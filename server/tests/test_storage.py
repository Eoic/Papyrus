"""Tests for storage backend endpoints."""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient


def test_list_storage_backends(client: TestClient, auth_headers: dict[str, str]):
    """Test listing storage backends."""
    response = client.get("/v1/storage/backends", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "backends" in data


def test_create_storage_backend(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a storage backend."""
    response = client.post(
        "/v1/storage/backends",
        headers=auth_headers,
        json={
            "backend_type": "local",
            "name": "My Local Storage",
            "is_primary": True,
            "base_path": "/storage/books",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "My Local Storage"


def test_get_storage_backend(client: TestClient, auth_headers: dict[str, str]):
    """Test getting a storage backend by ID."""
    backend_id = str(uuid4())
    response = client.get(f"/v1/storage/backends/{backend_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_storage_backend(client: TestClient, auth_headers: dict[str, str]):
    """Test updating a storage backend."""
    backend_id = str(uuid4())
    response = client.patch(
        f"/v1/storage/backends/{backend_id}",
        headers=auth_headers,
        json={"name": "Updated Storage Name"},
    )
    assert response.status_code == 200


def test_delete_storage_backend(client: TestClient, auth_headers: dict[str, str]):
    """Test deleting a storage backend."""
    backend_id = str(uuid4())
    response = client.delete(f"/v1/storage/backends/{backend_id}", headers=auth_headers)
    assert response.status_code == 204


def test_test_storage_backend(client: TestClient, auth_headers: dict[str, str]):
    """Test testing storage backend connection."""
    backend_id = str(uuid4())
    response = client.post(f"/v1/storage/backends/{backend_id}/test", headers=auth_headers)
    assert response.status_code == 200


def test_set_primary_storage_backend(client: TestClient, auth_headers: dict[str, str]):
    """Test setting primary storage backend."""
    backend_id = str(uuid4())
    response = client.post(
        "/v1/storage/backends/set-primary",
        headers=auth_headers,
        json={"backend_id": backend_id},
    )
    assert response.status_code == 200
