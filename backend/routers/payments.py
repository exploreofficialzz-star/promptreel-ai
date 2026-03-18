"""
PromptReel AI — Flutterwave Payment Router
==========================================
POST /api/payments/verify        — Verify transaction & upgrade user plan
POST /api/payments/webhook       — Flutterwave server-side webhook
GET  /api/payments/prices        — Return current USD plan prices
GET  /api/payments/checkout-page — Serve Flutterwave checkout as real HTML page
"""
import logging
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import get_db
from models.user import PlanType, User
from routers.auth import get_current_user

router = APIRouter(prefix="/payments", tags=["Payments"])
logger = logging.getLogger(__name__)

FLW_BASE_URL   = "https://api.flutterwave.com/v3"
FLW_VERIFY_URL = f"{FLW_BASE_URL}/transactions/{{}}/verify"

PLAN_PRICES_USD = {
    "creator": 15.00,
    "studio":  35.00,
}

AMOUNT_TOLERANCE_PCT = 0.10


# ─── Schemas ──────────────────────────────────────────────────────────────────
class VerifyPaymentRequest(BaseModel):
    transaction_id: str
    tx_ref:         str
    plan:           str


# ─── Helpers ──────────────────────────────────────────────────────────────────
def _expected_usd(plan: str) -> float:
    return PLAN_PRICES_USD.get(plan, 0.0)


def _flw_headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.FLUTTERWAVE_SECRET_KEY}",
        "Content-Type":  "application/json",
    }


async def _lookup_tx_by_ref(tx_ref: str) -> str:
    """
    Look up a Flutterwave transaction ID using tx_ref.
    Used when the app sends transaction_id='0' (Chrome browser flow).
    """
    logger.info(f"Looking up transaction by tx_ref: {tx_ref}")
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            f"{FLW_BASE_URL}/transactions",
            params={"tx_ref": tx_ref},
            headers=_flw_headers(),
        )

    if resp.status_code != 200:
        logger.error(
            f"FLW tx_ref lookup failed: "
            f"status={resp.status_code} body={resp.text}"
        )
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            "Could not find your payment. "
            "Please wait a moment and try again.",
        )

    body = resp.json()
    data = body.get("data", [])

    if not data:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Payment not found. "
            "If you just paid, please wait 30 seconds and try again.",
        )

    tx_id = str(data[0].get("id", "0"))
    logger.info(f"Found transaction by tx_ref: tx_id={tx_id}")
    return tx_id


async def _verify_with_flutterwave(transaction_id: str) -> dict:
    """Call Flutterwave verify endpoint and return transaction data."""
    if not settings.FLUTTERWAVE_SECRET_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Payment service not configured. Contact support.",
        )

    url = FLW_VERIFY_URL.format(transaction_id)
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, headers=_flw_headers())

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


# ─── Checkout Page ────────────────────────────────────────────────────────────
@router.get("/checkout-page", response_class=HTMLResponse)
async def checkout_page(
    public_key: str,
    amount:     str,
    email:      str,
    name:       str,
    tx_ref:     str,
    plan_name:  str,
    currency:   str = "USD",
):
    """
    Serve Flutterwave checkout as a real HTTPS page.
    The app opens this in Chrome browser via url_launcher.
    Chrome has no popup restrictions — Flutterwave modal works perfectly.
    """
    safe_name     = name.replace("'", "\\'").replace('"', '\\"')
    safe_email    = email.replace("'", "").replace('"', '')
    safe_tx_ref   = tx_ref.replace("'", "").replace('"', '')
    safe_plan     = plan_name.replace("'", "").replace('"', '')
    safe_amount   = amount.replace("'", "").replace('"', '')
    safe_currency = currency.replace("'", "").replace('"', '')
    safe_key      = public_key.replace("'", "").replace('"', '')

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
  <title>PromptReel AI — Checkout</title>
  <script src="https://checkout.flutterwave.com/v3.js"></script>
  <style>
    *{{margin:0;padding:0;box-sizing:border-box;
       -webkit-tap-highlight-color:transparent;}}
    html,body{{width:100%;height:100%;overflow-x:hidden;}}
    body{{
      background:#0A0A0F;min-height:100vh;
      display:flex;flex-direction:column;
      align-items:center;justify-content:center;
      font-family:-apple-system,Arial,sans-serif;padding:20px;
    }}
    .card{{
      background:#12121A;border:1px solid #2A2A3A;
      border-radius:20px;padding:32px 24px;
      width:100%;max-width:420px;text-align:center;
    }}
    .emoji{{font-size:44px;margin-bottom:10px;}}
    .title{{color:#FFB830;font-size:22px;font-weight:800;margin-bottom:4px;}}
    .sub{{color:#555;font-size:13px;margin-bottom:24px;}}
    .pbox{{
      background:#1A1A2E;border:1px solid #2A2A3A;
      border-radius:12px;padding:18px;margin-bottom:24px;
    }}
    .price{{color:#fff;font-size:40px;font-weight:900;line-height:1;}}
    .price span{{font-size:16px;font-weight:400;color:#666;}}
    .badge{{
      display:inline-block;
      background:rgba(255,184,48,.15);color:#FFB830;
      border:1px solid rgba(255,184,48,.3);border-radius:50px;
      padding:3px 14px;font-size:11px;font-weight:700;
      text-transform:uppercase;letter-spacing:1px;margin-top:8px;
    }}
    .btn{{
      width:100%;padding:17px;
      background:linear-gradient(135deg,#FFB830,#FF8C00);
      color:#000;font-size:16px;font-weight:800;
      border:none;border-radius:50px;cursor:pointer;
      margin-bottom:12px;-webkit-appearance:none;
    }}
    .btn:disabled{{opacity:.55;cursor:not-allowed;}}
    .lock{{color:#444;font-size:12px;margin-bottom:6px;}}
    .status{{color:#888;font-size:13px;min-height:20px;margin-top:4px;}}
    .spin{{
      display:inline-block;width:16px;height:16px;
      border:2px solid rgba(0,0,0,.25);border-top-color:#000;
      border-radius:50%;animation:sp .7s linear infinite;
      vertical-align:middle;margin-right:6px;
    }}
    @keyframes sp{{to{{transform:rotate(360deg);}}}}
  </style>
</head>
<body>
<div class="card">
  <div class="emoji">🎬</div>
  <div class="title">PromptReel AI</div>
  <div class="sub">AI Video Production Platform</div>
  <div class="pbox">
    <div class="price">${safe_amount}<span>/mo</span></div>
    <div class="badge">{safe_plan} Plan</div>
  </div>
  <button class="btn" id="btn" onclick="pay()">
    Pay Securely — ${safe_amount}
  </button>
  <div class="lock">🔒 Secured by Flutterwave</div>
  <div class="status" id="st"></div>
</div>

<script>
  function st(t) {{ document.getElementById('st').textContent = t; }}

  function pay() {{
    var btn = document.getElementById('btn');
    btn.disabled  = true;
    btn.innerHTML = '<span class="spin"></span>Opening payment...';
    st('Connecting to Flutterwave...');

    try {{
      FlutterwaveCheckout({{
        public_key:      '{safe_key}',
        tx_ref:          '{safe_tx_ref}',
        amount:           {safe_amount},
        currency:        '{safe_currency}',
        payment_options: 'card,banktransfer,ussd,mobilemoney',
        redirect_url:    'https://promptreel.ai/payment/callback',
        meta: {{
          source:      'promptreel_mobile_app',
          plan:        '{safe_plan}',
          consumer_id: '{safe_tx_ref}'
        }},
        customer: {{
          email:        '{safe_email}',
          phone_number: '0000000000',
          name:         '{safe_name}'
        }},
        customizations: {{
          title:       'PromptReel AI',
          description: '{safe_plan} Plan — Monthly Subscription',
          logo:        'https://promptreel.ai/logo.png'
        }},
        callback: function(data) {{
          var s   = data.status         || 'unknown';
          var tid = data.transaction_id || '0';
          st('Payment ' + s + '! You can return to the app.');
          btn.disabled    = false;
          btn.textContent = '✅ Payment ' + s + ' — Return to app';
        }},
        onclose: function() {{
          btn.disabled    = false;
          btn.textContent = 'Pay Securely — ${safe_amount}';
          st('Window closed. Tap button to try again.');
        }}
      }});
      st('Payment window opening...');
    }} catch (e) {{
      btn.disabled    = false;
      btn.textContent = 'Retry Payment';
      st('Error: ' + e.message);
    }}
  }}

  window.addEventListener('load', function() {{
    setTimeout(pay, 600);
  }});
</script>
</body>
</html>"""

    return HTMLResponse(
        content=html,
        headers={
            "Cache-Control": "no-cache, no-store, must-revalidate",
        },
    )


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

    # ── If transaction_id is '0' look up by tx_ref (Chrome browser flow) ─────
    if req.transaction_id == '0':
        req.transaction_id = await _lookup_tx_by_ref(req.tx_ref)

    # ── Fetch & verify transaction ────────────────────────────────────────────
    tx = await _verify_with_flutterwave(req.transaction_id)

    logger.info(
        f"FLW tx: status={tx.get('status')} | "
        f"currency={tx.get('currency')} | amount={tx.get('amount')} | "
        f"tx_ref={tx.get('tx_ref')} | settled={tx.get('amount_settled')}"
    )

    # ── Validate status ───────────────────────────────────────────────────────
    tx_status = (tx.get("status") or "").lower()
    if tx_status not in ("successful", "completed"):
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Transaction status is '{tx_status}', expected 'successful'.",
        )

    # ── Validate tx_ref ───────────────────────────────────────────────────────
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
    currency       = tx.get("currency", "USD")
    amount_charged = float(tx.get("amount", 0))
    amount_settled = float(tx.get("amount_settled") or 0)
    expected_usd   = _expected_usd(req.plan)

    if currency == "USD":
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
        if amount_settled > 0:
            min_expected = expected_usd * (1 - AMOUNT_TOLERANCE_PCT)
            if amount_settled < min_expected:
                logger.warning(
                    f"Settled mismatch: expected ~${expected_usd}, "
                    f"settled ${amount_settled} {currency} "
                    f"(user={current_user.id})"
                )
                raise HTTPException(
                    status.HTTP_400_BAD_REQUEST,
                    f"Settled amount ${amount_settled:.2f} does not match "
                    f"{req.plan} plan price ${expected_usd:.2f}.",
                )
        else:
            logger.info(
                f"Non-USD payment ({currency}) — "
                f"trusting Flutterwave successful status"
            )

    # ── Duplicate protection ──────────────────────────────────────────────────
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
        "success":    True,
        "plan":       req.plan,
        "message":    f"🎉 Successfully upgraded to {req.plan.capitalize()} plan!",
        "amount_paid":amount_charged,
        "currency":   currency,
        "expires_at": current_user.subscription_expires_at.isoformat(),
    }


# ─── Get Prices ───────────────────────────────────────────────────────────────
@router.get("/prices")
async def get_prices():
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
    Flutterwave webhook — configure URL in dashboard:
    Settings → Webhooks →
    https://promptreel-ai.onrender.com/api/payments/webhook
    """
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

    if event == "charge.completed" and tx_status == "successful":
        logger.info(
            f"✅ Webhook payment confirmed: "
            f"tx_ref={tx_ref} | tx_id={tx_id} | {amount} {currency}"
        )

    return {"status": "ok"}
