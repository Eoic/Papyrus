"""Follow relationship model."""

from datetime import datetime
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.orm import Mapped, mapped_column

from papyrus.core.database import Base


class Follow(Base):
    __tablename__ = "follows"

    follower_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    followed_id: Mapped[UUID] = mapped_column(
        sa.Uuid, sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    created_at: Mapped[datetime] = mapped_column(server_default=sa.func.now())

    __table_args__ = (sa.CheckConstraint("follower_id != followed_id", name="no_self_follow"),)
