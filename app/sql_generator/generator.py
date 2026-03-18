"""SQL Generator — generate PostgreSQL queries from context using GPT-4o."""

import json
import structlog
from openai import AsyncOpenAI
from app.config import get_settings

logger = structlog.get_logger()


class SQLGenerator:
    """Generate SQL from pruned schema + SQL examples + custom instructions."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model

    async def generate(
        self,
        question: str,
        pruned_schema: str,
        sql_examples: list[dict],
        custom_instructions: str,
        glossary: dict,
        metadata_context: str = "",
    ) -> dict:
        """Generate SQL query for a user question."""

        # Format SQL examples
        examples_text = ""
        for ex in sql_examples:
            examples_text += f"\nQ: {ex.get('question', '')}\nSQL: {ex.get('sql', '')}\n"

        # Format glossary
        glossary_text = ""
        for term, info in glossary.items():
            glossary_text += f"- {term}: {info.get('meaning', '')} → {info.get('db_field', '')}\n"

        system_prompt = f"""Bạn là SQL expert cho hệ thống HSU CRM (PostgreSQL).
Viết chính xác SQL query để trả lời câu hỏi người dùng.

## QUY TẮC BẮT BUỘC
1. CHỈ dùng các bảng và cột trong schema được cung cấp
2. Tên cột snake_case, KHÔNG dùng double quotes: is_enrolled, full_name, care_status
3. CHỈ viết SELECT queries (KHÔNG INSERT/UPDATE/DELETE/DROP)
4. Luôn filter status = 'active' trừ khi câu hỏi nói khác
5. Dùng alias tiếng Việt cho output columns khi phù hợp

## SCHEMA
{pruned_schema}

{metadata_context}

## CUSTOM INSTRUCTIONS
{custom_instructions}

## GLOSSARY
{glossary_text}

## SQL EXAMPLES TƯƠNG TỰ
{examples_text}

## OUTPUT FORMAT
Trả về JSON:
{{
  "sql": "SELECT ...",
  "explanation": "Giải thích ngắn bằng tiếng Việt",
  "tables_used": ["table1", "table2"],
  "confidence": 0.9
}}
"""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": question},
            ],
            temperature=0.0,
            max_tokens=4096,
            response_format={"type": "json_object"},
        )

        raw = response.choices[0].message.content

        try:
            result = json.loads(raw)
        except json.JSONDecodeError:
            # Fallback: try to extract SQL from truncated output
            logger.warning("json_parse_failed", raw_length=len(raw), raw_tail=raw[-200:])
            import re
            sql_match = re.search(r'"sql"\s*:\s*"(.*?)"', raw, re.DOTALL)
            result = {
                "sql": sql_match.group(1) if sql_match else "",
                "explanation": "JSON parse fallback — output may be truncated",
                "tables_used": [],
                "confidence": 0.5,
            }

        logger.info(
            "sql_generated",
            question=question[:50],
            tables=result.get("tables_used", []),
            confidence=result.get("confidence", 0),
        )

        return result

