"""User-to-book relationship model (reading status, visibility)."""

import enum
from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base


class BookStatus(enum.StrEnum):
    WANT_TO_READ = "want_to_read"
    READING = "reading"
    READ = "read"
    DNF = "dnf"
    PAUSED = "paused"


class BookVisibility(enum.StrEnum):
    PUBLIC = "public"
    FRIENDS = "friends"
    PRIVATE = "private"


class UserBook(Base):
    __tablename__ = "user_books"

    user_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    catalog_book_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("catalog_books.id", ondelete="CASCADE"), primary_key=True
    )
    status: Mapped[BookStatus] = mapped_column(
        sa.Enum(BookStatus, name="book_status"),
        server_default=BookStatus.WANT_TO_READ.value,
    )
    visibility: Mapped[BookVisibility] = mapped_column(
        sa.Enum(BookVisibility, name="book_visibility"),
        server_default=BookVisibility.PUBLIC.value,
    )
    started_at: Mapped[datetime | None] = mapped_column()
    finished_at: Mapped[datetime | None] = mapped_column()
    progress: Mapped[float | None] = mapped_column()
    local_book_id: Mapped[str | None] = mapped_column(sa.String(36))
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=sa.func.now(), onupdate=sa.func.now()
    )
