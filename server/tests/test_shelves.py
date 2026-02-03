"""Tests for shelf endpoints."""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient


def test_list_shelves(client: TestClient, auth_headers: dict[str, str]):
    """Test listing shelves."""
    response = client.get("/v1/shelves", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "shelves" in data


def test_create_shelf(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a shelf."""
    response = client.post(
        "/v1/shelves",
        headers=auth_headers,
        json={
            "name": "Test Shelf",
            "color": "#FF5722",
            "description": "A test shelf",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Shelf"


def test_get_shelf(client: TestClient, auth_headers: dict[str, str], shelf_id: str):
    """Test getting a shelf by ID."""
    response = client.get(f"/v1/shelves/{shelf_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_shelf(client: TestClient, auth_headers: dict[str, str], shelf_id: str):
    """Test updating a shelf."""
    response = client.patch(
        f"/v1/shelves/{shelf_id}",
        headers=auth_headers,
        json={"name": "Updated Shelf Name"},
    )
    assert response.status_code == 200


def test_delete_shelf(client: TestClient, auth_headers: dict[str, str], shelf_id: str):
    """Test deleting a shelf."""
    response = client.delete(f"/v1/shelves/{shelf_id}", headers=auth_headers)
    assert response.status_code == 204


def test_list_shelf_books(client: TestClient, auth_headers: dict[str, str], shelf_id: str):
    """Test listing books in a shelf."""
    response = client.get(f"/v1/shelves/{shelf_id}/books", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "books" in data


def test_add_book_to_shelf(
    client: TestClient, auth_headers: dict[str, str], shelf_id: str, book_id: str
):
    """Test adding a book to a shelf."""
    response = client.post(
        f"/v1/shelves/{shelf_id}/books/{book_id}",
        headers=auth_headers,
    )
    assert response.status_code == 204


def test_remove_book_from_shelf(
    client: TestClient, auth_headers: dict[str, str], shelf_id: str, book_id: str
):
    """Test removing a book from a shelf."""
    response = client.delete(
        f"/v1/shelves/{shelf_id}/books/{book_id}",
        headers=auth_headers,
    )
    assert response.status_code == 204


def test_remove_multiple_books_from_shelf(
    client: TestClient, auth_headers: dict[str, str], shelf_id: str, book_id: str
):
    """Test removing multiple books from a shelf."""
    book_ids = [book_id, str(uuid4())]
    response = client.post(
        f"/v1/shelves/{shelf_id}/books/remove",
        headers=auth_headers,
        json={"book_ids": book_ids},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["removed_count"] == 2
