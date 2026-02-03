"""Tests for bookmark endpoints."""

import pytest
from fastapi.testclient import TestClient


def test_list_bookmarks(client: TestClient, auth_headers: dict[str, str]):
    """Test listing all bookmarks."""
    response = client.get("/v1/bookmarks", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "bookmarks" in data


def test_list_book_bookmarks(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test listing bookmarks for a specific book."""
    response = client.get(f"/v1/bookmarks/books/{book_id}", headers=auth_headers)
    assert response.status_code == 200


def test_create_bookmark(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test creating a bookmark."""
    response = client.post(
        f"/v1/bookmarks/books/{book_id}",
        headers=auth_headers,
        json={
            "position": "epubcfi(/6/4[chap01]!/4/2/1:0)",
            "page_number": 42,
            "chapter_title": "Chapter 3",
            "note": "Interesting part",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["page_number"] == 42


def test_get_bookmark(client: TestClient, auth_headers: dict[str, str], bookmark_id: str):
    """Test getting a bookmark by ID."""
    response = client.get(f"/v1/bookmarks/{bookmark_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_bookmark(client: TestClient, auth_headers: dict[str, str], bookmark_id: str):
    """Test updating a bookmark."""
    response = client.patch(
        f"/v1/bookmarks/{bookmark_id}",
        headers=auth_headers,
        json={"note": "Updated note"},
    )
    assert response.status_code == 200


def test_delete_bookmark(client: TestClient, auth_headers: dict[str, str], bookmark_id: str):
    """Test deleting a bookmark."""
    response = client.delete(f"/v1/bookmarks/{bookmark_id}", headers=auth_headers)
    assert response.status_code == 204
