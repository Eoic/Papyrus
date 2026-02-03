"""Tests for sync endpoints."""

from datetime import datetime, timezone
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient


def test_get_sync_status(client: TestClient, auth_headers: dict[str, str]):
    """Test getting sync status."""
    response = client.get("/v1/sync/status", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "status" in data


def test_pull_changes(client: TestClient, auth_headers: dict[str, str]):
    """Test pulling changes from server."""
    response = client.get("/v1/sync/changes", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "changes" in data
    assert "server_timestamp" in data


def test_push_changes(client: TestClient, auth_headers: dict[str, str]):
    """Test pushing changes to server."""
    now = datetime.now(timezone.utc)
    response = client.post(
        "/v1/sync/changes",
        headers=auth_headers,
        json={
            "changes": [
                {
                    "entity_type": "book",
                    "entity_id": str(uuid4()),
                    "operation": "update",
                    "data": {"title": "Updated Title"},
                    "timestamp": now.isoformat(),
                }
            ],
            "device_id": "device_123",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "accepted" in data
    assert "rejected" in data


def test_get_sync_conflicts(client: TestClient, auth_headers: dict[str, str]):
    """Test getting sync conflicts."""
    response = client.get("/v1/sync/conflicts", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "conflicts" in data


def test_force_sync(client: TestClient, auth_headers: dict[str, str]):
    """Test forcing a full sync."""
    response = client.post("/v1/sync/force", headers=auth_headers)
    assert response.status_code == 204


def test_get_metadata_server_config(client: TestClient, auth_headers: dict[str, str]):
    """Test getting metadata server configuration."""
    response = client.get("/v1/sync/config", headers=auth_headers)
    assert response.status_code == 200


def test_create_metadata_server_config(client: TestClient, auth_headers: dict[str, str]):
    """Test creating metadata server configuration."""
    response = client.post(
        "/v1/sync/config",
        headers=auth_headers,
        json={
            "server_url": "https://api.papyrus.app",
            "sync_enabled": True,
            "sync_interval_seconds": 30,
        },
    )
    assert response.status_code == 201


def test_delete_metadata_server_config(client: TestClient, auth_headers: dict[str, str]):
    """Test deleting metadata server configuration."""
    response = client.delete("/v1/sync/config", headers=auth_headers)
    assert response.status_code == 204


def test_test_metadata_server_connection(client: TestClient, auth_headers: dict[str, str]):
    """Test testing metadata server connection."""
    response = client.post("/v1/sync/config/test", headers=auth_headers)
    assert response.status_code == 200
