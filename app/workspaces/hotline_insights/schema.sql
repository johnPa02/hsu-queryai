-- Hotline Insights workspace schema (PostgreSQL)
-- Extracted from production database
-- Tables: voip_call_records, users, leads

CREATE TABLE users (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    role text NOT NULL,
    phone text,
    status text NOT NULL DEFAULT 'active',
    PRIMARY KEY (id)
);

CREATE TABLE leads (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    phone text NOT NULL,
    status text DEFAULT 'active',
    PRIMARY KEY (id)
);

CREATE TABLE voip_call_records (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    extension text NOT NULL, -- số máy lẻ (soft match với users)
    dst text NOT NULL, -- số điện thoại đích (soft match với leads.phone)
    duration integer NOT NULL, -- giây
    uniqueid text NOT NULL,
    record_url text,
    createtime timestamp NOT NULL,
    analysis jsonb, -- {sentiment, keywords, topics, duration_category, quality_score}
    direction text, -- 'inbound','outbound','internal'
    call_status text, -- 'answered','missed','voicemail'
    imported_at timestamp NOT NULL DEFAULT now(),
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (uniqueid)
);
-- NOTE: voip_call_records ↔ leads qua dst = leads.phone (soft relationship, no FK)
-- NOTE: voip_call_records ↔ users qua extension mapping (soft relationship, no FK)
