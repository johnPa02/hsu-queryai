"""Metadata Gateway — inject certified metadata for selected tables into pipeline context."""

import structlog

from app.workspaces.models import Workspace

logger = structlog.get_logger()


class MetadataGateway:
    """
    After Table Agent selects relevant tables, this gateway extracts
    certified metadata (enriched descriptions, business rules, enum values)
    for those tables and injects them into the pipeline context.

    This is deterministic — not embedding-based.
    When you know which tables are needed, you always want ALL metadata for them.
    """

    def get_context(self, workspace: Workspace, selected_tables: list[str]) -> str:
        """
        Extract metadata for selected tables and format as context string
        for the SQL Generator prompt.

        Args:
            workspace: The active workspace with metadata loaded
            selected_tables: List of table names selected by Table Agent

        Returns:
            Formatted string with table descriptions, column details,
            business rules, and relationships for the selected tables.
        """
        if not workspace.metadata:
            return ""

        tables_meta = workspace.metadata.get("tables", {})
        if not tables_meta:
            return ""

        sections = []
        matched_tables = 0

        for table_name in selected_tables:
            table_info = tables_meta.get(table_name)
            if not table_info:
                continue

            matched_tables += 1
            lines = [
                f"### {table_name}",
                f"{table_info.get('description', '')}",
                "",
            ]

            # Column descriptions
            columns = table_info.get("columns", {})
            if columns:
                lines.append("**Columns:**")
                for col_name, col_desc in columns.items():
                    lines.append(f"- `{col_name}`: {col_desc}")
                lines.append("")

            # Relationships
            relationships = table_info.get("relationships", [])
            if relationships:
                lines.append("**Relationships:**")
                for rel in relationships:
                    lines.append(f"- {rel}")
                lines.append("")

            # Business rules
            rules = table_info.get("business_rules", [])
            if rules:
                lines.append("**Business Rules:**")
                for rule in rules:
                    lines.append(f"- {rule}")
                lines.append("")

            sections.append("\n".join(lines))

        if not sections:
            return ""

        result = "## CERTIFIED METADATA (mô tả chi tiết các bảng đã chọn)\n\n" + "\n---\n\n".join(sections)

        logger.info(
            "metadata_gateway",
            workspace=workspace.id,
            selected_tables=selected_tables,
            matched_tables=matched_tables,
        )

        return result
