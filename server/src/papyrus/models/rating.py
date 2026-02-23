"""Book rating model (1-10 scale)."""

from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base


class Rating(Base):
    __tablename__ = "ratings"

    user_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    catalog_book_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("catalog_books.id", ondelete="CASCADE"), primary_key=True
    )
    score: Mapped[int] = mapped_column(sa.SmallInteger)
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())
    updated_at: Mapped[datetime] = mapped_column(
        server_default=sa.func.now(), onupdate=sa.func.now()
    )

    __table_args__ = (sa.CheckConstraint("score >= 1 AND score <= 10", name="rating_range"),)
