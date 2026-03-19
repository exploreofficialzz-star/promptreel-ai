from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel, EmailStr, field_validator
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
from typing import Optional
from slowapi import Limiter
from slowapi.util import get_remote_address

from database import get_db
from models.user import User, PlanType
from config import settings
from services.email_service import (
    send_verification_email,
    send_reset_email,
    generate_code,
    code_expires_at,
)
import logging

# ── Per-router rate limiter (stricter than global) ────────────────────────────
_limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/auth", tags=["Authentication"])
logger = logging.getLogger(__name__)

pwd_context  = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


# ─── Schemas ──────────────────────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

    @field_validator("name")
    @classmethod
    def validate_name(cls, v):
        if len(v.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v.strip()


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token:  str
    refresh_token: str
    token_type:    str = "bearer"
    user:          dict


class RefreshRequest(BaseModel):
    refresh_token: str


class UpdateProfileRequest(BaseModel):
    name:         Optional[str] = None
    password:     Optional[str] = None
    new_password: Optional[str] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, v):
        if v is not None and len(v.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v.strip() if v else v

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v):
        if v is not None and len(v) < 8:
            raise ValueError("New password must be at least 8 characters")
        return v


class NotificationPreferencesRequest(BaseModel):
    generation_complete: Optional[bool] = None
    daily_reminder:      Optional[bool] = None
    product_updates:     Optional[bool] = None
    promotions:          Optional[bool] = None


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code:  str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email:    EmailStr
    code:     str
    password: str

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class ResendCodeRequest(BaseModel):
    email: EmailStr


class FcmTokenRequest(BaseModel):
    fcm_token: str


# ─── Helpers ──────────────────────────────────────────────────────────────────
def _truncate_password(password: str) -> str:
    return password.encode("utf-8")[:72].decode("utf-8", errors="ignore")


def hash_password(password: str) -> str:
    return pwd_context.hash(_truncate_password(password))


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(_truncate_password(plain), hashed)


def create_token(data: dict,
                 expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY,
                      algorithm=settings.ALGORITHM)


def user_to_dict(user: User) -> dict:
    return {
        "id":                    user.id,
        "email":                 user.email,
        "name":                  user.name,
        "plan":                  user.plan.value if hasattr(user.plan, "value") else user.plan,
        "is_verified":           user.is_verified,
        "total_plans_generated": user.total_plans_generated,
        "plans_generated_today": user.plans_generated_today,
        "created_at":            user.created_at.isoformat() if user.created_at else None,
        "is_paid":               user.is_paid,
        "daily_limit":           user.daily_limit,
        "max_duration_minutes":  user.max_duration_minutes,
    }


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload  = jwt.decode(token, settings.SECRET_KEY,
                              algorithms=[settings.ALGORITHM])
        user_id  = payload.get("sub")
        if user_id is None:
            raise exc
    except JWTError:
        raise exc

    result = await db.execute(
        select(User).where(User.id == int(user_id))
    )
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise exc
    return user


# ─── Register ─────────────────────────────────────────────────────────────────
@router.post("/register", response_model=TokenResponse,
             status_code=status.HTTP_201_CREATED)
@_limiter.limit("10/minute")  # Brute-force protection
async def register(request: Request, data: RegisterRequest,
                   db: AsyncSession = Depends(get_db)):
    existing = await db.execute(
        select(User).where(User.email == data.email.lower())
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT,
                            "Email already registered")

    # Generate verification code
    code    = generate_code()
    expires = code_expires_at(minutes=15)

    user = User(
        email=data.email.lower(),
        name=data.name,
        password_hash=hash_password(data.password),
        plan=PlanType.FREE,
        is_verified=False,
        verification_code=code,
        verification_code_expires=expires,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    # Send verification email (non-blocking — don't fail registration)
    try:
        await send_verification_email(user.email, user.name, code)
    except Exception as e:
        logger.warning(f"Verification email failed: {e}")

    access_token  = create_token({"sub": str(user.id), "type": "access"})
    refresh_token = create_token(
        {"sub": str(user.id), "type": "refresh"},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return {
        "access_token":  access_token,
        "refresh_token": refresh_token,
        "user":          user_to_dict(user),
    }


# ─── Login ────────────────────────────────────────────────────────────────────
@router.post("/login", response_model=TokenResponse)
@_limiter.limit("10/minute")  # Brute-force protection
async def login(request: Request, data: LoginRequest,
                db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == data.email.lower())
    )
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED,
                            "Invalid email or password")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN,
                            "Account is deactivated")

    user.last_login_at = datetime.now(timezone.utc)
    await db.flush()

    access_token  = create_token({"sub": str(user.id), "type": "access"})
    refresh_token = create_token(
        {"sub": str(user.id), "type": "refresh"},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return {
        "access_token":  access_token,
        "refresh_token": refresh_token,
        "user":          user_to_dict(user),
    }


# ─── Refresh Token ────────────────────────────────────────────────────────────
@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(data: RefreshRequest,
                        db: AsyncSession = Depends(get_db)):
    try:
        payload = jwt.decode(data.refresh_token, settings.SECRET_KEY,
                             algorithms=[settings.ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status.HTTP_401_UNAUTHORIZED,
                                "Invalid token type")
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED,
                            "Invalid refresh token")

    result = await db.execute(
        select(User).where(User.id == int(user_id))
    )
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User not found")

    access_token  = create_token({"sub": str(user.id), "type": "access"})
    new_refresh   = create_token(
        {"sub": str(user.id), "type": "refresh"},
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )
    return {
        "access_token":  access_token,
        "refresh_token": new_refresh,
        "user":          user_to_dict(user),
    }


# ─── Get / Update Profile ─────────────────────────────────────────────────────
@router.get("/me", response_model=dict)
async def get_me(current_user: User = Depends(get_current_user)):
    return user_to_dict(current_user)


@router.put("/me", response_model=dict)
async def update_profile(
    data: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.name is not None:
        current_user.name = data.name

    if data.new_password is not None:
        if not data.password:
            raise HTTPException(status.HTTP_400_BAD_REQUEST,
                                "Current password required")
        if not verify_password(data.password, current_user.password_hash):
            raise HTTPException(status.HTTP_400_BAD_REQUEST,
                                "Current password is incorrect")
        current_user.password_hash = hash_password(data.new_password)

    current_user.updated_at = datetime.now(timezone.utc)
    await db.flush()
    await db.refresh(current_user)
    return user_to_dict(current_user)


# ─── Notification Preferences ─────────────────────────────────────────────────
@router.get("/notifications", response_model=dict)
async def get_notifications(
    current_user: User = Depends(get_current_user),
):
    return {
        "generation_complete": getattr(current_user, "notif_generation_complete", True),
        "daily_reminder":      getattr(current_user, "notif_daily_reminder", False),
        "product_updates":     getattr(current_user, "notif_product_updates", True),
        "promotions":          getattr(current_user, "notif_promotions", False),
    }


@router.put("/notifications", response_model=dict)
async def update_notifications(
    data: NotificationPreferencesRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.generation_complete is not None:
        current_user.notif_generation_complete = data.generation_complete
    if data.daily_reminder is not None:
        current_user.notif_daily_reminder = data.daily_reminder
    if data.product_updates is not None:
        current_user.notif_product_updates = data.product_updates
    if data.promotions is not None:
        current_user.notif_promotions = data.promotions

    await db.flush()
    return {
        "generation_complete": current_user.notif_generation_complete,
        "daily_reminder":      current_user.notif_daily_reminder,
        "product_updates":     current_user.notif_product_updates,
        "promotions":          current_user.notif_promotions,
    }


# ─── Verify Email ─────────────────────────────────────────────────────────────
@router.post("/verify-email")
async def verify_email(data: VerifyEmailRequest,
                       db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == data.email.lower())
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.is_verified:
        return {"message": "Email already verified"}
    if user.verification_code != data.code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid code")
    if (user.verification_code_expires and
            datetime.now(timezone.utc) > user.verification_code_expires):
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            "Code expired. Request a new one.")

    user.is_verified              = True
    user.verification_code        = None
    user.verification_code_expires = None
    await db.flush()
    return {"message": "Email verified successfully"}


# ─── Resend Verification Code ─────────────────────────────────────────────────
@router.post("/resend-verification")
async def resend_verification(data: ResendCodeRequest,
                              db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == data.email.lower())
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.is_verified:
        return {"message": "Email already verified"}

    code    = generate_code()
    expires = code_expires_at(minutes=15)

    user.verification_code         = code
    user.verification_code_expires = expires
    await db.flush()

    await send_verification_email(user.email, user.name, code)
    return {"message": "Verification code sent"}


# ─── Forgot Password ──────────────────────────────────────────────────────────
@router.post("/forgot-password")
@_limiter.limit("5/minute")  # Prevent email flooding
async def forgot_password(request: Request, data: ForgotPasswordRequest,
                          db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == data.email.lower())
    )
    user = result.scalar_one_or_none()

    # Always return success to prevent email enumeration
    if not user:
        return {"message": "If that email exists, a reset code was sent"}

    code    = generate_code()
    expires = code_expires_at(minutes=15)

    user.reset_code         = code
    user.reset_code_expires = expires
    await db.flush()

    await send_reset_email(user.email, user.name, code)
    return {"message": "If that email exists, a reset code was sent"}


# ─── Reset Password ───────────────────────────────────────────────────────────
@router.post("/reset-password")
@_limiter.limit("5/minute")
async def reset_password(request: Request, data: ResetPasswordRequest,
                         db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(User.email == data.email.lower())
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if user.reset_code != data.code:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid code")
    if (user.reset_code_expires and
            datetime.now(timezone.utc) > user.reset_code_expires):
        raise HTTPException(status.HTTP_400_BAD_REQUEST,
                            "Code expired. Request a new one.")

    user.password_hash    = hash_password(data.password)
    user.reset_code       = None
    user.reset_code_expires = None
    await db.flush()
    return {"message": "Password reset successfully"}


# ─── Save FCM Token (Push Notifications) ─────────────────────────────────────
@router.post("/fcm-token")
async def save_fcm_token(
    data: FcmTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.fcm_token = data.fcm_token
    await db.flush()
    return {"message": "FCM token saved"}





# ─── Get subscription status ─────────────────────────────────────────────────
@router.get("/subscription")
async def get_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Returns current plan, expiry date, and whether subscription is active."""
    # Auto-downgrade if expired
    if current_user.downgrade_if_expired():
        await db.flush()

    from datetime import datetime, timezone
    return {
        "plan":       current_user.plan.value,
        "is_paid":    current_user.is_paid,
        "expires_at": current_user.subscription_expires_at.isoformat()
                      if current_user.subscription_expires_at else None,
        "is_expired": (
            current_user.subscription_expires_at is not None
            and datetime.now(timezone.utc) >= current_user.subscription_expires_at
        ),
    }


# ─── Account Hard Delete (GDPR) ───────────────────────────────────────────────
class DeleteAccountRequest(BaseModel):
    password: str  # Require password confirmation before deleting


@router.delete("/me", status_code=204, tags=["Auth"])
async def delete_account(
    data: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Permanently delete the authenticated user's account and all associated data.
    Requires the user to confirm their current password.
    This action is irreversible.
    """
    # Verify password before deletion
    if not verify_password(data.password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Incorrect password. Account deletion cancelled.",
        )

    logger.warning(
        f"Account hard-delete requested for user {current_user.id} ({current_user.email})"
    )

    # SQLAlchemy cascade="all, delete-orphan" on User.projects handles
    # deleting all associated Project rows automatically.
    await db.delete(current_user)
    await db.flush()

    logger.info(f"Account {current_user.id} permanently deleted.")
    return  # 204 No Content
