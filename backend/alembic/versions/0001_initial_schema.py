"""initial schema — users and projects tables

Revision ID: 0001_initial_schema
Revises:
Create Date: 2025-03-19 00:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001_initial_schema"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users ─────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id",           sa.Integer(),     nullable=False),
        sa.Column("email",        sa.String(255),   nullable=False),
        sa.Column("name",         sa.String(100),   nullable=False),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("plan",         sa.String(20),    nullable=False, server_default="free"),
        sa.Column("is_verified",  sa.Boolean(),     nullable=False, server_default="false"),
        sa.Column("is_active",    sa.Boolean(),     nullable=False, server_default="true"),
        sa.Column("fcm_token",    sa.String(500),   nullable=True),
        sa.Column("verification_code",         sa.String(10),  nullable=True),
        sa.Column("verification_code_expires", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reset_code",          sa.String(10),  nullable=True),
        sa.Column("reset_code_expires",  sa.DateTime(timezone=True), nullable=True),
        sa.Column("plans_generated_today",  sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_plans_generated", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_generation_date",  sa.Date(),    nullable=True),
        sa.Column("subscription_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("notifications_enabled",   sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), onupdate=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_id",    "users", ["id"])

    # ── projects ──────────────────────────────────────────────────────────────
    op.create_table(
        "projects",
        sa.Column("id",          sa.Integer(),     nullable=False),
        sa.Column("user_id",     sa.Integer(),     nullable=False),
        sa.Column("title",       sa.String(255),   nullable=False),
        sa.Column("idea",        sa.Text(),        nullable=False),
        sa.Column("platform",    sa.String(50),    nullable=False),
        sa.Column("content_type",sa.String(50),    nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
        sa.Column("generator",   sa.String(50),    nullable=True),
        sa.Column("ai_model_used", sa.String(100), nullable=True),
        sa.Column("plan_data",   sa.JSON(),        nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), onupdate=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_projects_id",      "projects", ["id"])
    op.create_index("ix_projects_user_id", "projects", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_projects_user_id", table_name="projects")
    op.drop_index("ix_projects_id",      table_name="projects")
    op.drop_table("projects")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_id",    table_name="users")
    op.drop_table("users")
