"""Pydantic schemas for request/response validation."""

from papyrus.schemas.common import Error, ErrorDetail, Pagination
from papyrus.schemas.auth import (
    AuthTokens,
    GoogleOAuthRequest,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    RegisterResponse,
)
from papyrus.schemas.user import User, UpdateUserRequest, UserPreferences
from papyrus.schemas.book import (
    Book,
    BookCreate,
    BookList,
    BookSummary,
    BookUpdate,
    FileFormat,
    MetadataSearchResult,
    ReadingProgress,
    ReadingStatus,
    UpdateProgressRequest,
)
from papyrus.schemas.shelf import (
    CreateShelfRequest,
    Shelf,
    ShelfList,
    ShelfSummary,
    UpdateShelfRequest,
)
from papyrus.schemas.tag import CreateTagRequest, Tag, TagList, UpdateTagRequest
from papyrus.schemas.series import (
    CreateSeriesRequest,
    Series,
    SeriesList,
    SeriesWithBooks,
    UpdateSeriesRequest,
)
from papyrus.schemas.annotation import (
    Annotation,
    AnnotationList,
    CreateAnnotationRequest,
    UpdateAnnotationRequest,
)
from papyrus.schemas.note import CreateNoteRequest, Note, NoteList, UpdateNoteRequest
from papyrus.schemas.bookmark import (
    Bookmark,
    BookmarkList,
    CreateBookmarkRequest,
    UpdateBookmarkRequest,
)
from papyrus.schemas.progress import (
    CreateReadingSessionRequest,
    ReadingSession,
    ReadingSessionList,
    ReadingStatistics,
)
from papyrus.schemas.goal import (
    CreateGoalRequest,
    Goal,
    GoalList,
    GoalType,
    TimePeriod,
    UpdateGoalRequest,
)
from papyrus.schemas.sync import (
    MetadataServerConfig,
    CreateMetadataServerConfigRequest,
    ServerType,
    SyncChanges,
    SyncConflictResponse,
    SyncPushRequest,
    SyncPushResponse,
    SyncStatus,
)
from papyrus.schemas.storage import (
    ConnectionStatus,
    CreateStorageBackendRequest,
    StorageBackend,
    StorageBackendList,
    StorageBackendType,
    UpdateStorageBackendRequest,
)
from papyrus.schemas.file import FileInfo
from papyrus.schemas.reading_profile import (
    CreateReadingProfileRequest,
    ReadingMode,
    ReadingProfile,
    ReadingProfileList,
    TextAlign,
    ThemeMode,
    UpdateReadingProfileRequest,
)
from papyrus.schemas.saved_filter import (
    CreateSavedFilterRequest,
    FilterType,
    SavedFilter,
    SavedFilterList,
    UpdateSavedFilterRequest,
)

__all__ = [
    # Common
    "Error",
    "ErrorDetail",
    "Pagination",
    # Auth
    "AuthTokens",
    "GoogleOAuthRequest",
    "LoginRequest",
    "RefreshTokenRequest",
    "RegisterRequest",
    "RegisterResponse",
    # User
    "User",
    "UpdateUserRequest",
    "UserPreferences",
    # Book
    "Book",
    "BookCreate",
    "BookList",
    "BookSummary",
    "BookUpdate",
    "FileFormat",
    "MetadataSearchResult",
    "ReadingProgress",
    "ReadingStatus",
    "UpdateProgressRequest",
    # Shelf
    "CreateShelfRequest",
    "Shelf",
    "ShelfList",
    "ShelfSummary",
    "UpdateShelfRequest",
    # Tag
    "CreateTagRequest",
    "Tag",
    "TagList",
    "UpdateTagRequest",
    # Series
    "CreateSeriesRequest",
    "Series",
    "SeriesList",
    "SeriesWithBooks",
    "UpdateSeriesRequest",
    # Annotation
    "Annotation",
    "AnnotationList",
    "CreateAnnotationRequest",
    "UpdateAnnotationRequest",
    # Note
    "CreateNoteRequest",
    "Note",
    "NoteList",
    "UpdateNoteRequest",
    # Bookmark
    "Bookmark",
    "BookmarkList",
    "CreateBookmarkRequest",
    "UpdateBookmarkRequest",
    # Progress
    "CreateReadingSessionRequest",
    "ReadingSession",
    "ReadingSessionList",
    "ReadingStatistics",
    # Goal
    "CreateGoalRequest",
    "Goal",
    "GoalList",
    "GoalType",
    "TimePeriod",
    "UpdateGoalRequest",
    # Sync
    "MetadataServerConfig",
    "CreateMetadataServerConfigRequest",
    "ServerType",
    "SyncChanges",
    "SyncConflictResponse",
    "SyncPushRequest",
    "SyncPushResponse",
    "SyncStatus",
    # Storage
    "ConnectionStatus",
    "CreateStorageBackendRequest",
    "StorageBackend",
    "StorageBackendList",
    "StorageBackendType",
    "UpdateStorageBackendRequest",
    # File
    "FileInfo",
    # Reading Profile
    "CreateReadingProfileRequest",
    "ReadingMode",
    "ReadingProfile",
    "ReadingProfileList",
    "TextAlign",
    "ThemeMode",
    "UpdateReadingProfileRequest",
    # Saved Filter
    "CreateSavedFilterRequest",
    "FilterType",
    "SavedFilter",
    "SavedFilterList",
    "UpdateSavedFilterRequest",
]
