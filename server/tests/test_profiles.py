"""Tests for community profile endpoints."""

from fastapi.testclient import TestClient


def test_get_own_profile(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/profiles/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "user_id" in data
    assert "display_name" in data
    assert "follower_count" in data


def test_update_profile(client: TestClient, auth_headers: dict[str, str]):
    response = client.patch(
        "/v1/profiles/me",
        headers=auth_headers,
        json={"username": "testuser", "bio": "I love reading"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "testuser"
    assert data["bio"] == "I love reading"


def test_get_profile_by_username(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/profiles/someuser", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "user_id" in data


def test_unauthorized_profile(client: TestClient):
    response = client.get("/v1/profiles/me")
    assert response.status_code in (401, 403)
