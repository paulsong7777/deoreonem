-- V3: Create decompression_item table and updated_at triggers for both tables

CREATE TABLE decompression_item (
    item_id     UUID         NOT NULL DEFAULT gen_random_uuid(),
    session_id  UUID         NOT NULL,
    content     VARCHAR(500) NOT NULL,
    category    VARCHAR(20)  NULL,
    sort_order  INT          NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_decompression_item PRIMARY KEY (item_id),
    CONSTRAINT fk_decompression_item_session
        FOREIGN KEY (session_id)
        REFERENCES decompression_session(session_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_decompression_item_category CHECK (
        category IS NULL
        OR category IN ('NOW', 'TOMORROW', 'THIS_WEEK', 'WAITING', 'MEMO', 'WORRY_ONLY', 'DROP')
    )
);

CREATE INDEX idx_decompression_item_session_id ON decompression_item (session_id);

-- updated_at trigger function (used by both tables)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for decompression_session
CREATE TRIGGER trg_decompression_session_updated_at
    BEFORE UPDATE ON decompression_session
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Trigger for decompression_item
CREATE TRIGGER trg_decompression_item_updated_at
    BEFORE UPDATE ON decompression_item
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
