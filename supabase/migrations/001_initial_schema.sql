-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Companies (the client companies using SalesTheory)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    domain TEXT UNIQUE,
    industry TEXT,
    size TEXT CHECK (size IN ('1-10', '11-50', '51-200', '201-500', '501-1000', '1000+')),
    description TEXT,
    products JSONB DEFAULT '[]'::jsonb,
    value_propositions JSONB DEFAULT '[]'::jsonb,
    competitors JSONB DEFAULT '[]'::jsonb,
    sales_methodology TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users (salespeople)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT CHECK (role IN ('admin', 'manager', 'sales_rep')),
    avatar_url TEXT,
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Prospects (companies being sold to)
CREATE TABLE prospects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    domain TEXT,
    industry TEXT,
    size TEXT,
    revenue_range TEXT,
    location TEXT,
    description TEXT,
    pain_points JSONB DEFAULT '[]'::jsonb,
    technologies JSONB DEFAULT '[]'::jsonb,
    decision_makers JSONB DEFAULT '[]'::jsonb,
    notes TEXT,
    enrichment_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contacts (people at prospect companies)
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prospect_id UUID REFERENCES prospects(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    title TEXT,
    department TEXT,
    linkedin_url TEXT,
    is_decision_maker BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calls (sales calls/meetings)
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    prospect_id UUID REFERENCES prospects(id) ON DELETE SET NULL,
    contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
    type TEXT CHECK (type IN ('discovery', 'demo', 'negotiation', 'closing', 'follow_up', 'other')),
    status TEXT CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    recording_url TEXT,
    transcript TEXT,
    summary TEXT,
    outcome TEXT CHECK (outcome IN ('won', 'lost', 'follow_up', 'no_decision', NULL)),
    deal_value DECIMAL(12, 2),
    next_steps TEXT,
    sentiment_score DECIMAL(3, 2),
    engagement_score DECIMAL(3, 2),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI Suggestions (real-time coaching suggestions)
CREATE TABLE suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
    timestamp_ms INTEGER NOT NULL,
    type TEXT CHECK (type IN ('response', 'question', 'objection_handling', 'closing', 'rapport', 'clarification')),
    trigger_text TEXT,
    suggestion_text TEXT NOT NULL,
    confidence_score DECIMAL(3, 2),
    was_used BOOLEAN DEFAULT false,
    was_helpful BOOLEAN,
    user_feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Playbooks (sales methodologies and scripts)
CREATE TABLE playbooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT CHECK (type IN ('discovery', 'demo', 'negotiation', 'closing', 'objection_handling')),
    content JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    success_rate DECIMAL(3, 2),
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Learning Outcomes (for ML improvement)
CREATE TABLE learning_outcomes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
    suggestion_id UUID REFERENCES suggestions(id) ON DELETE CASCADE,
    outcome_type TEXT CHECK (outcome_type IN ('used_successful', 'used_unsuccessful', 'not_used', 'modified')),
    original_suggestion TEXT,
    actual_response TEXT,
    prospect_reaction TEXT,
    impact_score DECIMAL(3, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Embeddings (for semantic search and similarity)
CREATE TABLE embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_prospects_company_id ON prospects(company_id);
CREATE INDEX idx_contacts_prospect_id ON contacts(prospect_id);
CREATE INDEX idx_calls_company_id ON calls(company_id);
CREATE INDEX idx_calls_user_id ON calls(user_id);
CREATE INDEX idx_calls_prospect_id ON calls(prospect_id);
CREATE INDEX idx_suggestions_call_id ON suggestions(call_id);
CREATE INDEX idx_playbooks_company_id ON playbooks(company_id);
CREATE INDEX idx_embeddings_company_id ON embeddings(company_id);
CREATE INDEX idx_embeddings_entity ON embeddings(entity_type, entity_id);

-- Create full-text search indexes
CREATE INDEX idx_prospects_search ON prospects USING gin(
    to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, ''))
);

CREATE INDEX idx_calls_transcript ON calls USING gin(
    to_tsvector('english', coalesce(transcript, ''))
);

-- Create functions for updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_prospects_updated_at BEFORE UPDATE ON prospects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_calls_updated_at BEFORE UPDATE ON calls
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_playbooks_updated_at BEFORE UPDATE ON playbooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();