"""Tests for user book tracking endpoints."""

from uuid import uuid4

from fastapi.testclient import TestClient


def test_add_book_to_library(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/v1/user-books",
        headers=auth_headers,
        json={"catalog_book_id": str(uuid4()), "status": "want_to_read"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "want_to_read"


def test_update_book_status(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.patch(
        f"/v1/user-books/{book_id}",
        headers=auth_headers,
        json={"status": "reading"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "reading"


def test_remove_book_from_library(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.delete(f"/v1/user-books/{book_id}", headers=auth_headers)
    assert response.status_code == 204
