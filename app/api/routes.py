"""API routes for HSU QueryAI."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import structlog
import time

from app.pipeline.orchestrator import Pipeline

logger = structlog.get_logger()
router = APIRouter()


# ---------- Request / Response models ----------

class QueryRequest(BaseModel):
    """Request model for the /query endpoint."""
    question: str


class QueryResponse(BaseModel):
    """Response model for the /query endpoint."""
    question: str
    sql: str
    explanation: str
    workspace: str
    intent: str
    tables_used: list[str]
    confidence: float
    latency_ms: float


# ---------- Routes ----------

@router.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok", "service": "hsu-queryai"}


@router.post("/query", response_model=QueryResponse)
async def query(request: QueryRequest):
    """
    Convert a natural language question to SQL.
    
    Main pipeline endpoint: question → intent → workspace → RAG → SQL
    """
    start = time.perf_counter()

    try:
        pipeline = Pipeline()
        result = await pipeline.run(request.question)

        latency_ms = (time.perf_counter() - start) * 1000

        logger.info(
            "query_completed",
            question=request.question,
            intent=result.get("intent"),
            workspace=result.get("workspace"),
            latency_ms=round(latency_ms, 1),
        )

        return QueryResponse(
            question=request.question,
            sql=result["sql"],
            explanation=result["explanation"],
            workspace=result["workspace"],
            intent=result["intent"],
            tables_used=result.get("tables_used", []),
            confidence=result.get("confidence", 0.0),
            latency_ms=round(latency_ms, 1),
        )

    except Exception as e:
        logger.error("query_failed", question=request.question, error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/workspaces")
async def list_workspaces():
    """List all available workspaces and their intents."""
    from app.workspaces.registry import WorkspaceRegistry

    registry = WorkspaceRegistry()
    workspaces = registry.list_all()
    return {
        "total": len(workspaces),
        "workspaces": [
            {
                "id": ws.id,
                "name": ws.name,
                "tables": ws.tables,
                "intents": ws.intents,
            }
            for ws in workspaces
        ],
    }
