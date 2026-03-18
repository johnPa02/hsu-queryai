-- Executive Admissions Summary workspace schema (PostgreSQL)
-- Extracted from production database
-- This is a planner workspace that spans all major tables (simplified DDL)

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
    stage text DEFAULT 'raw_lead',
    smart_score text DEFAULT 'D',
    care_status text,
    assigned_to character varying, -- FK → users(id)
    interested_majors text,
    admission_majors text,
    is_scholarship_applied boolean DEFAULT false,
    is_scholarship_deposited boolean DEFAULT false,
    is_online_applied boolean DEFAULT false,
    is_admitted boolean DEFAULT false,
    is_enrolled boolean DEFAULT false,
    is_tuition_paid boolean DEFAULT false,
    status text DEFAULT 'active',
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

CREATE TABLE lead_stage_history (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    lead_id character varying NOT NULL,
    from_stage text,
    to_stage text NOT NULL,
    changed_by character varying,
    changed_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (lead_id) REFERENCES leads(id),
    FOREIGN KEY (changed_by) REFERENCES users(id)
);

CREATE TABLE zalo_conversations (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    user_id character varying NOT NULL, -- FK → users(id)
    lead_id character varying, -- FK → leads(id)
    last_message_at timestamp,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (lead_id) REFERENCES leads(id)
);

CREATE TABLE zalo_ai_analysis (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    zalo_conversation_id character varying NOT NULL, -- FK → zalo_conversations(id)
    sentiment text,
    topics text[],
    quality_score integer,
    quality_grade text,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (zalo_conversation_id),
    FOREIGN KEY (zalo_conversation_id) REFERENCES zalo_conversations(id)
);

CREATE TABLE voip_call_records (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    extension text NOT NULL,
    dst text NOT NULL,
    duration integer NOT NULL,
    createtime timestamp NOT NULL,
    direction text,
    call_status text,
    analysis jsonb,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE activities (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    user_id character varying,
    action text NOT NULL,
    entity_type text NOT NULL,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE tasks (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    assigned_to character varying NOT NULL,
    title text NOT NULL,
    type text NOT NULL,
    priority text NOT NULL,
    due_date timestamp NOT NULL,
    completed boolean DEFAULT false,
    completed_at timestamp,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);
