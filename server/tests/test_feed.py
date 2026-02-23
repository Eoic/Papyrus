"""Tests for activity feed endpoints."""

from fastapi.testclient import TestClient


def test_get_personal_feed(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/feed", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "activities" in data
    assert "pagination" in data


def test_get_global_feed(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/feed/global", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "activities" in data
