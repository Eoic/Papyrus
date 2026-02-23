"""Tests for social endpoints."""

from uuid import uuid4

from fastapi.testclient import TestClient


def test_follow_user(client: TestClient, auth_headers: dict[str, str]):
    target = str(uuid4())
    response = client.post(f"/v1/social/follow/{target}", headers=auth_headers)
    assert response.status_code == 204


def test_unfollow_user(client: TestClient, auth_headers: dict[str, str]):
    target = str(uuid4())
    response = client.delete(f"/v1/social/follow/{target}", headers=auth_headers)
    assert response.status_code == 204


def test_list_followers(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/social/followers", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "users" in data
    assert "pagination" in data


def test_list_following(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/social/following", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "users" in data


def test_list_friends(client: TestClient, auth_headers: dict[str, str]):
    response = client.get("/v1/social/friends", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "users" in data


def test_block_user(client: TestClient, auth_headers: dict[str, str]):
    target = str(uuid4())
    response = client.post(f"/v1/social/block/{target}", headers=auth_headers)
    assert response.status_code == 204


def test_unblock_user(client: TestClient, auth_headers: dict[str, str]):
    target = str(uuid4())
    response = client.delete(f"/v1/social/block/{target}", headers=auth_headers)
    assert response.status_code == 204
