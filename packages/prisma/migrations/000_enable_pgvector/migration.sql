-- Enable pgvector extension for vector similarity search.
-- This migration must run before any migration that uses Unsupported("vector(...)") columns.
CREATE EXTENSION IF NOT EXISTS vector;

-- Note: HNSW indexes for vector columns will be added in a later migration
-- once the Task and User tables exist. Example:
--
-- CREATE INDEX task_embedding_hnsw ON "Task" USING hnsw (embedding vector_cosine_ops);
-- CREATE INDEX user_embedding_hnsw ON "User" USING hnsw (embedding vector_cosine_ops);
