"""
PromptReel AI — Flutterwave Payment Router
==========================================
POST /api/payments/verify  — Verify a completed Flutterwave transaction and
                              upgrade the authenticated user's plan in the DB.
POST /api/payments/webhook — Optional Flutterwave webhook for server-side events.
GET  /api/payments/prices  — Return current USD plan prices (for display in app).
"""
import hashlib
import hmac
import json
import logging

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

# ─── Schemas ─────────────────────────────────────────────────────────────────

class VerifyPaymentRequest(BaseModel):
    transaction_id: str   # Flutterwave transaction ID returned after payment
    tx_ref: str           # Your unique tx_ref passed into the SDK
    plan: str             # "creator" or "studio"


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _expected_amount(plan: str) -> float:
    return {
        "creator": settings.CREATOR_PRICE_USD,
        "studio":  settings.STUDIO_PRICE_USD,
    }.get(plan, 0.0)


async def _verify_with_flutterwave(transaction_id: str) -> dict:
    """Call Flutterwave's verify endpoint and return the transaction data dict."""
    if not settings.FLUTTERWAVE_SECRET_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Payment service not configured. Contact support.",
        )

    url = FLW_VERIFY_URL.format(transaction_id)
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            url,
            headers={"Authorization": f"Bearer {settings.FLUTTERWAVE_SECRET_KEY}"},
        )

    if resp.status_code != 200:
        logger.error(f"FLW verify HTTP {resp.status_code}: {resp.text}")
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            "Could not verify payment with Flutterwave. Try again.",
        )

    body = resp.json()
    if body.get("status") != "success":
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Flutterwave error: {body.get('message', 'Unknown')}",
        )

    return body.get("data", {})


# ─── Routes ──────────────────────────────────────────────────────────────────

@router.post("/verify")
async def verify_payment(
    req: VerifyPaymentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Called by the Flutter app immediately after Flutterwave returns a
    successful ChargeResponse.  Verifies the transaction server-side,
    checks the amount, and upgrades the user's plan.
    """
    if req.plan not in ("creator", "studio"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid plan. Must be 'creator' or 'studio'.")

    tx = await _verify_with_flutterwave(req.transaction_id)

    # ── Validate status ───────────────────────────────────────────────────────
    if tx.get("status") != "successful":
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Transaction status is '{tx.get('status')}', not 'successful'.",
        )

    # ── Validate currency ─────────────────────────────────────────────────────
    if tx.get("currency") != "USD":
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Unexpected currency '{tx.get('currency')}'. Expected USD.",
        )

    # ── Validate amount (allow $0.10 tolerance for rounding) ─────────────────
    expected = _expected_amount(req.plan)
    actual   = float(tx.get("amount", 0))
    if actual < expected - 0.10:
        logger.warning(
            f"Amount mismatch for user {current_user.id}: "
            f"expected ≥${expected}, got ${actual} (plan={req.plan})"
        )
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Payment amount ${actual} does not match {req.plan} plan price ${expected}.",
        )

    # ── Validate tx_ref matches ───────────────────────────────────────────────
    if tx.get("tx_ref") != req.tx_ref:
        logger.warning(
            f"tx_ref mismatch for user {current_user.id}: "
            f"expected {req.tx_ref!r}, got {tx.get('tx_ref')!r}"
        )
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Transaction reference mismatch.")

    # ── Upgrade plan ─────────────────────────────────────────────────────────
    current_user.plan = PlanType(req.plan)
    await db.flush()

    logger.info(
        f"✅ User {current_user.id} ({current_user.email}) upgraded to "
        f"{req.plan} | tx_id={req.transaction_id} | amount=${actual}"
    )

    return {
        "success": True,
        "plan": req.plan,
        "message": f"🎉 Successfully upgraded to {req.plan.capitalize()} plan!",
        "amount_paid_usd": actual,
    }


@router.get("/prices")
async def get_prices():
    """Return current USD plan prices. Called by the app to display up-to-date amounts."""
    return {
        "currency": "USD",
        "creator": settings.CREATOR_PRICE_USD,
        "studio":  settings.STUDIO_PRICE_USD,
    }


@router.post("/webhook")
async def flutterwave_webhook(
    request: Request,
    verif_hash: str = Header(None, alias="verif-hash"),
):
    """
    Optional: Flutterwave server-side webhook.
    Configure the URL in your Flutterwave dashboard under Settings → Webhooks.
    Set the secret hash to match FLUTTERWAVE_SECRET_KEY.

    This endpoint logs the event. Extend it to handle subscription renewals,
    chargebacks, etc. as your business grows.
    """
    if not settings.FLUTTERWAVE_WEBHOOK_SECRET:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Webhook secret not configured.")

    # Validate webhook signature using HMAC SHA512
    if not verif_hash:
        logger.warning("Webhook received without verif-hash header — rejected.")
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Missing verif-hash header.")

    request_body = await request.body()
    computed_hash = hmac.new(
        settings.FLUTTERWAVE_WEBHOOK_SECRET.encode("utf-8"),
        msg=request_body,
        digestmod=hashlib.sha512,
    ).hexdigest()

    if not hmac.compare_digest(computed_hash, verif_hash):
        logger.warning("Webhook received with invalid verif-hash signature — rejected.")
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid webhook signature.")

    try:
        payload = await request.json()
    except Exception:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid JSON payload.")

    event     = payload.get("event", "unknown")
    tx_status = payload.get("data", {}).get("status", "unknown")
    tx_ref    = payload.get("data", {}).get("tx_ref", "")

    logger.info(f"📡 Flutterwave webhook: event={event}, status={tx_status}, tx_ref={tx_ref}")

    # TODO: Implement logic for handling webhook events (e.g., subscription updates, chargebacks)
    # For example, if event == 'charge.completed' and tx_status == 'successful':
    #   - Retrieve tx_ref from payload.get("data", {}).get("tx_ref")
    #   - Query your database for the user associated with this tx_ref
    #   - Update user's plan or subscription status
    #   - Handle cases like 'charge.failed', 'subscription.cancelled', etc.
    #   - Ensure idempotency to prevent duplicate processing of events.

    return {"status": "ok"}
