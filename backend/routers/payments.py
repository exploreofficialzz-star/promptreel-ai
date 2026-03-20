"""
PromptReel AI — Flutterwave Payment Router (Production Ready)
=============================================================
- Shows fixed $15 Creator and $35 Studio USD plans
- Accepts ALL Flutterwave payment methods
- Handles auto-renewal subscriptions (monthly)
- Cross-platform: Web, Android, iOS
- Handles transaction lookup by tx_ref when needed
"""
import hashlib
import hmac
import json
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from config import settings
from database import get_db
from models.user import PlanType, User, SubscriptionStatus
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

# ─── Platform Detection ───────────────────────────────────────────────────────
def detect_platform(user_agent: str = "", referer: str = "") -> str:
    """Detect platform from headers."""
    ua = user_agent.lower()
    if "android" in ua:
        return "android"
    elif "iphone" in ua or "ipad" in ua or "ios" in ua:
        return "ios"
    return "web"

# ─── Pydantic Models ───────────────────────────────────────────────────────────
class VerifyPaymentRequest(BaseModel):
    transaction_id: Optional[str] = None  # Can be "0" - will lookup by tx_ref
    tx_ref: str
    plan_id: str


class CheckoutRequest(BaseModel):
    plan_id: str
    email: str
    name: str
    platform: Optional[str] = "web"  # web, android, ios
    redirect_url: Optional[str] = None  # Custom redirect for mobile apps


class SubscriptionResponse(BaseModel):
    status: str
    plan: str
    expires_at: Optional[datetime] = None
    auto_renew: bool = True
    payment_method: Optional[str] = None


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
    """Get or create Flutterwave payment plan for auto-renewal."""
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
    
    # Create new plan with auto-renewal enabled
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            f"{FLW_BASE_URL}/payment-plans",
            headers=_flw_headers(),
            json={
                "name": f"PromptReel {plan['name']}",
                "amount": plan["amount"],
                "currency": plan["currency"],
                "interval": plan["interval"],
                "duration": None,  # Indefinite until cancelled
            },
        )
        
        if resp.status_code in (200, 201):
            plan_id = resp.json().get("data", {}).get("id")
            _flw_plan_cache[plan_key] = plan_id
            return plan_id
        else:
            logger.error(f"Failed to create plan: {resp.text}")
            raise HTTPException(
                status.HTTP_503_SERVICE_UNAVAILABLE,
                "Could not create payment plan",
            )


async def _lookup_tx_by_ref(tx_ref: str) -> Optional[Dict[str, Any]]:
    """
    Look up transaction by tx_ref. Returns full transaction data.
    Used when frontend sends transaction_id="0".
    """
    logger.info(f"Looking up transaction by tx_ref: {tx_ref}")
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(
            f"{FLW_BASE_URL}/transactions",
            params={"tx_ref": tx_ref},
            headers=_flw_headers(),
        )
        
        if resp.status_code != 200:
            logger.error(f"Lookup failed: {resp.status_code}")
            return None
        
        data = resp.json().get("data", [])
        if not data:
            logger.warning(f"No transaction found for tx_ref: {tx_ref}")
            return None
        
        return data[0]


async def _get_flw_payment_methods(currency: str = "USD") -> List[str]:
    """Get available payment methods for currency."""
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
        logger.error(f"Verification failed: {resp.status_code}")
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


def _get_platform_redirect_urls(platform: str, request: Request) -> Dict[str, str]:
    """Generate platform-specific redirect URLs."""
    base_url = str(request.base_url).rstrip("/")
    
    if platform == "android":
        # Deep link for Android app
        return {
            "success": "promptreel://payment/success",
            "cancel": "promptreel://payment/cancel",
            "callback": f"{base_url}/api/payments/callback"
        }
    elif platform == "ios":
        # Universal link for iOS app
        return {
            "success": "https://promptreel.ai/payment/success",  # Universal link
            "cancel": "https://promptreel.ai/payment/cancel",
            "callback": f"{base_url}/api/payments/callback"
        }
    else:  # web
        return {
            "success": f"{base_url}/api/payments/callback",
            "cancel": f"{base_url}/api/payments/callback",
            "callback": f"{base_url}/api/payments/callback"
        }


# ─── API Endpoints ───────────────────────────────────────────────────────────
@router.get("/plans")
async def get_app_plans():
    """Return the $15 Creator and $35 Studio plans."""
    return {
        "status": "success",
        "plans": list(APP_PLANS.values()),
        "currency": "USD",
    }


@router.get("/methods")
async def get_payment_methods(currency: str = Query("USD")):
    """Get available payment methods."""
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
    request: Request,
    current_user: User = Depends(get_current_user),
):
    """Create checkout session. Returns payment link or data for inline checkout."""
    if req.plan_id not in APP_PLANS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Invalid plan. Choose: {', '.join(APP_PLANS.keys())}",
        )
    
    plan = APP_PLANS[req.plan_id]
    flw_plan_id = await _get_or_create_flw_plan(req.plan_id)
    
    # Generate unique transaction reference
    tx_ref = f"PR-{current_user.id}-{req.plan_id}-{int(datetime.now(timezone.utc).timestamp())}"
    
    methods = await _get_flw_payment_methods(plan["currency"])
    payment_options = ",".join(methods)
    
    # Platform-specific redirects
    redirects = _get_platform_redirect_urls(req.platform or "web", request)
    
    payload = {
        "tx_ref": tx_ref,
        "amount": str(plan["amount"]),
        "currency": plan["currency"],
        "payment_options": payment_options,
        "payment_plan": flw_plan_id,  # This enables auto-renewal!
        "redirect_url": redirects["callback"],
        "customer": {
            "email": req.email,
            "name": req.name,
        },
        "meta": {
            "user_id": str(current_user.id),
            "plan_id": req.plan_id,
            "flw_plan_id": flw_plan_id,
            "platform": req.platform or "web",
        },
        "customizations": {
            "title": "PromptReel AI",
            "description": f"{plan['name']} Plan Subscription",
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
        
        response_data = {
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
            "is_subscription": True,
            "auto_renew": True,
            "platform": req.platform or "web",
        }
        
        # For mobile apps, also return inline checkout config
        if req.platform in ["android", "ios"]:
            response_data["inline_config"] = {
                "public_key": settings.FLUTTERWAVE_PUBLIC_KEY,
                "tx_ref": tx_ref,
                "amount": plan["amount"],
                "currency": plan["currency"],
                "payment_options": payment_options,
                "payment_plan": flw_plan_id,
                "customer": {
                    "email": req.email,
                    "name": req.name,
                },
                "meta": {
                    "user_id": str(current_user.id),
                    "plan_id": req.plan_id,
                },
                "customizations": {
                    "title": "PromptReel AI",
                    "description": f"{plan['name']} Plan",
                },
            }
        
        return response_data


@router.get("/checkout-page", response_class=HTMLResponse)
async def checkout_page(
    plan_id: str,
    email: str,
    name: str,
    tx_ref: Optional[str] = None,
    currency: str = "USD",
    platform: str = "web",
    request: Request = None,
):
    """
    Checkout page - accepts plan_id, looks up details automatically.
    Cross-platform support: web, android, ios
    """
    if plan_id not in APP_PLANS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Invalid plan: {plan_id}")
    
    if not settings.FLUTTERWAVE_PUBLIC_KEY:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Payment service not configured",
        )
    
    plan = APP_PLANS[plan_id]
    flw_plan_id = await _get_or_create_flw_plan(plan_id)
    
    if not tx_ref:
        tx_ref = f"PR-{int(datetime.now(timezone.utc).timestamp())}-{plan_id}"
    
    methods = await _get_flw_payment_methods(currency)
    payment_options = ",".join(methods)
    
    # Platform-specific handling
    redirects = _get_platform_redirect_urls(platform, request)
    
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
    
    # Platform-specific post-message handling
    post_message_script = ""
    if platform == "android":
        post_message_script = """
            // Android WebView communication
            if (window.PromptReelAndroid) {
                window.PromptReelAndroid.onPaymentSuccess(JSON.stringify(data));
            }
        """
    elif platform == "ios":
        post_message_script = """
            // iOS WKWebView communication
            if (window.webkit && window.webkit.messageHandlers) {
                window.webkit.messageHandlers.PromptReel.postMessage(JSON.stringify(data));
            }
        """
    else:
        post_message_script = """
            // Web: redirect parent or opener
            if (window.opener) {
                window.opener.postMessage({type: 'PAYMENT_SUCCESS', data: data}, '*');
            }
        """
    
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
    .auto-renew{{background:#FFB83020;color:#FFB830;font-size:12px;padding:6px 12px;border-radius:20px;display:inline-block;margin-top:8px;}}
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
    .platform-badge{{position:absolute;top:16px;right:16px;background:#2A2A3A;color:#888;font-size:11px;padding:4px 8px;border-radius:4px;}}
  </style>
</head>
<body>
<div class="card">
  <div class="platform-badge">{platform.upper()}</div>
  <div class="logo">🎬</div>
  <div class="brand">PromptReel AI</div>
  <div class="tagline">AI Video Production Platform</div>
  
  <div class="plan-box">
    <div class="plan-name">{safe_plan} Plan</div>
    <div class="price"><span>$</span>{plan['amount']}</div>
    <div class="period">per month</div>
    <div class="auto-renew">🔄 Auto-renews monthly</div>
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
    <span id="btnText">Subscribe ${plan['amount']}/month</span>
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
        redirect_url: '{redirects['callback']}',
        customer: {{
          email: '{safe_email}',
          name: '{safe_name}',
          phone_number: '0000000000'
        }},
        meta: {{
          plan_id: '{plan_id}',
          flw_plan_id: '{flw_plan_id}',
          platform: '{platform}',
          source: 'checkout_page'
        }},
        customizations: {{
          title: 'PromptReel AI',
          description: '{safe_plan} Plan Subscription',
          logo: 'https://promptreel.ai/logo.png'
        }},
        callback: function(data) {{
          console.log('Payment callback:', data);
          status.textContent = 'Payment ' + data.status + '! Processing...';
          
          const result = {{
            status: data.status,
            transaction_id: data.transaction_id,
            tx_ref: '{safe_tx_ref}',
            plan_id: '{plan_id}'
          }};
          
          {post_message_script}
          
          // Also try to redirect
          setTimeout(() => {{
            window.location.href = '{redirects['success']}?tx_ref={safe_tx_ref}&transaction_id=' + (data.transaction_id || '') + '&status=' + data.status;
          }}, 1000);
        }},
        onclose: function() {{
          btn.disabled = false;
          loading.style.display = 'none';
          btnText.textContent = 'Subscribe ${plan['amount']}/month';
          status.textContent = 'Payment cancelled. You can try again.';
          
          // Notify app of cancellation
          const cancelData = {{status: 'cancelled', tx_ref: '{safe_tx_ref}'}};
          {post_message_script.replace('onPaymentSuccess', 'onPaymentCancelled').replace('PAYMENT_SUCCESS', 'PAYMENT_CANCELLED')}
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
  
  // Auto-start after 500ms for better UX
  setTimeout(makePayment, 500);
</script>
</body>
</html>"""
    
    return HTMLResponse(
        content=html,
        headers={"Cache-Control": "no-cache, no-store, must-revalidate"},
    )


@router.get("/callback")
async def payment_callback(
    tx_ref: str,
    transaction_id: Optional[str] = None,
    status: Optional[str] = None,
    request: Request = None,
):
    """Handle return from Flutterwave. Works for all platforms."""
    platform = detect_platform(
        request.headers.get("user-agent", ""),
        request.headers.get("referer", "")
    )
    
    # For mobile apps, return deep link response
    if platform in ["android", "ios"]:
        return {
            "status": status or "unknown",
            "tx_ref": tx_ref,
            "transaction_id": transaction_id,
            "platform": platform,
            "message": "Payment completed. Return to app to verify.",
            "deep_link": f"promptreel://payment/verify?tx_ref={tx_ref}&transaction_id={transaction_id}&status={status}"
        }
    
    # For web, return JSON that frontend can handle
    return {
        "status": status or "unknown",
        "tx_ref": tx_ref,
        "transaction_id": transaction_id,
        "message": "Payment completed. Verifying...",
        "next_step": "Call POST /api/payments/verify to complete"
    }


@router.post("/verify")
async def verify_payment(
    req: VerifyPaymentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Verify payment and upgrade user plan.
    Handles transaction_id="0" by looking up tx_ref.
    Sets up auto-renewal subscription.
    """
    if req.plan_id not in APP_PLANS:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid plan")
    
    # Lookup transaction if ID not provided or is placeholder
    tx_data = None
    if req.transaction_id and req.transaction_id not in ("0", "pending", ""):
        tx_data = await _verify_with_flutterwave(req.transaction_id)
    else:
        logger.info(f"Looking up transaction by tx_ref: {req.tx_ref}")
        tx_lookup = await _lookup_tx_by_ref(req.tx_ref)
        
        if not tx_lookup:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Payment still processing. Please wait 30 seconds and try again.",
            )
        
        tx_id = str(tx_lookup.get("id"))
        tx_data = await _verify_with_flutterwave(tx_id)
        req.transaction_id = tx_id
    
    if not tx_data:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Could not retrieve transaction data",
        )
    
    # Validate payment status
    payment_status = tx_data.get("status")
    if payment_status != "successful":
        raise HTTPException(
            status.HTTP_402_PAYMENT_REQUIRED,
            f"Payment failed or pending: {payment_status}",
        )
    
    # Validate amount
    expected_amount = APP_PLANS[req.plan_id]["amount"]
    charged_amount = float(tx_data.get("charged_amount", 0))
    
    if abs(charged_amount - expected_amount) > 0.50:
        logger.warning(f"Amount mismatch: expected ${expected_amount}, got ${charged_amount}")
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Payment amount mismatch. Expected ${expected_amount}, received ${charged_amount}",
        )
    
    # Validate currency
    expected_currency = APP_PLANS[req.plan_id]["currency"]
    if tx_data.get("currency") != expected_currency:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Currency mismatch. Expected {expected_currency}",
        )
    
    # Get subscription details for auto-renewal
    flw_plan_id = tx_data.get("plan", {}).get("id") or await _get_or_create_flw_plan(req.plan_id)
    subscription_id = tx_data.get("plan_token")  # Flutterwave subscription token
    
    # Upgrade user with subscription info
    try:
        current_user.plan = PlanType(req.plan_id)
        current_user.subscription_status = SubscriptionStatus.ACTIVE
        current_user.subscription_started_at = datetime.now(timezone.utc)
        current_user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
        current_user.subscription_id = subscription_id or req.transaction_id
        current_user.flw_plan_id = str(flw_plan_id)
        current_user.flw_customer_id = tx_data.get("customer", {}).get("id")
        current_user.payment_method = tx_data.get("payment_type", "unknown")
        current_user.auto_renew = True
        
        await db.commit()
        await db.refresh(current_user)
    except Exception as e:
        logger.error(f"Database error upgrading user: {e}")
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "Failed to upgrade plan. Please contact support.",
        )
    
    payment_method = tx_data.get("payment_type", "unknown")
    
    logger.info(
        f"✅ User {current_user.id} upgraded to {req.plan_id} | "
        f"tx={req.transaction_id} | method={payment_method} | "
        f"amount=${charged_amount} | auto_renew=True"
    )
    
    return {
        "success": True,
        "plan": req.plan_id,
        "plan_name": APP_PLANS[req.plan_id]["name"],
        "message": f"🎉 Welcome to {APP_PLANS[req.plan_id]['name']} Plan!",
        "subscription": {
            "status": "active",
            "auto_renew": True,
            "expires_at": current_user.subscription_expires_at.isoformat(),
            "next_billing_date": (current_user.subscription_expires_at).isoformat(),
        },
        "payment_details": {
            "transaction_id": req.transaction_id,
            "amount": charged_amount,
            "currency": expected_currency,
            "method": payment_method,
            "tx_ref": req.tx_ref,
        },
        "features": APP_PLANS[req.plan_id]["features"],
    }


@router.get("/subscription/status")
async def get_subscription_status(
    current_user: User = Depends(get_current_user),
):
    """Get current subscription status for the user."""
    return {
        "status": "success",
        "subscription": {
            "plan": current_user.plan.value if hasattr(current_user.plan, 'value') else str(current_user.plan),
            "status": current_user.subscription_status.value if hasattr(current_user.subscription_status, 'value') else str(current_user.subscription_status),
            "auto_renew": getattr(current_user, 'auto_renew', True),
            "expires_at": current_user.subscription_expires_at.isoformat() if current_user.subscription_expires_at else None,
            "started_at": current_user.subscription_started_at.isoformat() if current_user.subscription_started_at else None,
        }
    }


@router.post("/subscription/cancel")
async def cancel_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel auto-renewal subscription."""
    if not current_user.subscription_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "No active subscription found",
        )
    
    # Cancel in Flutterwave if we have a subscription ID
    if current_user.flw_plan_id:
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                resp = await client.post(
                    f"{FLW_BASE_URL}/subscriptions/{current_user.subscription_id}/cancel",
                    headers=_flw_headers(),
                )
                if resp.status_code in (200, 201):
                    logger.info(f"Cancelled subscription in Flutterwave: {current_user.subscription_id}")
        except Exception as e:
            logger.error(f"Failed to cancel in Flutterwave: {e}")
            # Continue to cancel locally even if FLW fails
    
    # Update user
    current_user.auto_renew = False
    current_user.subscription_status = SubscriptionStatus.CANCELLED
    await db.commit()
    
    return {
        "success": True,
        "message": "Subscription cancelled. You have access until the end of your billing period.",
        "access_until": current_user.subscription_expires_at.isoformat() if current_user.subscription_expires_at else None,
    }


@router.post("/webhook")
async def flutterwave_webhook(
    request: Request,
    verif_hash: Optional[str] = Header(None, alias="verif-hash"),
    db: AsyncSession = Depends(get_db),
):
    """Handle Flutterwave webhooks for auto-renewal and lifecycle events."""
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
    
    # Handle successful subscription charge (auto-renewal)
    if event == "charge.completed":
        tx_status = data.get("status")
        tx_ref = data.get("tx_ref")
        flw_plan_id = data.get("plan", {}).get("id")
        
        if tx_status == "successful":
            # Find user by customer email or tx_ref pattern
            customer_email = data.get("customer", {}).get("email")
            user_id_from_ref = None
            
            # Extract user ID from tx_ref (format: PR-{user_id}-{plan}-{timestamp})
            if tx_ref and tx_ref.startswith("PR-"):
                parts = tx_ref.split("-")
                if len(parts) >= 2:
                    try:
                        user_id_from_ref = int(parts[1])
                    except ValueError:
                        pass
            
            # Update subscription expiry
            if user_id_from_ref:
                from sqlalchemy import select
                result = await db.execute(select(User).where(User.id == user_id_from_ref))
                user = result.scalar_one_or_none()
                
                if user and user.subscription_status == SubscriptionStatus.ACTIVE:
                    # Extend subscription by 30 days
                    user.subscription_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
                    user.subscription_id = data.get("plan_token") or user.subscription_id
                    await db.commit()
                    logger.info(f"🔄 Auto-renewed subscription for user {user.id}, new expiry: {user.subscription_expires_at}")
    
    # Handle subscription cancellation
    elif event in ("subscription.cancelled", "payment_plan.subscription_cancelled"):
        flw_subscription_id = data.get("id") or data.get("subscription_id")
        if flw_subscription_id:
            result = await db.execute(select(User).where(User.subscription_id == flw_subscription_id))
            user = result.scalar_one_or_none()
            if user:
                user.auto_renew = False
                user.subscription_status = SubscriptionStatus.CANCELLED
                await db.commit()
                logger.info(f"❌ Subscription cancelled for user {user.id}")
    
    # Handle failed subscription charge
    elif event == "charge.failed":
        tx_ref = data.get("tx_ref")
        if tx_ref and tx_ref.startswith("PR-"):
            parts = tx_ref.split("-")
            if len(parts) >= 2:
                try:
                    user_id = int(parts[1])
                    result = await db.execute(select(User).where(User.id == user_id))
                    user = result.scalar_one_or_none()
                    if user:
                        # Don't cancel immediately, mark for retry
                        logger.warning(f"⚠️ Payment failed for user {user.id}, tx_ref: {tx_ref}")
                        # Could send email notification here
                except ValueError:
                    pass
    
    # Handle subscription created (initial signup)
    elif event == "subscription.created":
        logger.info(f"New subscription created: {data.get('id')}")
    
    return {"status": "ok"}


@router.post("/subscription/sync")
async def sync_subscription_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Manually sync subscription status with Flutterwave."""
    if not current_user.subscription_id:
        return {"status": "no_subscription"}
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.get(
                f"{FLW_BASE_URL}/subscriptions/{current_user.subscription_id}",
                headers=_flw_headers(),
            )
            
            if resp.status_code == 200:
                sub_data = resp.json().get("data", {})
                flw_status = sub_data.get("status")
                
                # Sync status
                if flw_status == "active":
                    current_user.subscription_status = SubscriptionStatus.ACTIVE
                    current_user.auto_renew = True
                elif flw_status == "cancelled":
                    current_user.subscription_status = SubscriptionStatus.CANCELLED
                    current_user.auto_renew = False
                elif flw_status == "expired":
                    current_user.subscription_status = SubscriptionStatus.EXPIRED
                    current_user.auto_renew = False
                
                await db.commit()
                
                return {
                    "status": "synced",
                    "flutterwave_status": flw_status,
                    "local_status": current_user.subscription_status.value,
                    "next_payment": sub_data.get("next_payment_date"),
                }
            else:
                return {"status": "error", "message": "Could not fetch from Flutterwave"}
    except Exception as e:
        logger.error(f"Sync error: {e}")
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Could not sync subscription")


@router.on_event("startup")
async def initialize_payment_plans():
    """Pre-create plans on startup."""
    try:
        for plan_key in APP_PLANS:
            await _get_or_create_flw_plan(plan_key)
        logger.info("✅ Payment plans initialized in Flutterwave")
    except Exception as e:
        logger.error(f"Failed to initialize payment plans: {e}")
