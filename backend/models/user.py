from sqlalchemy import Column, Integer, String, DateTime, Boolean, Enum as SAEnum, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
from datetime import datetime, timezone
import enum


class PlanType(str, enum.Enum):
    FREE    = "free"
    CREATOR = "creator"
    STUDIO  = "studio"


class SubscriptionStatus(str, enum.Enum):
    active    = "active"
    inactive  = "inactive"
    cancelled = "cancelled"
    expired   = "expired"
    trial     = "trial"


class User(Base):
    __tablename__ = "users"

    id            = Column(Integer, primary_key=True, index=True)
    email         = Column(String(255), unique=True, nullable=False, index=True)
    name          = Column(String(255), nullable=False)
    password_hash = Column(String(255), nullable=False)
    plan          = Column(SAEnum(PlanType, native_enum=False),
                           default=PlanType.FREE, nullable=False)
    is_active     = Column(Boolean, default=True,  nullable=False)
    is_verified   = Column(Boolean, default=False, nullable=False)

    # ── Email verification ────────────────────────────────────────────────────
    verification_code         = Column(String(6),  nullable=True)
    verification_code_expires = Column(DateTime(timezone=True), nullable=True)

    # ── Password reset ────────────────────────────────────────────────────────
    reset_code         = Column(String(6),  nullable=True)
    reset_code_expires = Column(DateTime(timezone=True), nullable=True)

    # ── Push notifications (FCM) ──────────────────────────────────────────────
    fcm_token = Column(String(500), nullable=True)

    # ── Rate limiting ─────────────────────────────────────────────────────────
    plans_generated_today = Column(Integer, default=0, nullable=False)
    last_generation_date  = Column(Date, nullable=True)
    total_plans_generated = Column(Integer, default=0, nullable=False)

    # ── Subscription ──────────────────────────────────────────────────────────
    subscription_id         = Column(String(255), nullable=True)
    subscription_expires_at = Column(DateTime(timezone=True), nullable=True)

    # ── Subscription extended fields ──────────────────────────────────────────
    # ✅ FIX: Using String instead of SAEnum to avoid PostgreSQL native enum conflict
    subscription_status     = Column(String(20), default='inactive', nullable=True)
    subscription_started_at = Column(DateTime(timezone=True), nullable=True)
    flw_plan_id             = Column(String(255), nullable=True)
    flw_customer_id         = Column(String(255), nullable=True)
    payment_method          = Column(String(100), nullable=True)
    auto_renew              = Column(Boolean, default=False, nullable=False)

    # ── Notification preferences ──────────────────────────────────────────────
    notif_generation_complete = Column(Boolean, default=True,  nullable=False)
    notif_daily_reminder      = Column(Boolean, default=False, nullable=False)
    notif_product_updates     = Column(Boolean, default=True,  nullable=False)
    notif_promotions          = Column(Boolean, default=False, nullable=False)

    # ── Timestamps ────────────────────────────────────────────────────────────
    created_at    = Column(DateTime(timezone=True),
                           server_default=func.now(), nullable=False)
    updated_at    = Column(DateTime(timezone=True), onupdate=func.now())
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    # ── Relationships ─────────────────────────────────────────────────────────
    projects = relationship("Project", back_populates="user",
                            cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User {self.email} [{self.plan}]>"

    @property
    def is_paid(self) -> bool:
        if self.plan not in (PlanType.CREATOR, PlanType.STUDIO):
            return False
        if self.subscription_expires_at is None:
            return True
        return datetime.now(timezone.utc) < self.subscription_expires_at

    def downgrade_if_expired(self) -> bool:
        if (
            self.plan in (PlanType.CREATOR, PlanType.STUDIO)
            and self.subscription_expires_at is not None
            and datetime.now(timezone.utc) >= self.subscription_expires_at
        ):
            self.plan = PlanType.FREE
            return True
        return False

    @property
    def daily_limit(self) -> int:
        return -1 if self.is_paid else 3

    @property
    def max_duration_minutes(self) -> int:
        if self.is_paid:
            return 20
        return 5
