"""Activity feed model."""

from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base
from papyrus.models.user_book import BookVisibility


class Activity(Base):
    __tablename__ = "activities"

    id: Mapped[UUID] = mapped_column(
        sa.Uuid, primary_key=True, server_default=sa.text("gen_random_uuid()")
    )
    user_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    activity_type: Mapped[str] = mapped_column(sa.String(50))
    target_type: Mapped[str | None] = mapped_column(sa.String(50))
    target_id: Mapped[UUID | None] = mapped_column(sa.Uuid)
    metadata_: Mapped[dict | None] = mapped_column("metadata", JSONB)
    visibility: Mapped[BookVisibility] = mapped_column(
        sa.Enum(BookVisibility, name="book_visibility", create_type=False),
        server_default=BookVisibility.PUBLIC.value,
    )
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now(), index=True)
