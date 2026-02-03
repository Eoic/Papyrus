"""Tests for series endpoints."""

from fastapi.testclient import TestClient


def test_list_series(client: TestClient, auth_headers: dict[str, str]):
    """Test listing series."""
    response = client.get("/v1/series", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "series" in data


def test_create_series(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a series."""
    response = client.post(
        "/v1/series",
        headers=auth_headers,
        json={
            "name": "Harry Potter",
            "author": "J.K. Rowling",
            "total_books": 7,
            "is_complete": True,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Harry Potter"


def test_get_series(client: TestClient, auth_headers: dict[str, str], series_id: str):
    """Test getting a series by ID."""
    response = client.get(f"/v1/series/{series_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "books" in data  # SeriesWithBooks includes books


def test_update_series(client: TestClient, auth_headers: dict[str, str], series_id: str):
    """Test updating a series."""
    response = client.patch(
        f"/v1/series/{series_id}",
        headers=auth_headers,
        json={"is_complete": True},
    )
    assert response.status_code == 200


def test_delete_series(client: TestClient, auth_headers: dict[str, str], series_id: str):
    """Test deleting a series."""
    response = client.delete(f"/v1/series/{series_id}", headers=auth_headers)
    assert response.status_code == 204
