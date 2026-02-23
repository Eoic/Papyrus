"""Book review model."""

from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base
from papyrus.models.user_book import BookVisibility


class Review(Base):
    __tablename__ = "reviews"

    id: Mapped[UUID] = mapped_column(
        sa.Uuid, primary_key=True, server_default=sa.text("gen_random_uuid()")
    )
    user_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    catalog_book_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("catalog_books.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str | None] = mapped_column(sa.String(255))
    body: Mapped[str] = mapped_column(sa.Text)
    contains_spoilers: Mapped[bool] = mapped_column(server_default=sa.text("false"))
    visibility: Mapped[BookVisibility] = mapped_column(
        sa.Enum(BookVisibility, name="book_visibility", create_type=False),
        server_default=BookVisibility.PUBLIC.value,
    )
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=sa.func.now(), onupdate=sa.func.now()
    )

    __table_args__ = (
        sa.UniqueConstraint("user_id", "catalog_book_id", name="one_review_per_book"),
    )
