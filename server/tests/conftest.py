"""Pytest configuration and fixtures."""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from papyrus.core.security import create_access_token
from papyrus.main import app


@pytest.fixture
def client() -> TestClient:
    """Create a test client for the application."""
    return TestClient(app)


@pytest.fixture
def user_id() -> str:
    """Generate a test user ID."""
    return str(uuid4())


@pytest.fixture
def auth_headers(user_id: str) -> dict[str, str]:
    """Create authorization headers with a valid JWT token."""
    token = create_access_token({"sub": user_id})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def book_id() -> str:
    """Generate a test book ID."""
    return str(uuid4())


@pytest.fixture
def shelf_id() -> str:
    """Generate a test shelf ID."""
    return str(uuid4())


@pytest.fixture
def tag_id() -> str:
    """Generate a test tag ID."""
    return str(uuid4())


@pytest.fixture
def series_id() -> str:
    """Generate a test series ID."""
    return str(uuid4())


@pytest.fixture
def annotation_id() -> str:
    """Generate a test annotation ID."""
    return str(uuid4())


@pytest.fixture
def note_id() -> str:
    """Generate a test note ID."""
    return str(uuid4())


@pytest.fixture
def bookmark_id() -> str:
    """Generate a test bookmark ID."""
    return str(uuid4())


@pytest.fixture
def goal_id() -> str:
    """Generate a test goal ID."""
    return str(uuid4())
