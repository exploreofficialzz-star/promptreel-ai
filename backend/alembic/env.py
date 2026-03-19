"""
Alembic migration environment — PromptReel AI
Async SQLAlchemy + PostgreSQL via asyncpg.

Usage (run from backend/ directory):
  alembic upgrade head                              # apply all pending
  alembic revision --autogenerate -m "add X"        # create new migration
  alembic downgrade -1                              # roll back one step
  alembic history                                   # list all migrations
"""
import asyncio
import os
import sys
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# ── Path & app imports ────────────────────────────────────────────────────────
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from config import settings          # noqa: E402
from database import Base            # noqa: E402, F401
from models import user, project     # noqa: E402, F401  — register all tables

# ── Alembic config ────────────────────────────────────────────────────────────
config = context.config

# Inject real DB URL; Alembic needs sync driver for offline SQL generation
_sync_url = settings.DATABASE_URL.replace(
    "postgresql+asyncpg://", "postgresql+psycopg2://"
).replace("postgres://", "postgresql+psycopg2://")
config.set_main_option("sqlalchemy.url", _sync_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


# ── Offline migrations (SQL script only, no DB connection) ───────────────────
def run_migrations_offline() -> None:
    context.configure(
        url=config.get_main_option("sqlalchemy.url"),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


# ── Online async migrations ───────────────────────────────────────────────────
def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
