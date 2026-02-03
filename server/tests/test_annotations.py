"""Tests for annotation endpoints."""

from fastapi.testclient import TestClient


def test_list_annotations(client: TestClient, auth_headers: dict[str, str]):
    """Test listing all annotations."""
    response = client.get("/v1/annotations", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "annotations" in data
    assert "pagination" in data


def test_list_book_annotations(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test listing annotations for a specific book."""
    response = client.get(f"/v1/annotations/books/{book_id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "annotations" in data


def test_create_annotation(client: TestClient, auth_headers: dict[str, str], book_id: str):
    """Test creating an annotation."""
    response = client.post(
        f"/v1/annotations/books/{book_id}",
        headers=auth_headers,
        json={
            "selected_text": "This is a highlighted passage.",
            "note": "My note",
            "highlight_color": "#FFEB3B",
            "start_position": "epubcfi(/6/4[chap01]!/4/2/1:0)",
            "end_position": "epubcfi(/6/4[chap01]!/4/2/1:42)",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["selected_text"] == "This is a highlighted passage."


def test_get_annotation(client: TestClient, auth_headers: dict[str, str], annotation_id: str):
    """Test getting an annotation by ID."""
    response = client.get(f"/v1/annotations/{annotation_id}", headers=auth_headers)
    assert response.status_code == 200


def test_update_annotation(client: TestClient, auth_headers: dict[str, str], annotation_id: str):
    """Test updating an annotation."""
    response = client.patch(
        f"/v1/annotations/{annotation_id}",
        headers=auth_headers,
        json={"note": "Updated note"},
    )
    assert response.status_code == 200


def test_delete_annotation(client: TestClient, auth_headers: dict[str, str], annotation_id: str):
    """Test deleting an annotation."""
    response = client.delete(f"/v1/annotations/{annotation_id}", headers=auth_headers)
    assert response.status_code == 204


def test_export_annotations_json(client: TestClient, auth_headers: dict[str, str]):
    """Test exporting annotations as JSON."""
    response = client.post(
        "/v1/annotations/export",
        headers=auth_headers,
        json={"format": "json"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["format"] == "json"
    assert "content" in data


def test_export_annotations_markdown(client: TestClient, auth_headers: dict[str, str]):
    """Test exporting annotations as Markdown."""
    response = client.post(
        "/v1/annotations/export",
        headers=auth_headers,
        json={"format": "markdown"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["format"] == "markdown"
