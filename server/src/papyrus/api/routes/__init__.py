"""API routes package."""

from fastapi import APIRouter

from papyrus.api.routes import (
    annotations,
    auth,
    bookmarks,
    books,
    files,
    goals,
    notes,
    profiles,
    progress,
    reading_profiles,
    saved_filters,
    series,
    shelves,
    social,
    storage,
    sync,
    tags,
    users,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(books.router, prefix="/books", tags=["Books"])
api_router.include_router(shelves.router, prefix="/shelves", tags=["Shelves"])
api_router.include_router(tags.router, prefix="/tags", tags=["Tags"])
api_router.include_router(series.router, prefix="/series", tags=["Series"])
api_router.include_router(annotations.router, prefix="/annotations", tags=["Annotations"])
api_router.include_router(notes.router, prefix="/notes", tags=["Notes"])
api_router.include_router(bookmarks.router, prefix="/bookmarks", tags=["Bookmarks"])
api_router.include_router(progress.router, prefix="/progress", tags=["Progress"])
api_router.include_router(goals.router, prefix="/goals", tags=["Goals"])
api_router.include_router(sync.router, prefix="/sync", tags=["Sync"])
api_router.include_router(storage.router, prefix="/storage", tags=["Storage"])
api_router.include_router(files.router, prefix="/files", tags=["Files"])
api_router.include_router(
    reading_profiles.router, prefix="/reading-profiles", tags=["Reading Profiles"]
)
api_router.include_router(saved_filters.router, prefix="/saved-filters", tags=["Saved Filters"])
api_router.include_router(profiles.router, prefix="/profiles", tags=["Profiles"])
api_router.include_router(social.router, prefix="/social", tags=["Social"])
