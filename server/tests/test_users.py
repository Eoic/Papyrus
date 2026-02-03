"""Tests for user endpoints."""

from fastapi.testclient import TestClient


def test_get_current_user(client: TestClient, auth_headers: dict[str, str]):
    """Test getting current user profile."""
    response = client.get("/v1/users/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "user_id" in data
    assert "email" in data
    assert "display_name" in data


def test_update_current_user(client: TestClient, auth_headers: dict[str, str]):
    """Test updating current user profile."""
    response = client.patch(
        "/v1/users/me",
        headers=auth_headers,
        json={"display_name": "Updated Name"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["display_name"] == "Updated Name"


def test_delete_current_user(client: TestClient, auth_headers: dict[str, str]):
    """Test deleting current user account."""
    response = client.request(
        "DELETE",
        "/v1/users/me",
        headers=auth_headers,
        json={"password": "current_password"},
    )
    assert response.status_code == 204


def test_get_user_preferences(client: TestClient, auth_headers: dict[str, str]):
    """Test getting user preferences."""
    response = client.get("/v1/users/me/preferences", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "theme" in data


def test_update_user_preferences(client: TestClient, auth_headers: dict[str, str]):
    """Test updating user preferences."""
    response = client.put(
        "/v1/users/me/preferences",
        headers=auth_headers,
        json={"theme": "light", "notifications_enabled": False},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["theme"] == "light"
    assert data["notifications_enabled"] is False


def test_change_password(client: TestClient, auth_headers: dict[str, str]):
    """Test changing user password."""
    response = client.post(
        "/v1/users/me/change-password",
        headers=auth_headers,
        json={
            "current_password": "old_password",
            "new_password": "NewSecureP@ss123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


def test_unauthorized_access(client: TestClient):
    """Test that endpoints require authentication."""
    response = client.get("/v1/users/me")
    assert response.status_code == 401  # No auth header
