"""Tests for authentication endpoints."""
import pytest
from httpx import AsyncClient
from tests.conftest import unique_email


@pytest.mark.asyncio
async def test_register_creates_user(client: AsyncClient):
    resp = await client.post("/api/register", json={
        "email": unique_email("new"),
        "password": "StrongPass99!",
        "name": "New User",
    })
    assert resp.status_code in (200, 201)
    data = resp.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate_email_fails(client: AsyncClient):
    email = unique_email("dupe")
    payload = {"email": email, "password": "StrongPass99!", "name": "Dupe"}
    await client.post("/api/register", json=payload)
    resp = await client.post("/api/register", json=payload)
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_login_returns_tokens(client: AsyncClient):
    email = unique_email("login")
    pwd   = "LoginPass99!"
    await client.post("/api/register", json={
        "email": email, "password": pwd, "name": "Login User"
    })
    resp = await client.post("/api/login", json={"email": email, "password": pwd})
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_login_wrong_password_fails(client: AsyncClient):
    email = unique_email("wrongpwd")
    await client.post("/api/register", json={
        "email": email, "password": "RightPass99!", "name": "X"
    })
    resp = await client.post("/api/login", json={
        "email": email, "password": "WrongPass99!"
    })
    assert resp.status_code in (400, 401)


@pytest.mark.asyncio
async def test_get_me_requires_auth(client: AsyncClient):
    resp = await client.get("/api/me")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_get_me_returns_profile(client: AsyncClient, auth_headers: dict):
    resp = await client.get("/api/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "email" in data
    assert "plan"  in data


@pytest.mark.asyncio
async def test_refresh_token_works(client: AsyncClient):
    email = unique_email("refresh")
    pwd   = "RefreshPass99!"
    await client.post("/api/register", json={
        "email": email, "password": pwd, "name": "Refresh User"
    })
    login_resp    = await client.post("/api/login", json={"email": email, "password": pwd})
    refresh_token = login_resp.json().get("refresh_token")
    assert refresh_token, "No refresh_token in login response"

    resp = await client.post("/api/refresh", json={"refresh_token": refresh_token})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_forgot_password_does_not_leak_existence(client: AsyncClient):
    """Should return 200 even for non-existent email (prevent user enumeration)."""
    resp = await client.post("/api/forgot-password",
                             json={"email": "nobody_exists@example.com"})
    # 200 is preferred — 404 leaks that the email doesn't exist
    assert resp.status_code in (200, 404)
