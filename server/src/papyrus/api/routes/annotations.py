"""Annotation routes."""

from datetime import UTC, datetime
from enum import StrEnum
from uuid import UUID, uuid4

from fastapi import APIRouter, Response, status
from pydantic import BaseModel

from papyrus.api.deps import CurrentUserId, Pagination
from papyrus.schemas import (
    Annotation,
    AnnotationList,
    CreateAnnotationRequest,
    UpdateAnnotationRequest,
)
from papyrus.schemas import (
    Pagination as PaginationSchema,
)

router = APIRouter()


class ExportFormat(StrEnum):
    """Annotation export formats."""

    JSON = "json"
    MARKDOWN = "markdown"
    CSV = "csv"
    HTML = "html"


class ExportAnnotationsRequest(BaseModel):
    """Request for exporting annotations."""

    book_ids: list[UUID] | None = None
    format: ExportFormat = ExportFormat.JSON
    include_notes: bool = True
    include_bookmarks: bool = False


class ExportAnnotationsResponse(BaseModel):
    """Response containing exported annotations."""

    format: ExportFormat
    content: str
    filename: str


def _example_annotation(
    annotation_id: UUID | None = None, book_id: UUID | None = None
) -> Annotation:
    """Create an example annotation for responses."""
    return Annotation(
        annotation_id=annotation_id or uuid4(),
        book_id=book_id or uuid4(),
        book_title="Example Book",
        selected_text="This is a highlighted text passage.",
        note="My note about this passage.",
        highlight_color="#FFEB3B",
        start_position="epubcfi(/6/4[chap01]!/4/2/1:0)",
        end_position="epubcfi(/6/4[chap01]!/4/2/1:42)",
        chapter_title="Chapter 1",
        chapter_index=1,
        page_number=10,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "",
    response_model=AnnotationList,
    summary="List all annotations",
)
async def list_annotations(
    user_id: CurrentUserId,
    pagination: Pagination,
    book_id: UUID | None = None,
    color: str | None = None,
    search: str | None = None,
) -> AnnotationList:
    """Return paginated list of annotations, optionally filtered by book."""
    return AnnotationList(
        annotations=[_example_annotation()],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=1,
            total_pages=1,
            has_next=False,
            has_prev=False,
        ),
    )


@router.post(
    "/export",
    response_model=ExportAnnotationsResponse,
    summary="Export annotations",
)
async def export_annotations(
    user_id: CurrentUserId,
    request: ExportAnnotationsRequest,
) -> ExportAnnotationsResponse:
    """Export annotations in various formats."""
    if request.format == ExportFormat.MARKDOWN:
        content = "# Annotations\n\n## Example Book\n\n> This is a highlighted text passage.\n\n_Note: My note about this passage._\n"
        filename = "annotations.md"
    elif request.format == ExportFormat.CSV:
        content = 'book_title,selected_text,note,highlight_color,page_number\nExample Book,"This is a highlighted text passage.","My note about this passage.",#FFEB3B,10\n'
        filename = "annotations.csv"
    elif request.format == ExportFormat.HTML:
        content = "<html><body><h1>Annotations</h1><h2>Example Book</h2><blockquote>This is a highlighted text passage.</blockquote><p><em>Note: My note about this passage.</em></p></body></html>"
        filename = "annotations.html"
    else:
        content = '[{"book_title": "Example Book", "selected_text": "This is a highlighted text passage.", "note": "My note about this passage."}]'
        filename = "annotations.json"

    return ExportAnnotationsResponse(
        format=request.format,
        content=content,
        filename=filename,
    )


@router.get(
    "/books/{book_id}",
    response_model=AnnotationList,
    summary="List book annotations",
)
async def list_book_annotations(
    user_id: CurrentUserId,
    book_id: UUID,
    pagination: Pagination,
) -> AnnotationList:
    """Return paginated list of annotations for a specific book."""
    return AnnotationList(
        annotations=[_example_annotation(book_id=book_id)],
        pagination=PaginationSchema(
            page=pagination.page,
            limit=pagination.limit,
            total=1,
            total_pages=1,
            has_next=False,
            has_prev=False,
        ),
    )


@router.post(
    "/books/{book_id}",
    response_model=Annotation,
    status_code=status.HTTP_201_CREATED,
    summary="Create annotation",
)
async def create_annotation(
    user_id: CurrentUserId,
    book_id: UUID,
    request: CreateAnnotationRequest,
) -> Annotation:
    """Create a new annotation for a book."""
    return Annotation(
        annotation_id=uuid4(),
        book_id=book_id,
        selected_text=request.selected_text,
        note=request.note,
        highlight_color=request.highlight_color,
        start_position=request.start_position,
        end_position=request.end_position,
        chapter_title=request.chapter_title,
        chapter_index=request.chapter_index,
        page_number=request.page_number,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@router.get(
    "/{annotation_id}",
    response_model=Annotation,
    summary="Get annotation details",
)
async def get_annotation(
    user_id: CurrentUserId,
    annotation_id: UUID,
) -> Annotation:
    """Return detailed information about an annotation."""
    return _example_annotation(annotation_id)


@router.patch(
    "/{annotation_id}",
    response_model=Annotation,
    summary="Update annotation",
)
async def update_annotation(
    user_id: CurrentUserId,
    annotation_id: UUID,
    request: UpdateAnnotationRequest,
) -> Annotation:
    """Update an annotation's note or color."""
    annotation = _example_annotation(annotation_id)
    if request.note is not None:
        annotation.note = request.note
    if request.highlight_color:
        annotation.highlight_color = request.highlight_color
    return annotation


@router.delete(
    "/{annotation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete annotation",
)
async def delete_annotation(
    user_id: CurrentUserId,
    annotation_id: UUID,
) -> Response:
    """Delete an annotation."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)
