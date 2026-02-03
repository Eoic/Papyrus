"""Tests for reading profile endpoints."""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient


def test_list_reading_profiles(client: TestClient, auth_headers: dict[str, str]):
    """Test listing reading profiles."""
    response = client.get("/v1/reading-profiles", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "profiles" in data


def test_create_reading_profile(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a reading profile."""
    response = client.post(
        "/v1/reading-profiles",
        headers=auth_headers,
        json={
            "name": "Dark Mode Profile",
            "theme_mode": "dark",
            "font_family": "Georgia",
            "font_size": 18,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Dark Mode Profile"


def test_get_reading_profile(client: TestClient, auth_headers: dict[str, str]):
    """Test getting a reading profile by ID."""
    profile_id = str(uuid4())
    response = client.get(f"/v1/reading-profiles/{profile_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_reading_profile(client: TestClient, auth_headers: dict[str, str]):
    """Test updating a reading profile."""
    profile_id = str(uuid4())
    response = client.patch(
        f"/v1/reading-profiles/{profile_id}",
        headers=auth_headers,
        json={"font_size": 20},
    )
    assert response.status_code == 200


def test_delete_reading_profile(client: TestClient, auth_headers: dict[str, str]):
    """Test deleting a reading profile."""
    profile_id = str(uuid4())
    response = client.delete(f"/v1/reading-profiles/{profile_id}", headers=auth_headers)
    assert response.status_code == 204


def test_set_default_reading_profile(client: TestClient, auth_headers: dict[str, str]):
    """Test setting default reading profile."""
    profile_id = str(uuid4())
    response = client.post(
        f"/v1/reading-profiles/{profile_id}/set-default", headers=auth_headers
    )
    assert response.status_code == 200
