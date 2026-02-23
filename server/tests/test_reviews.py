"""Tests for review endpoints."""

from uuid import uuid4

from fastapi.testclient import TestClient


def test_create_review(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/v1/reviews",
        headers=auth_headers,
        json={
            "catalog_book_id": str(uuid4()),
            "body": "This is a great book that I really enjoyed reading.",
            "contains_spoilers": False,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "review_id" in data
    assert data["contains_spoilers"] is False


def test_get_review(client: TestClient, auth_headers: dict[str, str]):
    review_id = str(uuid4())
    response = client.get(f"/v1/reviews/{review_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "review_id" in data
    assert "body" in data


def test_update_review(client: TestClient, auth_headers: dict[str, str]):
    review_id = str(uuid4())
    response = client.patch(
        f"/v1/reviews/{review_id}",
        headers=auth_headers,
        json={"body": "Updated review text that is long enough."},
    )
    assert response.status_code == 200


def test_delete_review(client: TestClient, auth_headers: dict[str, str]):
    review_id = str(uuid4())
    response = client.delete(f"/v1/reviews/{review_id}", headers=auth_headers)
    assert response.status_code == 204


def test_react_to_review(client: TestClient, auth_headers: dict[str, str]):
    review_id = str(uuid4())
    response = client.post(
        f"/v1/reviews/{review_id}/react",
        headers=auth_headers,
        json={"reaction_type": "like"},
    )
    assert response.status_code == 204


def test_remove_reaction(client: TestClient, auth_headers: dict[str, str]):
    review_id = str(uuid4())
    response = client.delete(f"/v1/reviews/{review_id}/react/like", headers=auth_headers)
    assert response.status_code == 204


def test_review_body_too_short(client: TestClient, auth_headers: dict[str, str]):
    response = client.post(
        "/v1/reviews",
        headers=auth_headers,
        json={"catalog_book_id": str(uuid4()), "body": "Short"},
    )
    assert response.status_code == 422
