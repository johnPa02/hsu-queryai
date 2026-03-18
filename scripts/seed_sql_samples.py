"""Seed SQL samples into Qdrant vector store."""

import asyncio
from pathlib import Path
import sys

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.rag.embedding import EmbeddingService
from app.rag.vector_store import VectorStore
from app.workspaces.registry import WorkspaceRegistry


async def seed():
    """Load all SQL samples from workspaces and upsert into Qdrant.

    NOTE: Certified metadata is NOT embedded here.
    Metadata is injected deterministically by MetadataGateway
    after Table Agent selects relevant tables.
    """
    print("🚀 Starting SQL samples seeding...")

    registry = WorkspaceRegistry()
    embedding_service = EmbeddingService()
    vector_store = VectorStore()

    total_seeded = 0

    for workspace in registry.list_all():
        if not workspace.sql_samples:
            print(f"⏭️  {workspace.name}: no samples, skipping")
            continue

        collection_name = f"sql_samples_{workspace.id}"
        print(f"\n📂 {workspace.name} → {collection_name}")

        # Prepare texts for embedding (question + explanation)
        texts = []
        payloads = []
        for sample in workspace.sql_samples:
            text = f"{sample['question']}\n{sample.get('explanation', '')}"
            texts.append(text)
            payloads.append({
                "id": sample.get("id", ""),
                "intent": sample.get("intent", ""),
                "question": sample["question"],
                "sql": sample["sql"],
                "explanation": sample.get("explanation", ""),
                "workspace": workspace.id,
            })

        # Embed all samples
        print(f"   Embedding {len(texts)} samples...")
        vectors = await embedding_service.embed_batch(texts)

        # Upsert into Qdrant
        ids = [f"{workspace.id}_{i}" for i in range(len(texts))]
        vector_store.upsert(
            collection_name=collection_name,
            ids=ids,
            vectors=vectors,
            payloads=payloads,
        )

        total_seeded += len(texts)
        print(f"   ✅ {len(texts)} samples seeded")

    print(f"\n🎉 Done! Total: {total_seeded} samples across {len(registry.list_all())} workspaces")
    print("ℹ️  Certified metadata is NOT embedded — it's injected by MetadataGateway at runtime.")


if __name__ == "__main__":
    asyncio.run(seed())
