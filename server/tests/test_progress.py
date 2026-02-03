"""Tests for reading progress and statistics endpoints."""

from datetime import UTC, datetime

from fastapi.testclient import TestClient


def test_list_reading_sessions(client: TestClient, auth_headers: dict[str, str]):
    """Test listing reading sessions."""
    response = client.get("/v1/progress/sessions", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "sessions" in data
    assert "pagination" in data


def test_create_reading_session(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test creating a reading session."""
    now = datetime.now(UTC)
    response = client.post(
        "/v1/progress/sessions",
        headers=auth_headers,
        json={
            "book_id": book_id,
            "start_time": now.isoformat(),
            "start_position": 0.25,
            "end_position": 0.35,
            "pages_read": 20,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["book_id"] == book_id


def test_get_reading_statistics(client: TestClient, auth_headers: dict[str, str]):
    """Test getting reading statistics."""
    response = client.get("/v1/progress/statistics", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "period" in data
    assert "totals" in data
    assert "daily_breakdown" in data
    assert "books_breakdown" in data


def test_get_reading_statistics_with_date_range(client: TestClient, auth_headers: dict[str, str]):
    """Test getting reading statistics with date range."""
    response = client.get(
        "/v1/progress/statistics",
        headers=auth_headers,
        params={
            "start_date": "2024-01-01",
            "end_date": "2024-12-31",
        },
    )
    assert response.status_code == 200
