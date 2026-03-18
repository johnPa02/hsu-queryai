-- Conversation Insights workspace schema (PostgreSQL)
-- Extracted from production database
-- Tables: zalo_conversations, zalo_ai_analysis, zalo_ai_analysis_recap, users, leads

CREATE TABLE users (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    role text NOT NULL,
    region text,
    area text,
    status text NOT NULL DEFAULT 'active',
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE leads (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    phone text NOT NULL,
    assigned_to character varying, -- FK → users(id)
    status text DEFAULT 'active',
    PRIMARY KEY (id)
);

CREATE TABLE zalo_conversations (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    conversation_id text NOT NULL, -- thread_id from Zalo
    user_id character varying NOT NULL, -- FK → users(id), CVTS owner
    lead_id character varying, -- FK → leads(id), nullable
    lead_zalo_id text,
    last_message text,
    last_message_at timestamp,
    messages jsonb DEFAULT '[]', -- array of {content, senderName, sender, timestamp}
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    lead_phone text,
    conversation_title text,
    conversation_thumbnail text,
    PRIMARY KEY (id),
    UNIQUE (conversation_id),
    FOREIGN KEY (lead_id) REFERENCES leads(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE zalo_ai_analysis (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    zalo_conversation_id character varying NOT NULL, -- FK → zalo_conversations(id)
    sentiment text, -- 'positive','neutral','negative'
    summary text,
    topics text[],
    suggested_actions text[],
    analysis_data jsonb,
    quality_score integer, -- 0-100
    quality_grade text, -- 'A','B','C','D','F'
    quality_breakdown jsonb,
    quality_flags text[],
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (zalo_conversation_id),
    FOREIGN KEY (zalo_conversation_id) REFERENCES zalo_conversations(id)
);

CREATE TABLE zalo_ai_analysis_recap (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    total_records integer NOT NULL,
    total_topics integer NOT NULL,
    unique_topics integer NOT NULL,
    analysis jsonb NOT NULL, -- {summary, groups: [{name, description, topics, count, percentage, occurrences}]}
    model text NOT NULL,
    tokens_used integer,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);
