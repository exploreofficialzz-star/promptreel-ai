"""
PromptReel AI — Flutterwave Payment Router (No APP_URL Required)
=================================================================
- Shows fixed $15 Creator and $35 Studio USD plans
- Accepts ALL Flutterwave payment methods
- Works without APP_URL configuration
"""
import hashlib
import hmac
import json
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from database import get_db
from models.user import PlanType, User
from routers.auth import get_current_user

router = APIRouter(prefix="/payments", tags=["Payments"])
logger = logging.getLogger(__name__)

FLW_BASE_URL = "https://api.flutterwave.com/v3"

# ─── Your Fixed App Plans ─────────────────────────────────────────────────────
APP_PLANS = {
    "creator": {
        "id": "creator",
        "name": "Creator",
        "description": "Perfect for individual content creators",
        "amount": 15.00,
        "currency": "USD",
        "interval": "monthly",
        "features": [
            "100 video exports/month",
            "1080p quality",
            "Basic AI voice cloning",
            "Email support"
        ],
    },
    "studio": {
        "id": "studio",
        "name": "Studio",
        "description": "For professional production teams",
        "amount": 35.00,
        "currency": "USD",
        "interval": "monthly",
        "features": [
            "Unlimited video exports",
            "4K quality",
            "Advanced AI voice cloning",
            "Priority support",
            "Team collaboration",
            "API access"
        ],
    }
}

_flw_plan_cache: Dict[str, int] = {}


# ─── Pydantic Models ───────────────────────────────────────────────────────────
class VerifyPaymentRequest(BaseModel):
    transaction_id: str
    tx_ref: str
    plan_id: str


class CheckoutRequest(BaseModel):
    plan_id: str
    email: str
    name: str


# ─── Helper Functions ─────────────────────────────────────────────────────────
def _flw_headers() -> dict:
    if not settings.FLUTTERWAVE_SECRET_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Payment service not configured",
        )
    return {
        "Authorization": f"Bearer {settings.FLUTTERWAVE_SECRET_KEY}",
        "Content-Type": "application/json",
    }


async def _get_or_create_flw_plan(plan_key: str) -> int:
    """Get or create Flutterwave payment plan."""
    if plan_key in _flw_plan_cache:
        return _flw_plan_cache[plan_key]
    
    plan = APP_PLANS[plan_key]
    
    # Check existing plans
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            f"{FLW_BASE_URL}/payment-plans",
            headers=_flw_headers(),
        )
        
        if resp.status_code == 200:
            existing = resp.json().get("data", [])
            for p in existing:
                if (p.get("name") == f"PromptReel {plan['name']}" and 
                    float(p.get("amount", 0)) == plan["amount"]):
                    _flw_plan_cache[plan_key] = p["id"]
                    return p["id"]
    
    # Create new plan
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            f"{FLW_BASE_URL}/payment-plans",
            headers=_flw_headers(),
            json={
                "name": f"PromptReel {plan['name']}",
                "amount": plan["amount"],
                "currency": plan["currency"],
                "interval": plan["interval"],
            },
        )
        
        if resp.status_code in (200, 201):
            plan_id = resp.json().get("data", {}).get("id")
            _flw_plan_cache[plan_key] = plan_id
            return plan_id
        else:
            raise HTTPException(
                status.HTTP_503_SERVICE_UNAVAILABLE,
                "Could not create payment plan",
            )


async def _get_flw_payment_methods(currency: str = "USD") -> List[str]:
    """Get available payment methods for currency."""
    # Comprehensive list based on Flutterwave documentation
    methods_by_currency = {
        "USD": ["card", "account", "googlepay", "applepay"],
        "NGN": ["card", "ussd", "banktransfer", "account", "internetbanking", "nqr", "enaira", "opay", "googlepay", "applepay"],
        "GHS": ["card", "ghanamobilemoney", "account"],
        "KES": ["card", "mpesa", "account"],
        "ZAR": ["card", "account", "1voucher"],
        "UGX": ["card", "mobilemoneyuganda"],
        "TZS": ["card", "mobilemoneytanzania"],
        "RWF": ["card", "mobilemoneyrwanda"],
        "XAF": ["card", "mobilemoneyxof"],
        "XOF": ["card", "mobilemoneyxaf"],
        "MWK": ["card", "mobilemoneymalawi"],
        "EGP": ["card", "fawrypay"],
        "GBP": ["card", "account", "googlepay", "applepay"],
        "EUR": ["card", "account", "googlepay", "applepay"],
    }
    return methods_by_currency.get(currency.upper(), ["card", "account"])


async def _verify_with_flutterwave(transaction_id: str) -> dict:
    """Verify transaction with Flutterwave."""
    url = f"{FLW_BASE_URL}/transactions/{transaction_id}/verify"
    
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, headers=_flw_headers())
    
    if resp.status_code != 200:
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            "Could not verify payment",
        )
    
    body = resp.json()
    if body.get("status") != "success":
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Flutterwave error: {body.get('message', 'Unknown error')}",
        )
    
    return body.get("data", {})


# ─── API Endpoints ───────────────────────────────────────────────────────────
@router.get("/plans")
async def get_app_plans():
    """
    Return the $15 Creator and $35 Studio plans for app display.
    """
    return {
        "status": "success",
        "plans": list(APP_PLANS.values()),
        "currency": "USD",
    }


@router.get("/methods")
async def get_payment_methods(currency: str = Query("USD")):
    """
    Get available payment methods for a currency.
    """
    currency = currency.upper()
    methods = await _get_flw_payment_methods(currency)
    
    method_names = {
        "card": "Credit/Debit Card",
        "account": "Bank Account",
        "banktransfer": "Bank Transfer",
        "ussd": "USSD",
        "nqr": "NQR",
        "enaira": "eNaira",
        "opay": "OPay",
        "ghanamobilemoney": "Mobile Money (Ghana)",
        "mpesa": "M-Pesa",
        "mobilemoneyuganda": "Mobile Money (Uganda)",
        "mobilemoneytanzania": "Mobile Money (Tanzania)",
        "mobilemoneyrwanda": "Mobile Money (Rwanda)",
        "mobilemoneyxof": "Mobile Money (West Africa)",
        "mobilemoneyxaf": "Mobile Money (Central Africa)",
        "mobilemoneymalawi": "Mobile Money (Malawi)",
        "fawrypay": "Fawry Pay",
        "1voucher": "1Voucher",
        "googlepay": "Google Pay",
        "applepay": "Apple Pay",
        "internetbanking": "Internet Banking",
    }
    
    return {
        "status": "success",
        "currency": currency,
        "payment_methods": [
            {"id": m, "name": method_names.get(m, m)} for m in methods
        ],
    }


@router.post("/checkout")
async def create_checkout(
    req: CheckoutRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Create checkout session. Returns payment link.
    """
    if req.plan_id not in APP_PLANS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Invalid plan. Choose: {', '.join(APP_PLANS.keys())}",
        )
    
    plan = APP_PLANS[req.plan_id]
    flw_plan_id = await _get_or_create_flw_plan(req.plan_id)
    
    tx_ref = f"PR-{current_user.id}-{req.plan_id}-{int(datetime.now(timezone.utc).timestamp())}"
    
    # Get all payment methods
    methods = await _get_flw_payment_methods(plan["currency"])
    payment_options = ",".join(methods)
    
    payload = {
        "tx_ref": tx_ref,
        "amount": str(plan["amount"]),
        "currency": plan["currency"],
        "payment_options": payment_options,
        "payment_plan": flw_plan_id,
        "redirect_url": "/api/payments/callback",  # Relative URL - will use same host
        "customer": {
            "email": req.email,
            "name": req.name,
        },
        "meta": {
            "user_id": str(current_user.id),
            "plan_id": req.plan_id,
            "flw_plan_id": flw_plan_id,
        },
        "customizations": {
            "title": "PromptReel AI",
            "description": f"{plan['name']} Plan",
            "logo": "https://promptreel.ai/logo.png",
        },
    }
    
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            f"{FLW_BASE_URL}/payments",
            headers=_flw_headers(),
            json=payload,
        )
        
        if resp.status_code != 200:
            logger.error(f"Failed to create payment: {resp.text}")
            raise HTTPException(
                status.HTTP_503_SERVICE_UNAVAILABLE,
                "Could not initialize payment",
            )
        
        data = resp.json().get("data", {})
        
        return {
            "status": "success",
            "tx_ref": tx_ref,
            "payment_link": data.get("link"),
            "plan": {
                "id": req.plan_id,
                "name": plan["name"],
                "amount": plan["amount"],
                "currency": plan["currency"],
            },
            "payment_methods": methods,
        }


@router.get("/checkout-page", response_class=HTMLResponse)
async def checkout_page(
    plan_id: str,
    email: str,
    name: str,
    tx_ref: Optional[str] = None,
    request: Request = None,
):
    """
    Checkout page with all payment methods. No APP_URL needed.
    """
    if plan_id not in APP_PLANS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid plan")
    
    if not settings.FLUTTERWAVE_PUBLIC_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Payment service not configured",
        )
    
    plan = APP_PLANS[plan_id]
    flw_plan_id = await _get_or_create_flw_plan(plan_id)
    
    if not tx_ref:
        tx_ref = f"PR-{int(datetime.now(timezone.utc).timestamp())}-{plan_id}"
    
    methods = await _get_flw_payment_methods(plan["currency"])
    payment_options = ",".join(methods)
    
    # Build callback URL from request
    base_url = str(request.base_url).rstrip("/")
    callback_url = f"{base_url}/api/payments/callback"
    
    # Sanitize
    safe_name = name.replace("'", "\\'").replace('"', '\\"')[:50]
    safe_email = email.replace("'", "").replace('"', "")[:100]
    safe_tx_ref = tx_ref.replace("'", "").replace('"', "")[:100]
    safe_plan = plan["name"].replace("'", "").replace('"', "")
    safe_key = settings.FLUTTERWAVE_PUBLIC_KEY.replace("'", "").replace('"', "")
    
    method_names = {
        "card": "💳 Card",
        "account": "🏦 Bank Account",
        "banktransfer": "🏦 Bank Transfer",
        "ussd": "📱 USSD",
        "nqr": "📲 NQR",
        "enaira": "💰 eNaira",
        "opay": "💳 OPay",
        "ghanamobilemoney": "📱 Mobile Money (Ghana)",
        "mpesa": "📱 M-Pesa",
        "mobilemoneyuganda": "📱 Mobile Money (Uganda)",
        "mobilemoneytanzania": "📱 Mobile Money (Tanzania)",
        "mobilemoneyrwanda": "📱 Mobile Money (Rwanda)",
        "mobilemoneyxof": "📱 Mobile Money (West Africa)",
        "mobilemoneyxaf": "📱 Mobile Money (Central Africa)",
        "mobilemoneymalawi": "📱 Mobile Money (Malawi)",
        "fawrypay": "🏪 Fawry Pay",
        "1voucher": "🎫 1Voucher",
        "googlepay": "🔵 Google Pay",
        "applepay": "🍎 Apple Pay",
        "internetbanking": "🌐 Internet Banking",
    }
    
    methods_display = " • ".join([method_names.get(m, m) for m in methods[:6]])
    
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
  <title>PromptReel AI — {safe_plan} Plan</title>
  <script src="https://checkout.flutterwave.com/v3.js"></script>
  <style>
    *{{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent;}}
    body{{background:#0A0A0F;min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:-apple-system,BlinkMacSystemFont,Arial,sans-serif;padding:20px;color:#fff;}}
    .card{{background:#12121A;border:1px solid #2A2A3A;border-radius:24px;padding:40px 24px;width:100%;max-width:440px;text-align:center;box-shadow:0 25px 50px -12px rgba(0,0,0,0.5);}}
    .logo{{font-size:48px;margin-bottom:8px;}}
    .brand{{color:#FFB830;font-size:24px;font-weight:800;margin-bottom:4px;}}
    .tagline{{color:#666;font-size:13px;margin-bottom:28px;}}
    .plan-box{{background:linear-gradient(135deg,#1A1A2E,#0F0F1A);border:1px solid #2A2A3A;border-radius:16px;padding:24px;margin-bottom:24px;}}
    .plan-name{{color:#FFB830;font-size:14px;font-weight:700;text-transform:uppercase;letter-spacing:1px;margin-bottom:8px;}}
    .price{{color:#fff;font-size:48px;font-weight:900;line-height:1;}}
    .price span{{font-size:20px;font-weight:500;color:#888;vertical-align:top;}}
    .period{{color:#666;font-size:14px;margin-top:4px;}}
    .features{{text-align:left;margin:20px 0;padding:0 12px;}}
    .feature{{color:#aaa;font-size:13px;padding:6px 0;display:flex;align-items:center;gap:8px;}}
    .feature::before{{content:"✓";color:#FFB830;font-weight:700;}}
    .pay-btn{{width:100%;padding:18px;background:linear-gradient(135deg,#FFB830,#FF8C00);color:#000;font-size:16px;font-weight:800;border:none;border-radius:12px;cursor:pointer;margin-bottom:16px;transition:transform 0.2s,box-shadow 0.2s;}}
    .pay-btn:hover{{transform:translateY(-2px);box-shadow:0 10px 30px -10px rgba(255,184,48,0.5);}}
    .pay-btn:disabled{{opacity:0.6;cursor:not-allowed;transform:none;}}
    .methods{{color:#666;font-size:12px;line-height:1.6;padding:16px;background:#0A0A0F;border-radius:8px;margin-bottom:16px;}}
    .methods strong{{color:#888;display:block;margin-bottom:8px;}}
    .secure{{color:#444;font-size:12px;display:flex;align-items:center;justify-content:center;gap:6px;}}
    .status{{color:#888;font-size:13px;margin-top:12px;min-height:20px;}}
    .loading{{display:none;width:20px;height:20px;border:3px solid rgba(0,0,0,0.3);border-top-color:#000;border-radius:50%;animation:spin 1s linear infinite;}}
    @keyframes spin{{to{{transform:rotate(360deg);}}}}
  </style>
</head>
<body>
<div class="card">
  <div class="logo">🎬</div>
  <div class="brand">PromptReel AI</div>
  <div class="tagline">AI Video Production Platform</div>
  
  <div class="plan-box">
    <div class="plan-name">{safe_plan} Plan</div>
    <div class="price"><span>$</span>{plan['amount']}</div>
    <div class="period">per month</div>
    <div class="features">
      {"".join([f'<div class="feature">{f}</div>' for f in plan['features'][:4]])}
    </div>
  </div>
  
  <div class="methods">
    <strong>💳 Accepted Payment Methods:</strong>
    {methods_display}
  </div>
  
  <button class="pay-btn" id="payBtn" onclick="makePayment()">
    <span class="loading" id="loading"></span>
    <span id="btnText">Pay ${plan['amount']} Now</span>
  </button>
  
  <div class="secure">🔒 Secured by Flutterwave • SSL Encrypted</div>
  <div class="status" id="status"></div>
</div>

<script>
  function makePayment() {{
    const btn = document.getElementById('payBtn');
    const loading = document.getElementById('loading');
    const btnText = document.getElementById('btnText');
    const status = document.getElementById('status');
    
    btn.disabled = true;
    loading.style.display = 'inline-block';
    btnText.textContent = 'Initializing...';
    status.textContent = 'Connecting to payment processor...';
    
    try {{
      FlutterwaveCheckout({{
        public_key: '{safe_key}',
        tx_ref: '{safe_tx_ref}',
        amount: {plan['amount']},
        currency: '{plan['currency']}',
        payment_options: '{payment_options}',
        payment_plan: '{flw_plan_id}',
        redirect_url: '{callback_url}',
        customer: {{
          email: '{safe_email}',
          name: '{safe_name}',
          phone_number: '0000000000'
        }},
        meta: {{
          plan_id: '{plan_id}',
          flw_plan_id: '{flw_plan_id}',
          source: 'checkout_page'
        }},
        customizations: {{
          title: 'PromptReel AI',
          description: '{safe_plan} Plan Subscription',
          logo: 'https://promptreel.ai/logo.png'
        }},
        callback: function(data) {{
          console.log('Payment callback:', data);
          status.textContent = 'Payment ' + data.status + '! Redirecting...';
          setTimeout(() => {{
            window.location.href = '{callback_url}?tx_ref={safe_tx_ref}&transaction_id=' + (data.transaction_id || '') + '&status=' + data.status;
          }}, 1500);
        }},
        onclose: function() {{
          btn.disabled = false;
          loading.style.display = 'none';
          btnText.textContent = 'Pay ${plan['amount']} Now';
          status.textContent = 'Payment cancelled. You can try again.';
        }}
      }});
    }} catch (e) {{
      console.error('Payment error:', e);
      btn.disabled = false;
      loading.style.display = 'none';
      btnText.textContent = 'Try Again';
      status.textContent = 'Error: ' + e.message;
    }}
  }}
  
  setTimeout(makePayment, 1000);
</script>
</body>
</html>"""
    
    return HTMLResponse(content=html)


@router.get("/callback")
async def payment_callback(
    tx_ref: str,
    transaction_id: Optional[str] = None,
    status: Optional[str] = None,
):
    """
    Handle return from Flutterwave.
    Returns JSON that your app can parse.
    """
    return {
        "status": status or "unknown",
        "tx_ref": tx_ref,
        "transaction_id": transaction_id,
        "message": "Payment completed. Return to app to verify.",
        "next_step": "Call POST /api/payments/verify with transaction_id",
    }


@router.post("/verify")
async def verify_payment(
    req: VerifyPaymentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Verify payment and upgrade user plan.
    """
    if req.plan_id not in APP_PLANS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid plan")
    
    tx_data = await _verify_with_flutterwave(req.transaction_id)
    
    if tx_data.get("status") != "successful":
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Payment failed: {tx_data.get('status')}",
        )
    
    expected_amount = APP_PLANS[req.plan_id]["amount"]
    charged_amount = float(tx_data.get("charged_amount", 0))
    
    if abs(charged_amount - expected_amount) > 0.50:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Amount mismatch. Expected ${expected_amount}, got ${charged_amount}",
        )
    
    expected_currency = APP_PLANS[req.plan_id]["currency"]
    if tx_data.get("currency") != expected_currency:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Currency mismatch. Expected {expected_currency}",
        )
    
    # Upgrade user
    current_user.plan = PlanType(req.plan_id)
    await db.commit()
    await db.refresh(current_user)
    
    payment_method = tx_data.get("payment_type", "unknown")
    
    logger.info(
        f"✅ User {current_user.id} upgraded to {req.plan_id} | "
        f"tx={req.transaction_id} | method={payment_method} | "
        f"amount=${charged_amount}"
    )
    
    return {
        "success": True,
        "plan": req.plan_id,
        "plan_name": APP_PLANS[req.plan_id]["name"],
        "message": f"🎉 Welcome to {APP_PLANS[req.plan_id]['name']} Plan!",
        "payment_details": {
            "transaction_id": req.transaction_id,
            "amount": charged_amount,
            "currency": expected_currency,
            "method": payment_method,
            "tx_ref": req.tx_ref,
        },
        "features": APP_PLANS[req.plan_id]["features"],
    }


@router.post("/webhook")
async def flutterwave_webhook(
    request: Request,
    verif_hash: Optional[str] = Header(None, alias="verif-hash"),
):
    """
    Handle Flutterwave webhooks.
    """
    if not settings.FLUTTERWAVE_WEBHOOK_HASH:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Webhook not configured")
    
    if not verif_hash:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Missing signature")
    
    body = await request.body()
    expected_hash = hmac.new(
        settings.FLUTTERWAVE_WEBHOOK_HASH.encode(),
        body,
        hashlib.sha512,
    ).hexdigest()
    
    if not hmac.compare_digest(expected_hash, verif_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid signature")
    
    payload = await request.json()
    event = payload.get("event")
    data = payload.get("data", {})
    
    logger.info(f"📡 Webhook: {event}")
    
    if event == "charge.completed":
        await _handle_successful_charge(data)
    elif event in ("subscription.cancelled", "payment_plan.subscription_cancelled"):
        await _handle_subscription_cancelled(data)
    
    return {"status": "ok"}


async def _handle_successful_charge(data: dict):
    """Process successful payment."""
    tx_ref = data.get("tx_ref")
    meta = data.get("meta", {})
    plan_id = meta.get("plan_id")
    user_id = meta.get("user_id")
    
    logger.info(f"Payment success: tx_ref={tx_ref}, plan={plan_id}, user={user_id}")
    # TODO: Update database if needed


async def _handle_subscription_cancelled(data: dict):
    """Handle cancellation."""
    logger.info(f"Subscription cancelled: {data.get('plan_id')}")


@router.on_event("startup")
async def initialize_payment_plans():
    """Pre-create plans on startup."""
    try:
        for plan_key in APP_PLANS:
            await _get_or_create_flw_plan(plan_key)
        logger.info("✅ Payment plans initialized")
    except Exception as e:
        logger.error(f"Failed to initialize plans: {e}")
