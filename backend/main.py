from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import logging
import time

from config import settings
from database import create_tables
from routers import auth, generate, projects, export, payments

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ─── Rate Limiter ──────────────────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address, default_limits=["200/minute"])


# ─── Lifespan ─────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 PromptReel AI Backend starting...")
    await create_tables()
    logger.info(f"✅ {settings.APP_NAME} v{settings.APP_VERSION} ready")
    yield
    logger.info("🛑 PromptReel AI Backend shutting down...")


# ─── App ──────────────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI Video Production Planning API — Turn ideas into complete video packages",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan,
)

# ─── Rate Limiter State ────────────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ─── Middleware ────────────────────────────────────────────────────────────────

# Trusted hosts (prevents host header injection)
if not settings.DEBUG:
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=[
            "promptreel-ai.onrender.com",
            "app.promptreel.ai",
            "promptreel.ai",
            "localhost",
            "127.0.0.1",
        ],
    )

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=[
        "Accept", "Accept-Language", "Content-Language",
        "Content-Type", "Authorization", "X-Requested-With",
    ],
    max_age=600,
)
app.add_middleware(GZipMiddleware, minimum_size=1000)


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"]         = f"{process_time:.3f}s"
    response.headers["X-Powered-By"]           = "PromptReel AI by chAs Tech Group"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"]        = "DENY"
    response.headers["X-XSS-Protection"]       = "1; mode=block"
    response.headers["Referrer-Policy"]        = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"]     = "camera=(), microphone=(), geolocation=()"
    if not settings.DEBUG:
        response.headers["Strict-Transport-Security"] = (
            "max-age=63072000; includeSubDomains; preload"
        )
    return response


# ─── Exception Handlers ───────────────────────────────────────────────────────
@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=404,
        content={"error": "Not found", "path": str(request.url.path)},
    )


@app.exception_handler(405)
async def method_not_allowed_handler(request: Request, exc):
    return JSONResponse(status_code=405, content={"error": "Method not allowed"})


@app.exception_handler(500)
async def internal_error_handler(request: Request, exc):
    logger.error(f"Internal error on {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error. Please try again."},
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.critical(
        f"Unhandled exception on {request.method} {request.url.path}: {exc}",
        exc_info=True,
    )
    return JSONResponse(status_code=500, content={"error": "An unexpected error occurred."})


# ─── Routers ──────────────────────────────────────────────────────────────────
app.include_router(auth.router, prefix="/api")
app.include_router(generate.router, prefix="/api")
app.include_router(projects.router, prefix="/api")
app.include_router(export.router, prefix="/api")
app.include_router(payments.router, prefix="/api")


# ─── Health & Root ────────────────────────────────────────────────────────────
@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "tagline": "Turn simple ideas into complete AI video production plans.",
        "status": "operational",
        "developer": "chAs Tech Group",
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


@app.get("/api/plans")
async def get_plans():
    """Return subscription plan details."""
    return {
        "plans": [
            {
                "id": "free",
                "name": "Free",
                "price_monthly": 0,
                "features": [
                    "3 video plans per day",
                    "Up to 5-minute videos",
                    "All content types",
                    "Basic export",
                ],
                "limits": {"daily_plans": 3, "max_duration_minutes": 5},
            },
            {
                "id": "creator",
                "name": "Creator",
                "price_monthly": 15,
                "features": [
                    "Unlimited video plans",
                    "Up to 20-minute videos",
                    "No ads",
                    "Full export package",
                    "Advanced AI prompts",
                    "Batch planner",
                    "Priority processing",
                ],
                "limits": {"daily_plans": -1, "max_duration_minutes": 20},
                "popular": True,
            },
            {
                "id": "studio",
                "name": "Studio",
                "price_monthly": 35,
                "features": [
                    "Everything in Creator",
                    "Team collaboration",
                    "Priority processing",
                    "API access",
                    "Custom branding",
                    "Dedicated support",
                ],
                "limits": {"daily_plans": -1, "max_duration_minutes": 20},
            },
        ]
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        workers=1 if settings.DEBUG else 4,
        proxy_headers=True,
        forwarded_allow_ips="*",
    )
