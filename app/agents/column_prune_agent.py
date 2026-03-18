"""Column Prune Agent — prune irrelevant columns from selected tables."""

import structlog
from openai import AsyncOpenAI
from app.config import get_settings

logger = structlog.get_logger()


class ColumnPruneAgent:
    """Prune columns to only those relevant for the question."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = "gpt-4.1-mini"

    async def prune(
        self,
        question: str,
        schema_sql: str,
        selected_tables: list[str],
    ) -> str:
        """Return a pruned DDL containing only relevant columns."""

        prompt = f"""Bạn là Column Prune Agent cho hệ thống HSU CRM (PostgreSQL).
Từ schema DDL và câu hỏi, giữ lại CHỈ các cột cần thiết để viết SQL trả lời câu hỏi.

## Schema DDL (các bảng đã chọn: {', '.join(selected_tables)})
{schema_sql}

## Câu hỏi
{question}

## Yêu cầu
- Giữ lại PRIMARY KEY, FOREIGN KEY, và các cột liên quan đến câu hỏi
- Bỏ các cột không liên quan
- Trả về DDL đã prune (dạng CREATE TABLE ... chỉ với cột cần)
- Tên cột là snake_case, KHÔNG dùng double quotes
- Output chỉ DDL, không có text giải thích"""

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.0,
                max_tokens=2000,
            )

            pruned = response.choices[0].message.content.strip()
        except Exception as e:
            logger.warning("column_prune_error", error=str(e), question=question[:50])
            pruned = schema_sql  # Fallback: use full schema

        logger.info(
            "columns_pruned",
            question=question[:50],
            original_len=len(schema_sql),
            pruned_len=len(pruned),
        )

        return pruned
