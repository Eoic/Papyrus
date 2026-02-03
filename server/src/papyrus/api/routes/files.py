"""File upload and download routes."""

from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, File, Response, UploadFile, status

from papyrus.api.deps import CurrentUserId
from papyrus.schemas import FileInfo

router = APIRouter()


@router.post(
    "/upload",
    response_model=FileInfo,
    status_code=status.HTTP_201_CREATED,
    summary="Upload a book file",
)
async def upload_file(
    user_id: CurrentUserId,
    file: Annotated[UploadFile, File()],
    storage_backend_id: UUID | None = None,
) -> FileInfo:
    """Upload a book file to storage."""
    # In a real implementation, this would:
    # 1. Validate the file type
    # 2. Calculate file hash
    # 3. Store the file in the specified or default storage backend
    # 4. Return the file info

    file_content = await file.read()
    file_size = len(file_content)

    # Determine format from filename
    file_format = None
    if file.filename:
        ext = file.filename.rsplit(".", 1)[-1].lower()
        if ext in ("epub", "pdf", "mobi", "azw3", "txt", "cbr", "cbz"):
            file_format = ext

    return FileInfo(
        file_path=f"books/{uuid4()}/{file.filename}",
        file_format=file_format,
        file_size=file_size,
        file_hash="sha256_placeholder_hash",
        storage_backend_id=storage_backend_id,
        uploaded_at=datetime.now(UTC),
    )


@router.get(
    "/download/{file_path:path}",
    summary="Download a book file",
)
async def download_file(
    user_id: CurrentUserId,
    file_path: str,
) -> Response:
    """Download a book file from storage."""
    # In a real implementation, this would:
    # 1. Verify user has access to the file
    # 2. Retrieve the file from storage
    # 3. Stream the file to the client

    return Response(
        status_code=status.HTTP_302_FOUND,
        headers={"Location": f"https://storage.papyrus.app/{file_path}"},
    )


@router.delete(
    "/{file_path:path}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a file",
)
async def delete_file(
    user_id: CurrentUserId,
    file_path: str,
) -> Response:
    """Delete a file from storage."""
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get(
    "/info/{file_path:path}",
    response_model=FileInfo,
    summary="Get file information",
)
async def get_file_info(
    user_id: CurrentUserId,
    file_path: str,
) -> FileInfo:
    """Get information about a stored file."""
    return FileInfo(
        file_path=file_path,
        file_format="epub",
        file_size=1024 * 1024 * 5,  # 5 MB
        file_hash="sha256_placeholder_hash",
        uploaded_at=datetime.now(UTC),
    )
