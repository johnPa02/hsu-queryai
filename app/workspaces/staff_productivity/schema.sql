-- Staff Productivity workspace schema (PostgreSQL)
-- Extracted from production database
-- Tables: users, channels, activities, tasks

CREATE TABLE users (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    role text NOT NULL, -- 'superadmin','manager_l1','manager_l2','marketing_manager','deputy_manager','cvts','ctv'
    region text,
    area text,
    manager_id character varying, -- FK → users(id)
    phone text,
    channel_connected_id text, -- Zalo userId
    status text NOT NULL DEFAULT 'active',
    last_interaction timestamp,
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (manager_id) REFERENCES users(id)
);

CREATE TABLE channels (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    channel text NOT NULL, -- 'zalo','facebook','email','hotline','webchat'
    sub_type text NOT NULL, -- 'personal','oa','page','smtp','voip','widget'
    name text NOT NULL,
    status text NOT NULL DEFAULT 'active', -- 'active','inactive','error'
    last_sync timestamp,
    message_count integer DEFAULT 0,
    metadata jsonb,
    user_id character varying, -- FK → users(id)
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    channel_connected_id text,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE activities (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    lead_id character varying,
    user_id character varying, -- FK → users(id)
    action text NOT NULL, -- 'created','updated','contacted','stage_changed'
    entity_type text NOT NULL, -- 'lead','conversation','task'
    entity_id character varying,
    details jsonb,
    created_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE tasks (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    lead_id character varying,
    assigned_to character varying NOT NULL, -- FK → users(id)
    title text NOT NULL,
    description text,
    type text NOT NULL, -- 'follow-up','callback','meeting','email'
    priority text NOT NULL, -- 'high','medium','low'
    due_date timestamp NOT NULL,
    completed boolean DEFAULT false,
    completed_at timestamp,
    created_at timestamp NOT NULL DEFAULT now(),
    school_id character varying,
    region text,
    lead_stage text,
    PRIMARY KEY (id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);
