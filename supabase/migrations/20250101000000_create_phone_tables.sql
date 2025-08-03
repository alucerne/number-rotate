-- Create phone_candidates table
CREATE TABLE IF NOT EXISTS phone_candidates (
    id SERIAL PRIMARY KEY,
    sha256_id TEXT NOT NULL,
    mobile_number TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    source TEXT,
    priority_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'untested',
    last_attempted_at TIMESTAMP WITH TIME ZONE,
    last_attempted_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_phone_candidates_sha256_id ON phone_candidates(sha256_id);
CREATE INDEX IF NOT EXISTS idx_phone_candidates_status ON phone_candidates(status);
CREATE INDEX IF NOT EXISTS idx_phone_candidates_sha256_mobile ON phone_candidates(sha256_id, mobile_number);

-- Create validated_phones table
CREATE TABLE IF NOT EXISTS validated_phones (
    sha256_id TEXT PRIMARY KEY,
    mobile_number TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    wrong_number BOOLEAN DEFAULT FALSE,
    disconnected BOOLEAN DEFAULT FALSE,
    positive_interaction BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for validated_phones
CREATE INDEX IF NOT EXISTS idx_validated_phones_sha256_id ON validated_phones(sha256_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE phone_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE validated_phones ENABLE ROW LEVEL SECURITY;

-- Create policies for phone_candidates
CREATE POLICY "Enable read access for all users" ON phone_candidates
    FOR SELECT USING (true);

CREATE POLICY "Enable insert access for all users" ON phone_candidates
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON phone_candidates
    FOR UPDATE USING (true);

-- Create policies for validated_phones
CREATE POLICY "Enable read access for all users" ON validated_phones
    FOR SELECT USING (true);

CREATE POLICY "Enable insert access for all users" ON validated_phones
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON validated_phones
    FOR UPDATE USING (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_phone_candidates_updated_at 
    BEFORE UPDATE ON phone_candidates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_validated_phones_updated_at 
    BEFORE UPDATE ON validated_phones 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 