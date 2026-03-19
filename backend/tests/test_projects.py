"""Tests for projects endpoints."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_projects_requires_auth(client: AsyncClient):
    resp = await client.get("/api/projects")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_list_projects_empty_for_new_user(client: AsyncClient, auth_headers: dict):
    resp = await client.get("/api/projects", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "projects" in data or isinstance(data, list)


@pytest.mark.asyncio
async def test_get_stats_returns_counts(client: AsyncClient, auth_headers: dict):
    resp = await client.get("/api/projects/stats", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "total_plans_generated" in data or "total" in data


@pytest.mark.asyncio
async def test_delete_nonexistent_project_returns_404(client: AsyncClient, auth_headers: dict):
    resp = await client.delete("/api/projects/999999", headers=auth_headers)
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_payments_prices_endpoint(client: AsyncClient):
    resp = await client.get("/api/payments/prices")
    assert resp.status_code == 200
    data = resp.json()
    assert "creator" in data or "prices" in data
