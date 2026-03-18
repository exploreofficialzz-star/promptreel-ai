"""
PromptReel AI — Email Service (Resend)
Free tier: 3000 emails/month
No domain needed — using Resend's free onboarding sender.
Sign up at https://resend.com to get your RESEND_API_KEY.
"""
import httpx
import logging
import random
import string
from datetime import datetime, timedelta, timezone
from config import settings

logger = logging.getLogger(__name__)


def generate_code(length: int = 6) -> str:
    """Generate a random 6-digit numeric code."""
    return ''.join(random.choices(string.digits, k=length))


def code_expires_at(minutes: int = 15) -> datetime:
    """Return expiry datetime minutes from now."""
    return datetime.now(timezone.utc) + timedelta(minutes=minutes)


async def send_email(to: str, subject: str, html: str) -> bool:
    """Send email via Resend API."""
    if not settings.RESEND_API_KEY:
        logger.warning("⚠️ RESEND_API_KEY not set — email not sent")
        return False

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    # ── No domain needed — use Resend's free sender ──────────
                    "from": "PromptReel AI <onboarding@resend.dev>",
                    "to":   [to],
                    "subject": subject,
                    "html": html,
                },
            )

            if resp.status_code == 200 or resp.status_code == 201:
                logger.info(f"✅ Email sent to {to}: {subject}")
                return True
            else:
                logger.error(
                    f"❌ Email failed to {to}: "
                    f"status={resp.status_code} body={resp.text}"
                )
                return False

    except Exception as e:
        logger.error(f"❌ Email exception to {to}: {e}")
        return False


async def send_verification_email(
    to: str, name: str, code: str
) -> bool:
    html = f"""
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="background:#0A0A0F;margin:0;padding:40px 20px;
             font-family:Arial,sans-serif;">
  <div style="max-width:480px;margin:0 auto;background:#12121A;
              border-radius:16px;border:1px solid #2A2A3A;
              padding:40px;">

    <!-- Logo -->
    <div style="text-align:center;margin-bottom:28px;">
      <div style="background:linear-gradient(135deg,#FFB830,#FF8C00);
                  width:64px;height:64px;border-radius:50%;
                  display:inline-flex;align-items:center;
                  justify-content:center;font-size:30px;">
        🎬
      </div>
      <h1 style="color:#FFB830;margin:12px 0 4px;font-size:22px;
                 font-weight:800;">
        PromptReel AI
      </h1>
      <p style="color:#555;margin:0;font-size:13px;">
        AI Video Production Platform
      </p>
    </div>

    <!-- Title -->
    <h2 style="color:#fff;margin:0 0 8px;font-size:20px;
               font-weight:700;">
      Verify Your Email ✉️
    </h2>
    <p style="color:#888;margin:0 0 28px;font-size:14px;
              line-height:1.7;">
      Hi <strong style="color:#fff;">{name}</strong>!
      Welcome to PromptReel AI. Enter this 6-digit code
      to verify your account. Expires in <strong>15 minutes</strong>.
    </p>

    <!-- Code Box -->
    <div style="background:#1A1A2E;border:2px solid #FFB830;
                border-radius:14px;padding:28px;text-align:center;
                margin-bottom:28px;">
      <p style="color:#888;font-size:12px;margin:0 0 12px;
                text-transform:uppercase;letter-spacing:2px;">
        Verification Code
      </p>
      <div style="font-size:44px;font-weight:900;
                  letter-spacing:14px;color:#FFB830;
                  font-family:monospace;">
        {code}
      </div>
    </div>

    <!-- Footer -->
    <p style="color:#444;font-size:12px;text-align:center;
              margin:0;line-height:1.6;">
      If you didn't create a PromptReel AI account,
      you can safely ignore this email.<br><br>
      Made with ❤️ by <strong style="color:#666;">
        chAs Tech Group
      </strong>
    </p>
  </div>
</body>
</html>
"""
    return await send_email(
        to, "Verify your PromptReel AI account ✉️", html
    )


async def send_reset_email(
    to: str, name: str, code: str
) -> bool:
    html = f"""
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="background:#0A0A0F;margin:0;padding:40px 20px;
             font-family:Arial,sans-serif;">
  <div style="max-width:480px;margin:0 auto;background:#12121A;
              border-radius:16px;border:1px solid #2A2A3A;
              padding:40px;">

    <!-- Logo -->
    <div style="text-align:center;margin-bottom:28px;">
      <div style="background:linear-gradient(135deg,#FF4444,#CC0000);
                  width:64px;height:64px;border-radius:50%;
                  display:inline-flex;align-items:center;
                  justify-content:center;font-size:30px;">
        🔐
      </div>
      <h1 style="color:#FFB830;margin:12px 0 4px;font-size:22px;
                 font-weight:800;">
        PromptReel AI
      </h1>
      <p style="color:#555;margin:0;font-size:13px;">
        AI Video Production Platform
      </p>
    </div>

    <!-- Title -->
    <h2 style="color:#fff;margin:0 0 8px;font-size:20px;
               font-weight:700;">
      Reset Your Password 🔑
    </h2>
    <p style="color:#888;margin:0 0 28px;font-size:14px;
              line-height:1.7;">
      Hi <strong style="color:#fff;">{name}</strong>!
      We received a request to reset your password.
      Enter this 6-digit code in the app.
      Expires in <strong>15 minutes</strong>.
    </p>

    <!-- Code Box -->
    <div style="background:#1A1A2E;border:2px solid #FF4444;
                border-radius:14px;padding:28px;text-align:center;
                margin-bottom:28px;">
      <p style="color:#888;font-size:12px;margin:0 0 12px;
                text-transform:uppercase;letter-spacing:2px;">
        Reset Code
      </p>
      <div style="font-size:44px;font-weight:900;
                  letter-spacing:14px;color:#FF4444;
                  font-family:monospace;">
        {code}
      </div>
    </div>

    <!-- Warning -->
    <div style="background:#1A0A0A;border:1px solid #FF444433;
                border-radius:8px;padding:12px;margin-bottom:20px;">
      <p style="color:#FF8888;font-size:13px;margin:0;">
        ⚠️ If you didn't request this reset, your account
        may be at risk. Please secure your account immediately.
      </p>
    </div>

    <!-- Footer -->
    <p style="color:#444;font-size:12px;text-align:center;
              margin:0;line-height:1.6;">
      This code expires in 15 minutes and can only be used once.<br><br>
      Made with ❤️ by <strong style="color:#666;">
        chAs Tech Group
      </strong>
    </p>
  </div>
</body>
</html>
"""
    return await send_email(
        to, "Reset your PromptReel AI password 🔑", html
    )
