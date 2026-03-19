"""Tests for public endpoints — health check, root, plans."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_returns_200(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert "app" in data
    assert "version" in data


@pytest.mark.asyncio
async def test_root_returns_app_info(client: AsyncClient):
    resp = await client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["app"] == "PromptReel AI"
    assert data["status"] == "operational"


@pytest.mark.asyncio
async def test_plans_returns_three_tiers(client: AsyncClient):
    resp = await client.get("/api/plans")
    assert resp.status_code == 200
    plans = resp.json()["plans"]
    assert len(plans) == 3
    plan_ids = {p["id"] for p in plans}
    assert plan_ids == {"free", "creator", "studio"}


@pytest.mark.asyncio
async def test_plans_prices_correct(client: AsyncClient):
    resp = await client.get("/api/plans")
    plans = {p["id"]: p for p in resp.json()["plans"]}
    assert plans["free"]["price_monthly"] == 0
    assert plans["creator"]["price_monthly"] == 15.0
    assert plans["studio"]["price_monthly"] == 35.0


@pytest.mark.asyncio
async def test_unknown_route_returns_404(client: AsyncClient):
    resp = await client.get("/api/this-does-not-exist")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_security_headers_present(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.headers.get("x-content-type-options") == "nosniff"
    assert resp.headers.get("x-frame-options") == "DENY"
