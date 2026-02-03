"""Tests for authentication endpoints."""

import pytest
from fastapi.testclient import TestClient


def test_register_user(client: TestClient):
    """Test user registration endpoint."""
    response = client.post(
        "/v1/auth/register",
        json={
            "email": "test@example.com",
            "password": "SecureP@ss123",
            "display_name": "Test User",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "user_id" in data
    assert data["email"] == "test@example.com"
    assert "message" in data


def test_login_user(client: TestClient):
    """Test user login endpoint."""
    response = client.post(
        "/v1/auth/login",
        json={
            "email": "test@example.com",
            "password": "password123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "Bearer"
    assert "expires_in" in data


def test_google_oauth(client: TestClient):
    """Test Google OAuth login endpoint."""
    response = client.post(
        "/v1/auth/oauth/google",
        json={"id_token": "fake_google_id_token"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


def test_refresh_token(client: TestClient):
    """Test token refresh endpoint."""
    response = client.post(
        "/v1/auth/refresh",
        json={"refresh_token": "fake_refresh_token"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


def test_logout_user(client: TestClient, auth_headers: dict[str, str]):
    """Test user logout endpoint."""
    response = client.post(
        "/v1/auth/logout",
        headers=auth_headers,
        json={"all_devices": False},
    )
    assert response.status_code == 204


def test_verify_email(client: TestClient):
    """Test email verification endpoint."""
    response = client.post(
        "/v1/auth/verify-email",
        json={"token": "verification_token"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


def test_forgot_password(client: TestClient):
    """Test forgot password endpoint."""
    response = client.post(
        "/v1/auth/forgot-password",
        json={"email": "test@example.com"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


def test_reset_password(client: TestClient):
    """Test password reset endpoint."""
    response = client.post(
        "/v1/auth/reset-password",
        json={
            "token": "reset_token",
            "password": "NewSecureP@ss123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
