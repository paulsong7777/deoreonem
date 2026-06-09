-- V2: Create decompression_session table
-- Stores one row per decompression session initiated by a user.

CREATE TABLE decompression_session (
    session_id             UUID         NOT NULL DEFAULT gen_random_uuid(),
    status                 VARCHAR(20)  NOT NULL DEFAULT 'IN_PROGRESS',
    first_action_item_id   UUID         NULL,
    completed_at           TIMESTAMPTZ  NULL,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_decompression_session PRIMARY KEY (session_id),
    CONSTRAINT chk_decompression_session_status CHECK (status IN ('IN_PROGRESS', 'COMPLETED'))
);

-- Note: first_action_item_id has no FK constraint intentionally.
-- It is a soft reference to decompression_item.item_id to avoid circular FK dependency.
-- Referential integrity is enforced at the service layer.
