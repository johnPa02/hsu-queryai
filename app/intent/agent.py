"""Intent Agent — LLM-only classification using GPT-4o."""

import json
import structlog
from openai import AsyncOpenAI
from pydantic import BaseModel

from app.config import get_settings
from app.intent.prompts import INTENT_SYSTEM_PROMPT, INTENT_FEW_SHOT_EXAMPLES
from app.intent.labels import INTENT_TO_WORKSPACE

logger = structlog.get_logger()


class IntentResult(BaseModel):
    """Output of the Intent Agent."""
    primary_workspace: str
    secondary_workspaces: list[str] = []
    intent: str
    requires_planner: bool = False
    time_range: str | None = None
    entities_detected: list[str] = []
    confidence: float = 0.0
    reasoning_summary: str = ""


class IntentAgent:
    """Classify user questions into intents and workspaces using GPT-4o."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model

    async def classify(self, question: str) -> IntentResult:
        """Classify a user question into intent + workspace."""

        # Build messages with few-shot examples
        messages = [{"role": "system", "content": INTENT_SYSTEM_PROMPT}]

        for example in INTENT_FEW_SHOT_EXAMPLES:
            messages.append({"role": "user", "content": example["question"]})
            messages.append({"role": "assistant", "content": example["answer"]})

        messages.append({"role": "user", "content": question})

        logger.info("intent_classifying", question=question)

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            temperature=0.0,
            max_tokens=500,
            response_format={"type": "json_object"},
        )

        raw = response.choices[0].message.content
        data = json.loads(raw)

        # Validate workspace exists
        intent = data.get("intent", "")
        workspace = data.get("primary_workspace", "")

        # Fallback if intent not in known mapping
        if intent in INTENT_TO_WORKSPACE:
            workspace = INTENT_TO_WORKSPACE[intent]
            data["primary_workspace"] = workspace

        result = IntentResult(**data)

        logger.info(
            "intent_classified",
            question=question,
            intent=result.intent,
            workspace=result.primary_workspace,
            confidence=result.confidence,
        )

        return result
