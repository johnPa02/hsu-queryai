-- Lead Status & Enrollment workspace schema (PostgreSQL)
-- Extracted from production database
-- Tables: users, leads, lead_stage_history

CREATE TABLE users (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    email text NOT NULL,
    password text NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL, -- 'superadmin','manager_l1','manager_l2','marketing_manager','deputy_manager','cvts','ctv'
    region text,
    phone text,
    avatar text,
    status text NOT NULL DEFAULT 'active', -- 'active','inactive','deleted'
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    manager_id character varying, -- FK → users(id)
    channel_connected_id text,
    area text, -- 'DNB & HCM','TNB & HCM'
    lead_target integer,
    conversion_rate_target integer,
    enrollment_target integer,
    email_notifications boolean DEFAULT true,
    push_notifications boolean DEFAULT true,
    task_reminders boolean DEFAULT true,
    responsible_regions text[],
    last_interaction timestamp,
    PRIMARY KEY (id),
    UNIQUE (email),
    FOREIGN KEY (manager_id) REFERENCES users(id)
);

CREATE TABLE leads (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    full_name text NOT NULL,
    gender text, -- 'male','female','other'
    date_of_birth timestamp,
    avatar text,
    nationality text,
    identification_number text,
    place_of_birth text,
    ethnicity text,
    religion text,
    health_status text,
    phone text NOT NULL,
    email text,
    address text,
    social_zalo text,
    social_facebook text,
    social_tiktok text,
    region text,
    city text,
    district text,
    ward text,
    grade_level text, -- '10','11','12','graduated'
    gpa text,
    graduation_year integer,
    previous_education text,
    academic_achievements text[],
    extracurricular_activities text[],
    language_proficiency jsonb,
    computer_skills text,
    special_needs text,
    parent_name text,
    parent_phone text,
    parent_occupation text,
    parent_support text, -- 'high','medium','low'
    parent_education_level text,
    number_of_siblings integer,
    family_income text,
    source text NOT NULL, -- 'zalo','facebook','form','direct','event','referral','HSU'
    stage text DEFAULT 'raw_lead', -- 'raw_lead','interested_in_major','scholarship_applied','scholarship_deposited','account_created','online_admission','hardcopy_submitted','admitted','enrolled','tuition_paid','enrollment_cancelled','not_interested'
    smart_score text DEFAULT 'D', -- 'A','B','C+','C','D','QL'
    assigned_to character varying, -- FK → users(id)
    interested_program text,
    interested_majors text,
    career_goals text,
    scholarship_interest boolean DEFAULT false,
    financial_situation text, -- 'good','average','difficult'
    living_situation text,
    preferred_contact_method text,
    tags text[],
    last_interaction timestamp,
    last_interaction_type text,
    interaction_count integer DEFAULT 0,
    preferred_contact_time text,
    next_follow_up_date timestamp,
    notes text,
    status text DEFAULT 'active', -- 'active','inactive','deleted'
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    school_id character varying, -- FK → schools(id)
    chunk_ids jsonb DEFAULT '[]',
    partner_lead_id text,
    area text, -- 'DNB & HCM','TNB & HCM'
    is_scholarship_applied boolean DEFAULT false,
    is_scholarship_deposited boolean DEFAULT false,
    is_account_created boolean DEFAULT false,
    is_online_applied boolean DEFAULT false,
    is_hardcopy_submitted boolean DEFAULT false,
    is_admitted boolean DEFAULT false,
    is_enrolled boolean DEFAULT false,
    is_tuition_paid boolean DEFAULT false,
    is_enrollment_cancelled boolean DEFAULT false,
    conduct text,
    care_status text, -- see glossary for enum values
    admission_preference text,
    province_code text,
    high_school_code text,
    comment text,
    scholarship_majors text,
    admission_majors text,
    PRIMARY KEY (id),
    UNIQUE (partner_lead_id),
    FOREIGN KEY (assigned_to) REFERENCES users(id),
    FOREIGN KEY (school_id) REFERENCES schools(id)
);

CREATE TABLE lead_stage_history (
    id character varying NOT NULL DEFAULT gen_random_uuid(),
    lead_id character varying NOT NULL, -- FK → leads(id)
    from_stage text,
    to_stage text NOT NULL,
    changed_by character varying, -- FK → users(id)
    changed_at timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (lead_id) REFERENCES leads(id),
    FOREIGN KEY (changed_by) REFERENCES users(id)
);
