from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
import time

from config import settings
from database import create_tables
from routers import auth, generate, projects, export, payments

# ─── Logging ─────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ─── Lifespan ─────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀 PromptReel AI Backend starting...")
    await create_tables()
    logger.info(f"✅ {settings.APP_NAME} v{settings.APP_VERSION} ready")
    yield
    logger.info("🛑 PromptReel AI Backend shutting down...")


# ─── App ─────────────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI Video Production Planning API — Turn ideas into complete video packages",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan,
)

# ─── Middleware ───────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = f"{process_time:.3f}s"
    response.headers["X-Powered-By"] = "PromptReel AI by chAs Tech Group"
    return response


# ─── Exception Handlers ──────────────────────────────────────────────────────
@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=404,
        content={"error": "Not found", "path": str(request.url.path)},
    )


@app.exception_handler(500)
async def internal_error_handler(request: Request, exc):
    logger.error(f"Internal error on {request.url.path}: {exc}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error. Please try again."},
    )


# ─── Routers ─────────────────────────────────────────────────────────────────
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
)
