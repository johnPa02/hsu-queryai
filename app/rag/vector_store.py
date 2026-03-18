"""Qdrant vector store operations."""

import structlog
from qdrant_client import QdrantClient, models
from app.config import get_settings

logger = structlog.get_logger()

EMBEDDING_DIM = 1536  # text-embedding-3-small


class VectorStore:
    """Manage Qdrant collections for SQL samples per workspace."""

    def __init__(self):
        settings = get_settings()
        self.client = QdrantClient(
            host=settings.qdrant_host,
            port=settings.qdrant_port,
        )

    def ensure_collection(self, collection_name: str):
        """Create collection if it doesn't exist."""
        collections = [c.name for c in self.client.get_collections().collections]
        if collection_name not in collections:
            self.client.create_collection(
                collection_name=collection_name,
                vectors_config=models.VectorParams(
                    size=EMBEDDING_DIM,
                    distance=models.Distance.COSINE,
                ),
            )
            logger.info("collection_created", name=collection_name)

    def upsert(
        self,
        collection_name: str,
        ids: list[str],
        vectors: list[list[float]],
        payloads: list[dict],
    ):
        """Upsert points into a collection."""
        self.ensure_collection(collection_name)
        points = [
            models.PointStruct(
                id=idx,
                vector=vec,
                payload=payload,
            )
            for idx, (vec, payload) in enumerate(zip(vectors, payloads))
        ]
        self.client.upsert(collection_name=collection_name, points=points)
        logger.info("points_upserted", collection=collection_name, count=len(points))

    def search(
        self,
        collection_name: str,
        query_vector: list[float],
        top_k: int = 5,
    ) -> list[dict]:
        """Search for similar SQL samples."""
        results = self.client.query_points(
            collection_name=collection_name,
            query=query_vector,
            limit=top_k,
        )
        return [
            {**hit.payload, "score": hit.score}
            for hit in results.points
        ]

    def collection_exists(self, collection_name: str) -> bool:
        """Check if a collection exists."""
        collections = [c.name for c in self.client.get_collections().collections]
        return collection_name in collections

    def count(self, collection_name: str) -> int:
        """Count points in a collection."""
        if not self.collection_exists(collection_name):
            return 0
        info = self.client.get_collection(collection_name)
        return info.points_count
