"""
PromptReel AI — Flutterwave Payment Router
==========================================
POST /api/payments/verify  — Verify a completed Flutterwave transaction and
                              upgrade the authenticated user's plan in the DB.
POST /api/payments/webhook — Flutterwave webhook for server-side events.
GET  /api/payments/prices  — Return current USD plan prices for display in app.
"""
import logging
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import get_db
from models.user import PlanType, User
from routers.auth import get_current_user

router = APIRouter(prefix="/payments", tags=["Payments"])
logger = logging.getLogger(__name__)

FLW_VERIFY_URL = "https://api.flutterwave.com/v3/transactions/{}/verify"

# USD equivalent prices — used for multi-currency validation
PLAN_PRICES_USD = {
    "creator": 15.00,
    "studio":  35.00,
}

# Approximate conversion tolerance (10% buffer handles rate fluctuations
# and Flutterwave fees for NGN, GHS, KES etc.)
AMOUNT_TOLERANCE_PCT = 0.10


# ─── Schemas ──────────────────────────────────────────────────────────────────
class VerifyPaymentRequest(BaseModel):
    transaction_id: str  # Flutterwave transaction ID returned after payment
    tx_ref:         str  # Your unique tx_ref passed into the SDK
    plan:           str  # "creator" or "studio"


# ─── Helpers ──────────────────────────────────────────────────────────────────
def _expected_usd(plan: str) -> float:
    """Return expected USD price for the given plan."""
    return PLAN_PRICES_USD.get(plan, 0.0)


async def _verify_with_flutterwave(transaction_id: str) -> dict:
    """
    Call Flutterwave's verify endpoint and return the transaction data dict.
    Handles both numeric transaction IDs and '0' (txRef-only verification).
    """
    if not settings.FLUTTERWAVE_SECRET_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Payment service not configured. Contact support.",
        )

    url = FLW_VERIFY_URL.format(transaction_id)
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            url,
            headers={
                "Authorization": f"Bearer {settings.FLUTTERWAVE_SECRET_KEY}",
                "Content-Type": "application/json",
            },
        )

    logger.info(f"FLW verify response: status={resp.status_code}")

    if resp.status_code == 404:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Transaction not found. Please contact support.",
        )

    if resp.status_code != 200:
        logger.error(f"FLW verify HTTP {resp.status_code}: {resp.text}")
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            "Could not verify payment with Flutterwave. Please try again.",
        )

    body = resp.json()
    if body.get("status") != "success":
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Flutterwave error: {body.get('message', 'Unknown error')}",
        )

    return body.get("data", {})


# ─── Verify Payment ───────────────────────────────────────────────────────────
@router.post("/verify")
async def verify_payment(
    req: VerifyPaymentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if req.plan not in ("creator", "studio"):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Invalid plan. Must be 'creator' or 'studio'.",
        )

    # ── Fetch transaction from Flutterwave ────────────────────────────────────
    tx = await _verify_with_flutterwave(req.transaction_id)

    logger.info(
        f"FLW transaction data: status={tx.get('status')} | "
        f"currency={tx.get('currency')} | amount={tx.get('amount')} | "
        f"tx_ref={tx.get('tx_ref')} | charged_amount={tx.get('charged_amount')}"
    )

    # ── Validate transaction status ───────────────────────────────────────────
    tx_status = (tx.get("status") or "").lower()
    if tx_status not in ("successful", "completed"):
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Transaction status is '{tx_status}', expected 'successful'.",
        )

    # ── Validate tx_ref matches ───────────────────────────────────────────────
    if tx.get("tx_ref") != req.tx_ref:
        logger.warning(
            f"tx_ref mismatch for user {current_user.id}: "
            f"expected {req.tx_ref!r}, got {tx.get('tx_ref')!r}"
        )
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Transaction reference mismatch. Contact support.",
        )

    # ── Validate amount (multi-currency aware) ────────────────────────────────
    # Flutterwave charges in local currency (NGN, GHS, etc.)
    # but also returns amount_settled in USD — use that for validation
    currency       = tx.get("currency", "USD")
    amount_charged = float(tx.get("amount", 0))
    amount_settled = float(tx.get("amount_settled") or 0)
    expected_usd   = _expected_usd(req.plan)

    if currency == "USD":
        # Direct USD payment — check amount exactly
        if amount_charged < expected_usd - 0.10:
            logger.warning(
                f"USD amount mismatch: expected >=${expected_usd}, "
                f"got ${amount_charged} (user={current_user.id})"
            )
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"Payment amount ${amount_charged:.2f} is less than "
                f"{req.plan} plan price ${expected_usd:.2f}.",
            )
    else:
        # Non-USD (NGN, GHS, KES etc.) — validate using amount_settled if available
        # Otherwise skip amount validation (Flutterwave confirmed it succeeded)
        if amount_settled > 0:
            min_expected = expected_usd * (1 - AMOUNT_TOLERANCE_PCT)
            if amount_settled < min_expected:
                logger.warning(
                    f"Settled amount mismatch: expected ~${expected_usd}, "
                    f"settled ${amount_settled} {currency} "
                    f"(user={current_user.id})"
                )
                raise HTTPException(
                    status.HTTP_400_BAD_REQUEST,
                    f"Settled amount ${amount_settled:.2f} does not match "
                    f"{req.plan} plan price ${expected_usd:.2f}.",
                )
        else:
            # No settled amount — trust Flutterwave's successful status
            logger.info(
                f"Non-USD payment ({currency}) — "
                f"trusting Flutterwave successful status"
            )

    # ── Duplicate transaction protection ──────────────────────────────────────
    if current_user.subscription_id == str(req.transaction_id):
        logger.warning(
            f"Duplicate transaction by user {current_user.id}: "
            f"tx_id={req.transaction_id}"
        )
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "This transaction has already been used to upgrade your plan.",
        )

    # ── Upgrade plan ──────────────────────────────────────────────────────────
    current_user.plan                    = PlanType(req.plan)
    current_user.subscription_id         = str(req.transaction_id)
    current_user.subscription_expires_at = (
        datetime.now(timezone.utc) + timedelta(days=30)
    )

    await db.flush()
    await db.refresh(current_user)

    logger.info(
        f"✅ User {current_user.id} ({current_user.email}) upgraded to "
        f"{req.plan} | tx_id={req.transaction_id} | "
        f"{amount_charged} {currency} | "
        f"expires={current_user.subscription_expires_at.isoformat()}"
    )

    return {
        "success":        True,
        "plan":           req.plan,
        "message":        f"🎉 Successfully upgraded to {req.plan.capitalize()} plan!",
        "amount_paid":    amount_charged,
        "currency":       currency,
        "expires_at":     current_user.subscription_expires_at.isoformat(),
    }


# ─── Get Prices ───────────────────────────────────────────────────────────────
@router.get("/prices")
async def get_prices():
    """Return current USD plan prices."""
    return {
        "currency": "USD",
        "creator":  settings.CREATOR_PRICE_USD,
        "studio":   settings.STUDIO_PRICE_USD,
    }


# ─── Webhook ──────────────────────────────────────────────────────────────────
@router.post("/webhook")
async def flutterwave_webhook(
    request: Request,
    verif_hash: str = Header(None, alias="verif-hash"),
    db: AsyncSession = Depends(get_db),
):
    """
    Flutterwave server-side webhook.
    Configure the URL in your Flutterwave dashboard:
    Settings → Webhooks → https://promptreel-ai.onrender.com/api/payments/webhook
    Set secret hash in FLUTTERWAVE_WEBHOOK_HASH env variable.
    """
    # ── Validate webhook signature ────────────────────────────────────────────
    expected_hash = settings.FLUTTERWAVE_WEBHOOK_HASH
    if not expected_hash:
        logger.warning("FLUTTERWAVE_WEBHOOK_HASH not set — skipping validation")
    elif not verif_hash or verif_hash != expected_hash:
        logger.warning(
            f"Webhook rejected: invalid hash "
            f"(got={verif_hash!r}, expected={expected_hash!r})"
        )
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Invalid webhook signature.",
        )

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, "Invalid JSON payload."
        )

    event     = payload.get("event", "unknown")
    data      = payload.get("data", {})
    tx_status = data.get("status", "unknown")
    tx_ref    = data.get("tx_ref", "")
    tx_id     = str(data.get("id", ""))
    currency  = data.get("currency", "")
    amount    = data.get("amount", 0)

    logger.info(
        f"📡 Webhook: event={event} | status={tx_status} | "
        f"tx_ref={tx_ref} | tx_id={tx_id} | "
        f"amount={amount} {currency}"
    )

    # ── Handle successful charge ───────────────────────────────────────────────
    if event == "charge.completed" and tx_status == "successful":
        logger.info(
            f"✅ Webhook confirmed payment: tx_ref={tx_ref} | "
            f"tx_id={tx_id} | {amount} {currency}"
        )
        # Plan upgrade is handled by /verify endpoint
        # This webhook is a backup confirmation log

    return {"status": "ok"}
