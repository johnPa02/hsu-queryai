"""PostgreSQL database connection pool using asyncpg."""

import asyncpg
import structlog
from app.config import get_settings

logger = structlog.get_logger()

_pool: asyncpg.Pool | None = None


async def get_pool() -> asyncpg.Pool:
    """Get or create the database connection pool."""
    global _pool
    if _pool is None:
        settings = get_settings()
        _pool = await asyncpg.create_pool(
            dsn=settings.database_url,
            min_size=2,
            max_size=10,
            command_timeout=30,
        )
        logger.info("database_pool_created")
    return _pool


async def close_pool() -> None:
    """Close the database connection pool."""
    global _pool
    if _pool is not None:
        await _pool.close()
        _pool = None
        logger.info("database_pool_closed")


async def execute_query(sql: str, timeout: float = 10.0) -> list[dict]:
    """Execute a read-only SQL query and return results as list of dicts."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        # Set read-only mode and timeout for safety
        await conn.execute(f"SET statement_timeout = '{int(timeout * 1000)}'")
        await conn.execute("SET default_transaction_read_only = ON")
        try:
            rows = await conn.fetch(sql)
            return [dict(row) for row in rows]
        finally:
            await conn.execute("SET default_transaction_read_only = OFF")


async def explain_query(sql: str) -> str:
    """Run EXPLAIN on a query to validate it without executing."""
    pool = await get_pool()
    async with pool.acquire() as conn:
        await conn.execute("SET statement_timeout = '5000'")
        rows = await conn.fetch(f"EXPLAIN {sql}")
        return "\n".join(row["QUERY PLAN"] for row in rows)
