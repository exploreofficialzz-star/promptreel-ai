"""
Shared pytest fixtures for PromptReel AI backend tests.
Uses SQLite in-memory database — no PostgreSQL needed in CI.
"""
import os
import uuid

# Set env vars BEFORE importing any app modules
os.environ["DATABASE_URL"]  = "sqlite+aiosqlite:///./test.db"
os.environ["SECRET_KEY"]    = "test-secret-key-32-chars-minimum!!"
os.environ["ENVIRONMENT"]   = "test"
os.environ["DEBUG"]         = "true"

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from database import Base, get_db
from main import app

# ── Test DB engine ────────────────────────────────────────────────────────────
TEST_DB_URL  = "sqlite+aiosqlite:///./test.db"
test_engine  = create_async_engine(TEST_DB_URL, echo=False)
TestSession  = async_sessionmaker(
    test_engine, class_=AsyncSession,
    expire_on_commit=False, autocommit=False, autoflush=False,
)


async def override_get_db():
    async with TestSession() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


app.dependency_overrides[get_db] = override_get_db


# ── Session-scoped DB setup ───────────────────────────────────────────────────
@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_test_db():
    """Create tables once for the whole test session, drop at the end."""
    from models import user, project  # noqa: F401 — registers models with Base
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await test_engine.dispose()


# ── Function-scoped HTTP client ───────────────────────────────────────────────
@pytest_asyncio.fixture
async def client() -> AsyncClient:
    """Fresh async HTTP client per test."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac


# ── Unique-email helpers ──────────────────────────────────────────────────────
def unique_email(prefix: str = "user") -> str:
    """Generate a unique email so tests never collide."""
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.com"


# ── Auth fixtures (function-scoped, unique email per test) ────────────────────
@pytest_asyncio.fixture
async def auth_headers(client: AsyncClient) -> dict:
    """
    Register a unique user per test and return Authorization headers.
    Using unique emails prevents 'duplicate email' failures when tests
    share a session-level DB.
    """
    email = unique_email("auth")
    pwd   = "TestPass123!"

    reg_resp = await client.post("/api/register", json={
        "email": email,
        "password": pwd,
        "name": "Test User",
    })
    data  = reg_resp.json()
    token = data.get("access_token")

    if not token:
        # Registration may require verification — fall back to login
        login_resp = await client.post("/api/login", json={
            "email": email, "password": pwd,
        })
        token = login_resp.json().get("access_token", "")

    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def registered_user(client: AsyncClient) -> dict:
    """Register a unique user and return the full response dict."""
    resp = await client.post("/api/register", json={
        "email": unique_email("reg"),
        "password": "TestPass123!",
        "name": "Reg User",
    })
    return resp.json()
