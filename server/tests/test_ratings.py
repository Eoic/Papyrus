"""Tests for rating endpoints."""

from uuid import uuid4

from fastapi.testclient import TestClient


def test_rate_book(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/v1/ratings",
        headers=auth_headers,
        json={"catalog_book_id": str(uuid4()), "score": 8},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["score"] == 8


def test_update_rating(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.patch(
        f"/v1/ratings/{book_id}",
        headers=auth_headers,
        json={"score": 9},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["score"] == 9


def test_delete_rating(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.delete(f"/v1/ratings/{book_id}", headers=auth_headers)
    assert response.status_code == 204


def test_invalid_rating_score(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/v1/ratings",
        headers=auth_headers,
        json={"catalog_book_id": str(uuid4()), "score": 11},
    )
    assert response.status_code == 422
