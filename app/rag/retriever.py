"""RAG retriever — find relevant SQL samples for a question within a workspace."""

import structlog
from app.rag.embedding import EmbeddingService
from app.rag.vector_store import VectorStore

logger = structlog.get_logger()


class Retriever:
    """Retrieve top-K relevant SQL samples from Qdrant for a given workspace."""

    def __init__(self):
        self.embedding_service = EmbeddingService()
        self.vector_store = VectorStore()

    async def retrieve(
        self,
        question: str,
        workspace_id: str,
        top_k: int = 5,
    ) -> list[dict]:
        """
        Embed the question and search the workspace's Qdrant collection.
        Returns list of SQL samples sorted by relevance.
        """
        collection_name = f"sql_samples_{workspace_id}"

        # Check if collection has data
        if not self.vector_store.collection_exists(collection_name):
            logger.warning("collection_not_found", collection=collection_name)
            return []

        # Embed the question
        query_vector = await self.embedding_service.embed(question)

        # Search Qdrant
        results = self.vector_store.search(
            collection_name=collection_name,
            query_vector=query_vector,
            top_k=top_k,
        )

        logger.info(
            "samples_retrieved",
            workspace=workspace_id,
            question=question[:50],
            results=len(results),
        )

        return results
