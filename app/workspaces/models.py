"""Workspace models and data structures."""

from pydantic import BaseModel


class Workspace(BaseModel):
    """A workspace grouping tables, intents, and context for a business domain."""

    id: str
    name: str
    description: str
    tables: list[str]
    intents: list[str]
    schema_sql: str = ""
    glossary: dict = {}
    sql_samples: list[dict] = []
    custom_instructions: str = ""
    metadata: dict = {}  # Certified metadata: enriched table/column descriptions for RAG
