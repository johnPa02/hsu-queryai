"""Workspace registry — loads and manages all workspace definitions."""

import json
from pathlib import Path
from functools import lru_cache
import structlog

from app.workspaces.models import Workspace

logger = structlog.get_logger()

WORKSPACES_DIR = Path(__file__).parent


class WorkspaceRegistry:
    """Registry that loads workspace configs from the filesystem."""

    def __init__(self):
        self._workspaces: dict[str, Workspace] = {}
        self._load_all()

    def _load_all(self):
        """Scan workspace subdirectories and load configs."""
        for ws_dir in sorted(WORKSPACES_DIR.iterdir()):
            config_path = ws_dir / "config.json"
            if ws_dir.is_dir() and config_path.exists():
                self._load_workspace(ws_dir)

    def _load_workspace(self, ws_dir: Path):
        """Load a single workspace from its directory."""
        config = json.loads((ws_dir / "config.json").read_text(encoding="utf-8"))

        # Load optional files
        schema_sql = ""
        schema_path = ws_dir / "schema.sql"
        if schema_path.exists():
            schema_sql = schema_path.read_text(encoding="utf-8")

        glossary = {}
        glossary_path = ws_dir / "glossary.json"
        if glossary_path.exists():
            glossary = json.loads(glossary_path.read_text(encoding="utf-8"))

        sql_samples = []
        samples_path = ws_dir / "sql_samples.json"
        if samples_path.exists():
            sql_samples = json.loads(samples_path.read_text(encoding="utf-8"))

        instructions = ""
        instructions_path = ws_dir / "instructions.md"
        if instructions_path.exists():
            instructions = instructions_path.read_text(encoding="utf-8")

        metadata = {}
        metadata_path = ws_dir / "metadata.json"
        if metadata_path.exists():
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

        ws = Workspace(
            id=config["id"],
            name=config["name"],
            description=config["description"],
            tables=config["tables"],
            intents=config["intents"],
            schema_sql=schema_sql,
            glossary=glossary,
            sql_samples=sql_samples,
            custom_instructions=instructions,
            metadata=metadata,
        )
        self._workspaces[ws.id] = ws
        logger.info("workspace_loaded", workspace=ws.id, tables=len(ws.tables), samples=len(ws.sql_samples))

    def get(self, workspace_id: str) -> Workspace | None:
        """Get a workspace by ID."""
        return self._workspaces.get(workspace_id)

    def get_by_intent(self, intent: str) -> Workspace | None:
        """Find the workspace that contains a given intent."""
        for ws in self._workspaces.values():
            if intent in ws.intents:
                return ws
        return None

    def list_all(self) -> list[Workspace]:
        """Return all loaded workspaces."""
        return list(self._workspaces.values())

    def get_all_intents(self) -> dict[str, str]:
        """Return a mapping of intent → workspace_id."""
        result = {}
        for ws in self._workspaces.values():
            for intent in ws.intents:
                result[intent] = ws.id
        return result


@lru_cache
def get_registry() -> WorkspaceRegistry:
    """Cached workspace registry singleton."""
    return WorkspaceRegistry()
