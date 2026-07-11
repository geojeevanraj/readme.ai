"""create processing tables

Revision ID: 0004_create_processing_tables
Revises: 0003_create_reader_tables
Create Date: 2026-06-29
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0004_create_processing_tables"
down_revision: str | None = "0003_create_reader_tables"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_STATUS = sa.Enum(
    "QUEUED",
    "PROCESSING",
    "COMPLETED",
    "FAILED",
    name="processing_status",
    native_enum=False,
    length=20,
)
_ANCHOR = sa.String(length=128)


def upgrade() -> None:
    _create_processed_books()
    _create_chapters()
    _create_sections()
    _create_paragraphs()
    _create_sentences()


def downgrade() -> None:
    for table in (
        "processed_sentences",
        "processed_paragraphs",
        "processed_sections",
        "processed_chapters",
        "processed_books",
    ):
        op.drop_table(table)


def _create_processed_books() -> None:
    op.create_table(
        "processed_books",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("book_id", sa.Uuid(), nullable=False),
        sa.Column("status", _STATUS, nullable=False),
        sa.Column("processor_name", sa.String(length=64), nullable=True),
        sa.Column("title", sa.String(length=512), nullable=True),
        sa.Column("author", sa.String(length=512), nullable=True),
        sa.Column("language", sa.String(length=32), nullable=True),
        sa.Column("page_count", sa.Integer(), nullable=True),
        sa.Column("word_count", sa.Integer(), nullable=False),
        sa.Column("character_count", sa.BigInteger(), nullable=False),
        sa.Column("estimated_reading_minutes", sa.Integer(), nullable=True),
        sa.Column("error_code", sa.String(length=64), nullable=True),
        sa.Column("error_message", sa.String(length=1024), nullable=True),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.ForeignKeyConstraint(["book_id"], ["books.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("book_id", name="uq_processed_books_book_id"),
    )
    op.create_index("ix_processed_books_book_id", "processed_books", ["book_id"])


def _create_chapters() -> None:
    op.create_table(
        "processed_chapters",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("processed_book_id", sa.Uuid(), nullable=False),
        sa.Column("order_index", sa.Integer(), nullable=False),
        sa.Column("anchor", _ANCHOR, nullable=False),
        sa.Column("title", sa.String(length=512), nullable=True),
        sa.Column("start_offset", sa.BigInteger(), nullable=False),
        sa.Column("end_offset", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(
            ["processed_book_id"], ["processed_books.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_processed_chapters_processed_book_id",
        "processed_chapters",
        ["processed_book_id"],
    )


def _create_sections() -> None:
    op.create_table(
        "processed_sections",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("processed_book_id", sa.Uuid(), nullable=False),
        sa.Column("chapter_id", sa.Uuid(), nullable=False),
        sa.Column("order_index", sa.Integer(), nullable=False),
        sa.Column("anchor", _ANCHOR, nullable=False),
        sa.Column("title", sa.String(length=512), nullable=True),
        sa.Column("start_offset", sa.BigInteger(), nullable=False),
        sa.Column("end_offset", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(
            ["processed_book_id"], ["processed_books.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["chapter_id"], ["processed_chapters.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_processed_sections_processed_book_id",
        "processed_sections",
        ["processed_book_id"],
    )
    op.create_index(
        "ix_processed_sections_chapter_id",
        "processed_sections",
        ["chapter_id"],
    )


def _create_paragraphs() -> None:
    op.create_table(
        "processed_paragraphs",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("processed_book_id", sa.Uuid(), nullable=False),
        sa.Column("section_id", sa.Uuid(), nullable=False),
        sa.Column("order_index", sa.Integer(), nullable=False),
        sa.Column("anchor", _ANCHOR, nullable=False),
        sa.Column("start_offset", sa.BigInteger(), nullable=False),
        sa.Column("end_offset", sa.BigInteger(), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(
            ["processed_book_id"], ["processed_books.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["section_id"], ["processed_sections.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_processed_paragraphs_processed_book_id",
        "processed_paragraphs",
        ["processed_book_id"],
    )
    op.create_index(
        "ix_processed_paragraphs_section_id",
        "processed_paragraphs",
        ["section_id"],
    )


def _create_sentences() -> None:
    op.create_table(
        "processed_sentences",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("processed_book_id", sa.Uuid(), nullable=False),
        sa.Column("paragraph_id", sa.Uuid(), nullable=False),
        sa.Column("order_index", sa.Integer(), nullable=False),
        sa.Column("anchor", _ANCHOR, nullable=False),
        sa.Column("start_offset", sa.BigInteger(), nullable=False),
        sa.Column("end_offset", sa.BigInteger(), nullable=False),
        sa.ForeignKeyConstraint(
            ["processed_book_id"], ["processed_books.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["paragraph_id"], ["processed_paragraphs.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_processed_sentences_processed_book_id",
        "processed_sentences",
        ["processed_book_id"],
    )
    op.create_index(
        "ix_processed_sentences_paragraph_id",
        "processed_sentences",
        ["paragraph_id"],
    )
