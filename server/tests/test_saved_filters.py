"""Tests for saved filter endpoints."""

from uuid import uuid4

from fastapi.testclient import TestClient


def test_list_saved_filters(client: TestClient, auth_headers: dict[str, str]):
    """Test listing saved filters."""
    response = client.get("/v1/saved-filters", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "filters" in data


def test_create_saved_filter(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a saved filter."""
    response = client.post(
        "/v1/saved-filters",
        headers=auth_headers,
        json={
            "name": "Unread Fiction",
            "query": "status:not_started tag:fiction",
            "filter_type": "custom",
            "is_pinned": True,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Unread Fiction"


def test_get_saved_filter(client: TestClient, auth_headers: dict[str, str]):
    """Test getting a saved filter by ID."""
    filter_id = str(uuid4())
    response = client.get(f"/v1/saved-filters/{filter_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_saved_filter(client: TestClient, auth_headers: dict[str, str]):
    """Test updating a saved filter."""
    filter_id = str(uuid4())
    response = client.patch(
        f"/v1/saved-filters/{filter_id}",
        headers=auth_headers,
        json={"name": "Updated Filter Name"},
    )
    assert response.status_code == 200


def test_delete_saved_filter(client: TestClient, auth_headers: dict[str, str]):
    """Test deleting a saved filter."""
    filter_id = str(uuid4())
    response = client.delete(f"/v1/saved-filters/{filter_id}", headers=auth_headers)
    assert response.status_code == 204


def test_use_saved_filter(client: TestClient, auth_headers: dict[str, str]):
    """Test marking a saved filter as used."""
    filter_id = str(uuid4())
    response = client.post(f"/v1/saved-filters/{filter_id}/use", headers=auth_headers)
    assert response.status_code == 200
