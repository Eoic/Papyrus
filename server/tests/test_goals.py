"""Tests for goal endpoints."""

from fastapi.testclient import TestClient


def test_list_goals(client: TestClient, auth_headers: dict[str, str]):
    """Test listing goals."""
    response = client.get("/v1/goals", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "goals" in data


def test_create_goal(client: TestClient, auth_headers: dict[str, str]):
    """Test creating a goal."""
    response = client.post(
        "/v1/goals",
        headers=auth_headers,
        json={
            "title": "Read 12 books this year",
            "goal_type": "books_count",
            "target_value": 12,
            "time_period": "yearly",
            "start_date": "2024-01-01",
            "end_date": "2024-12-31",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Read 12 books this year"


def test_get_goal(client: TestClient, auth_headers: dict[str, str], goal_id: str):
    """Test getting a goal by ID."""
    response = client.get(f"/v1/goals/{goal_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_goal(client: TestClient, auth_headers: dict[str, str], goal_id: str):
    """Test updating a goal."""
    response = client.patch(
        f"/v1/goals/{goal_id}",
        headers=auth_headers,
        json={"target_value": 15},
    )
    assert response.status_code == 200


def test_delete_goal(client: TestClient, auth_headers: dict[str, str], goal_id: str):
    """Test deleting a goal."""
    response = client.delete(f"/v1/goals/{goal_id}", headers=auth_headers)
    assert response.status_code == 204
