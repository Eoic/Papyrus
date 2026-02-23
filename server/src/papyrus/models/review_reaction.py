"""Review reaction model (like/helpful)."""

import enum
from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base


class ReactionType(enum.StrEnum):
    LIKE = "like"
    HELPFUL = "helpful"


class ReviewReaction(Base):
    __tablename__ = "review_reactions"

    user_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    review_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("reviews.id", ondelete="CASCADE"), primary_key=True
    )
    reaction_type: Mapped[ReactionType] = mapped_column(
        sa.Enum(ReactionType, name="reaction_type"), primary_key=True
    )
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())
