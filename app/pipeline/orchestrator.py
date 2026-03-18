"""Pipeline orchestrator — end-to-end Text-to-SQL pipeline."""

import structlog

from app.intent.agent import IntentAgent
from app.workspaces.registry import get_registry
from app.rag.retriever import Retriever
from app.agents.table_agent import TableAgent
from app.agents.metadata_gateway import MetadataGateway
from app.agents.column_prune_agent import ColumnPruneAgent
from app.sql_generator.generator import SQLGenerator
from app.validator.sql_validator import SQLValidator

logger = structlog.get_logger()


class Pipeline:
    """
    End-to-end Text-to-SQL pipeline:
    Question → Intent → Workspace → RAG → Table Agent
    → Metadata Gateway → Column Prune → SQL Gen → Validate
    """

    def __init__(self):
        self.intent_agent = IntentAgent()
        self.retriever = Retriever()
        self.table_agent = TableAgent()
        self.metadata_gateway = MetadataGateway()
        self.column_prune_agent = ColumnPruneAgent()
        self.sql_generator = SQLGenerator()
        self.sql_validator = SQLValidator()

    async def run(self, question: str) -> dict:
        """Run the full pipeline for a user question."""
        logger.info("pipeline_start", question=question)

        # Step 1: Intent classification
        intent_result = await self.intent_agent.classify(question)

        # Step 2: Get workspace
        registry = get_registry()
        workspace = registry.get(intent_result.primary_workspace)
        if not workspace:
            raise ValueError(f"Workspace not found: {intent_result.primary_workspace}")

        # Step 3: RAG — retrieve similar SQL samples
        sql_samples = await self.retriever.retrieve(
            question=question,
            workspace_id=workspace.id,
            top_k=5,
        )

        # Fallback to workspace's own samples if Qdrant is empty
        if not sql_samples:
            sql_samples = workspace.sql_samples[:5]

        # Step 4: Table Agent — select relevant tables
        selected_tables = await self.table_agent.select_tables(
            question=question,
            available_tables=workspace.tables,
            schema_sql=workspace.schema_sql,
        )

        # Step 5: Metadata Gateway — inject certified metadata for selected tables
        metadata_context = self.metadata_gateway.get_context(
            workspace=workspace,
            selected_tables=selected_tables,
        )

        # Step 6: Column Prune Agent — prune schema
        pruned_schema = await self.column_prune_agent.prune(
            question=question,
            schema_sql=workspace.schema_sql,
            selected_tables=selected_tables,
        )

        # Step 7: SQL Generation (with metadata context)
        gen_result = await self.sql_generator.generate(
            question=question,
            pruned_schema=pruned_schema,
            sql_examples=sql_samples,
            custom_instructions=workspace.custom_instructions,
            glossary=workspace.glossary,
            metadata_context=metadata_context,
        )

        # Step 8: Validate SQL
        validation = self.sql_validator.validate(gen_result.get("sql", ""))

        if not validation["valid"]:
            logger.warning(
                "pipeline_sql_invalid",
                errors=validation["errors"],
                sql=gen_result.get("sql", "")[:200],
            )

        result = {
            "sql": validation["sanitized_sql"],
            "explanation": gen_result.get("explanation", ""),
            "workspace": workspace.id,
            "intent": intent_result.intent,
            "tables_used": gen_result.get("tables_used", selected_tables),
            "confidence": gen_result.get("confidence", 0.0),
            "valid": validation["valid"],
            "validation_errors": validation["errors"],
            "intent_details": intent_result.model_dump(),
        }

        logger.info(
            "pipeline_complete",
            question=question[:50],
            workspace=workspace.id,
            intent=intent_result.intent,
            valid=validation["valid"],
        )

        return result
