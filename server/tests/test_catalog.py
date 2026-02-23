"""Tests for catalog endpoints."""

from uuid import uuid4

from fastapi.testclient import TestClient


def test_search_catalog(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/catalog/search?q=dune", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "local_results" in data
    assert "open_library_results" in data


def test_get_catalog_book(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.get(f"/v1/catalog/books/{book_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "catalog_book_id" in data
    assert "title" in data


def test_add_catalog_book(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/v1/catalog/books",
        headers=auth_headers,
        json={"title": "My Book", "authors": ["Author Name"]},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "My Book"


def test_get_book_reviews(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.get(f"/v1/catalog/books/{book_id}/reviews", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "reviews" in data


def test_get_ratings_distribution(client: TestClient, auth_headers: dict[str, str]):
    book_id = str(uuid4())
    response = client.get(
        f"/v1/catalog/books/{book_id}/ratings/distribution", headers=auth_headers
    )
    assert response.status_code == 200
    data = response.json()
    assert "catalog_book_id" in data
    assert "distribution" in data
