"""Tests for tag endpoints."""

import pytest
from fastapi.testclient import TestClient


def test_list_tags(client: TestClient, auth_headers: dict[str, str]):
    """Test listing tags."""
    response = client.get("/v1/tags", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "tags" in data


def test_create_tag(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a tag."""
    response = client.post(
        "/v1/tags",
        headers=auth_headers,
        json={
            "name": "Fiction",
            "color": "#4A90D9",
            "description": "Fiction books",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Fiction"
    assert data["color"] == "#4A90D9"


def test_get_tag(client: TestClient, auth_headers: dict[str, str], tag_id: str):
    """Test getting a tag by ID."""
    response = client.get(f"/v1/tags/{tag_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_tag(client: TestClient, auth_headers: dict[str, str], tag_id: str):
    """Test updating a tag."""
    response = client.patch(
        f"/v1/tags/{tag_id}",
        headers=auth_headers,
        json={"name": "Updated Tag"},
    )
    assert response.status_code == 200


def test_delete_tag(client: TestClient, auth_headers: dict[str, str], tag_id: str):
    """Test deleting a tag."""
    response = client.delete(f"/v1/tags/{tag_id}", headers=auth_headers)
    assert response.status_code == 204
