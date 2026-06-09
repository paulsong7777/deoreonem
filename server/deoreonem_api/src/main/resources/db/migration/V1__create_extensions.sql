-- V1: Enable pgcrypto extension for gen_random_uuid()
-- Required on PostgreSQL < 13. Harmless on PostgreSQL 13+ where gen_random_uuid() is built-in.
CREATE EXTENSION IF NOT EXISTS pgcrypto;
