"""create books table

Revision ID: 0002_create_books_table
Revises: 0001_create_users_table
Create Date: 2026-06-29
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002_create_books_table"
down_revision: str | None = "0001_create_users_table"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_BOOK_STATUS = sa.Enum(
    "UPLOADING",
    "UPLOADED",
    "PROCESSING",
    "READY",
    "FAILED",
    name="book_status",
    native_enum=False,
    length=20,
)


def upgrade() -> None:
    op.create_table(
        "books",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(length=512), nullable=False),
        sa.Column("original_filename", sa.String(length=512), nullable=False),
        sa.Column("storage_key", sa.String(length=1024), nullable=False),
        sa.Column("mime_type", sa.String(length=255), nullable=False),
        sa.Column("file_size", sa.BigInteger(), nullable=False),
        sa.Column("status", _BOOK_STATUS, nullable=False),
        sa.Column("total_pages", sa.Integer(), nullable=True),
        sa.Column("cover_image_url", sa.String(length=2048), nullable=True),
        sa.Column("ai_summary", sa.Text(), nullable=True),
        sa.Column("uploaded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_books_user_id", "books", ["user_id"], unique=False)
    op.create_index("ix_books_storage_key", "books", ["storage_key"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_books_storage_key", table_name="books")
    op.drop_index("ix_books_user_id", table_name="books")
    op.drop_table("books")
