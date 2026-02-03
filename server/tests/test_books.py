"""Tests for book endpoints."""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient


def test_list_books(client: TestClient, auth_headers: dict[str, str]):
    """Test listing books."""
    response = client.get("/v1/books", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "books" in data
    assert "pagination" in data


def test_list_books_with_filters(client: TestClient, auth_headers: dict[str, str]):
    """Test listing books with filters."""
    response = client.get(
        "/v1/books",
        headers=auth_headers,
        params={
            "status": "in_progress",
            "is_favorite": True,
            "page": 1,
            "limit": 10,
        },
    )
    assert response.status_code == 200


def test_create_book(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a book."""
    response = client.post(
        "/v1/books",
        headers=auth_headers,
        json={
            "title": "Test Book",
            "author": "Test Author",
            "isbn": "1234567890",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Book"
    assert data["author"] == "Test Author"


def test_get_book(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test getting a book by ID."""
    response = client.get(f"/v1/books/{book_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "book_id" in data


def test_update_book(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test updating a book."""
    response = client.patch(
        f"/v1/books/{book_id}",
        headers=auth_headers,
        json={"title": "Updated Title"},
    )
    assert response.status_code == 200


def test_delete_book(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test deleting a book."""
    response = client.delete(f"/v1/books/{book_id}", headers=auth_headers)
    assert response.status_code == 204


def test_get_book_shelves(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test getting book's shelves."""
    response = client.get(f"/v1/books/{book_id}/shelves", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "shelves" in data


def test_set_book_shelves(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test setting book's shelves."""
    shelf_id = str(uuid4())
    response = client.put(
        f"/v1/books/{book_id}/shelves",
        headers=auth_headers,
        json={"shelf_ids": [shelf_id]},
    )
    assert response.status_code == 200


def test_get_book_tags(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test getting book's tags."""
    response = client.get(f"/v1/books/{book_id}/tags", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "tags" in data


def test_set_book_tags(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test setting book's tags."""
    tag_id = str(uuid4())
    response = client.put(
        f"/v1/books/{book_id}/tags",
        headers=auth_headers,
        json={"tag_ids": [tag_id]},
    )
    assert response.status_code == 200


def test_get_book_progress(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test getting book's reading progress."""
    response = client.get(f"/v1/books/{book_id}/progress", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "book_id" in data


def test_update_book_progress(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test updating book's reading progress."""
    response = client.put(
        f"/v1/books/{book_id}/progress",
        headers=auth_headers,
        json={
            "reading_status": "in_progress",
            "current_position": 0.25,
        },
    )
    assert response.status_code == 200


def test_batch_create_books(client: TestClient, auth_headers: dict[str, str]):
    """Test batch creating books."""
    response = client.post(
        "/v1/books/batch",
        headers=auth_headers,
        json={
            "books": [
                {"title": "Book 1", "author": "Author 1"},
                {"title": "Book 2", "author": "Author 2"},
            ]
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert len(data["created"]) == 2


def test_batch_update_books(client: TestClient, auth_headers: dict[str, str]):
    """Test batch updating books."""
    book_ids = [str(uuid4()), str(uuid4())]
    response = client.patch(
        "/v1/books/batch",
        headers=auth_headers,
        json={
            "book_ids": book_ids,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["updated_count"] == 2


def test_batch_delete_books(client: TestClient, auth_headers: dict[str, str]):
    """Test batch deleting books."""
    book_ids = [str(uuid4()), str(uuid4())]
    response = client.request(
        "DELETE",
        "/v1/books/batch",
        headers=auth_headers,
        json={"book_ids": book_ids, "delete_files": False},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["deleted_count"] == 2


def test_fetch_book_metadata(client: TestClient, auth_headers: dict[str, str]):
    """Test fetching book metadata from online sources."""
    response = client.post(
        "/v1/books/metadata/fetch",
        headers=auth_headers,
        json={"isbn": "9780142424179"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "results" in data
