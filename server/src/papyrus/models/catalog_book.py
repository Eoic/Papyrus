"""Community book catalog model."""

from datetime import date, datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base


class CatalogBook(Base):
    __tablename__ = "catalog_books"

    id: Mapped[UUID] = mapped_column(
        sa.Uuid, primary_key=True, server_default=sa.text("gen_random_uuid()")
    )
    open_library_id: Mapped[str | None] = mapped_column(sa.String(50), unique=True)
    isbn: Mapped[str | None] = mapped_column(sa.String(13), index=True)
    title: Mapped[str] = mapped_column(sa.String(500))
    authors: Mapped[dict | None] = mapped_column(JSONB)
    cover_url: Mapped[str | None] = mapped_column(sa.String(500))
    description: Mapped[str | None] = mapped_column(sa.Text)
    page_count: Mapped[int | None] = mapped_column()
    published_date: Mapped[date | None] = mapped_column()
    genres: Mapped[dict | None] = mapped_column(JSONB)
    added_by_user_id: Mapped[UUID | None] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="SET NULL")
    )
    verified: Mapped[bool] = mapped_column(server_default=sa.text("false"))
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())
