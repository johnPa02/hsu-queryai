"""Table Agent — select relevant tables from workspace for a question."""

import json
import re
import structlog
from openai import AsyncOpenAI
from app.config import get_settings

logger = structlog.get_logger()


class TableAgent:
    """Select the subset of tables needed to answer a question."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = "gpt-4.1-mini"  # Lighter model for table selection

    async def select_tables(
        self,
        question: str,
        available_tables: list[str],
        schema_sql: str,
    ) -> list[str]:
        """Given a question and available tables, return only the ones needed."""

        prompt = f"""Bạn là Table Selection Agent cho hệ thống HSU CRM (PostgreSQL).
Từ danh sách bảng có sẵn và schema DDL, chọn chỉ những bảng CẦN THIẾT để trả lời câu hỏi.
Tên cột trong DB đều là snake_case.

## Bảng có sẵn
{json.dumps(available_tables)}

## Schema DDL
{schema_sql}

## Câu hỏi
{question}

Trả về JSON object: {{"tables": ["table1", "table2"]}}
Chỉ trả JSON, không có text khác."""

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.0,
                max_tokens=200,
                response_format={"type": "json_object"},
            )

            raw = response.choices[0].message.content
            if not raw or not raw.strip():
                logger.warning("table_agent_empty_response", question=question[:50])
                return available_tables

            data = json.loads(raw)
            if isinstance(data, dict):
                tables = data.get("tables", data.get("result", available_tables))
            else:
                tables = data

        except (json.JSONDecodeError, Exception) as e:
            logger.warning("table_agent_parse_error", error=str(e), question=question[:50])
            # Fallback: try regex extraction
            raw = raw if raw else ""
            found = re.findall(r'"(\w+)"', raw)
            tables = [t for t in found if t in available_tables] or available_tables

        logger.info("tables_selected", question=question[:50], tables=tables)
        return tables
