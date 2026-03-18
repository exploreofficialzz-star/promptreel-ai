"""
PromptReel AI — Email Service (Resend)
Free tier: 3000 emails/month — plenty for verification & resets.
Sign up at https://resend.com and set RESEND_API_KEY in Render env vars.
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
        logger.warning("RESEND_API_KEY not set — email not sent")
        return False

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "from": f"PromptReel AI <{settings.EMAIL_FROM}>",
                    "to": [to],
                    "subject": subject,
                    "html": html,
                },
            )
            resp.raise_for_status()
            logger.info(f"✅ Email sent to {to}: {subject}")
            return True
    except Exception as e:
        logger.error(f"❌ Email failed to {to}: {e}")
        return False


async def send_verification_email(to: str, name: str, code: str) -> bool:
    html = f"""
    <!DOCTYPE html>
    <html>
    <body style="background:#0A0A0F;color:#fff;font-family:Arial,sans-serif;
                 margin:0;padding:40px 20px;">
      <div style="max-width:480px;margin:0 auto;background:#12121A;
                  border-radius:16px;border:1px solid #2A2A3A;padding:40px;">
        <div style="text-align:center;margin-bottom:32px;">
          <div style="background:linear-gradient(135deg,#FFB830,#FF8C00);
                      width:60px;height:60px;border-radius:50%;
                      display:inline-flex;align-items:center;
                      justify-content:center;font-size:28px;">🎬</div>
          <h1 style="color:#FFB830;margin:16px 0 4px;font-size:24px;">
            PromptReel AI
          </h1>
          <p style="color:#666;margin:0;font-size:14px;">
            AI Video Production Platform
          </p>
        </div>

        <h2 style="color:#fff;margin:0 0 8px;font-size:20px;">
          Verify Your Email
        </h2>
        <p style="color:#999;margin:0 0 32px;font-size:14px;line-height:1.6;">
          Hi {name}! Enter this 6-digit code to verify your
          PromptReel AI account. The code expires in 15 minutes.
        </p>

        <div style="background:#1A1A2E;border:2px solid #FFB830;
                    border-radius:12px;padding:24px;text-align:center;
                    margin-bottom:32px;">
          <div style="font-size:42px;font-weight:900;letter-spacing:12px;
                      color:#FFB830;font-family:monospace;">
            {code}
          </div>
        </div>

        <p style="color:#666;font-size:12px;text-align:center;margin:0;">
          If you didn't create a PromptReel AI account, ignore this email.<br>
          Made with ❤️ by chAs Tech Group
        </p>
      </div>
    </body>
    </html>
    """
    return await send_email(to, "Verify your PromptReel AI account", html)


async def send_reset_email(to: str, name: str, code: str) -> bool:
    html = f"""
    <!DOCTYPE html>
    <html>
    <body style="background:#0A0A0F;color:#fff;font-family:Arial,sans-serif;
                 margin:0;padding:40px 20px;">
      <div style="max-width:480px;margin:0 auto;background:#12121A;
                  border-radius:16px;border:1px solid #2A2A3A;padding:40px;">
        <div style="text-align:center;margin-bottom:32px;">
          <div style="background:linear-gradient(135deg,#FFB830,#FF8C00);
                      width:60px;height:60px;border-radius:50%;
                      display:inline-flex;align-items:center;
                      justify-content:center;font-size:28px;">🔐</div>
          <h1 style="color:#FFB830;margin:16px 0 4px;font-size:24px;">
            PromptReel AI
          </h1>
        </div>

        <h2 style="color:#fff;margin:0 0 8px;font-size:20px;">
          Reset Your Password
        </h2>
        <p style="color:#999;margin:0 0 32px;font-size:14px;line-height:1.6;">
          Hi {name}! Enter this 6-digit code to reset your password.
          The code expires in 15 minutes.
        </p>

        <div style="background:#1A1A2E;border:2px solid #FF4444;
                    border-radius:12px;padding:24px;text-align:center;
                    margin-bottom:32px;">
          <div style="font-size:42px;font-weight:900;letter-spacing:12px;
                      color:#FF4444;font-family:monospace;">
            {code}
          </div>
        </div>

        <p style="color:#666;font-size:12px;text-align:center;margin:0;">
          If you didn't request a password reset, ignore this email.<br>
          Made with ❤️ by chAs Tech Group
        </p>
      </div>
    </body>
    </html>
    """
    return await send_email(to, "Reset your PromptReel AI password", html)
