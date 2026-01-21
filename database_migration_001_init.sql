-- Fanmania Database Schema Migration
-- Version: 1.0.0
-- Description: Initial schema for MVP

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- =======================
-- USERS TABLE
-- =======================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(50),
    avatar_url TEXT,
    total_points BIGINT DEFAULT 0,
    global_rank INTEGER,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    -- Constraints
    CONSTRAINT username_length CHECK (char_length(username) >= 3),
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Indexes for users
CREATE INDEX idx_users_username ON users(username) WHERE is_active = true;
CREATE INDEX idx_users_email ON users(email) WHERE is_active = true;
CREATE INDEX idx_users_global_rank ON users(global_rank) WHERE is_active = true;
CREATE INDEX idx_users_total_points ON users(total_points DESC) WHERE is_active = true;

-- =======================
-- CATEGORIES TABLE
-- =======================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    
    -- Visual identity (abstract)
    icon_type VARCHAR(50) NOT NULL DEFAULT 'cube', -- cube, triangle, wave, hexagon, sphere
    color_primary VARCHAR(7) NOT NULL DEFAULT '#00F2FF',
    color_secondary VARCHAR(7) NOT NULL DEFAULT '#8A2BE2',
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sort_order INTEGER DEFAULT 0,
    
    CONSTRAINT valid_hex_primary CHECK (color_primary ~* '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT valid_hex_secondary CHECK (color_secondary ~* '^#[0-9A-Fa-f]{6}$')
);

-- Indexes for categories
CREATE INDEX idx_categories_slug ON categories(slug) WHERE is_active = true;
CREATE INDEX idx_categories_active ON categories(is_active, sort_order);

-- =======================
-- CHALLENGES TABLE
-- =======================
CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    
    -- Challenge content
    title VARCHAR(255) NOT NULL,
    description TEXT,
    question_data JSONB NOT NULL, -- Stores question structure
    correct_answer_hash VARCHAR(255) NOT NULL, -- SHA256 hash of correct answer
    
    -- Difficulty & scoring
    difficulty_tier INTEGER NOT NULL CHECK (difficulty_tier BETWEEN 1 AND 5),
    base_points INTEGER NOT NULL DEFAULT 100,
    time_limit_seconds INTEGER DEFAULT 60,
    
    -- Challenge type
    challenge_type VARCHAR(50) NOT NULL, -- 'multiple_choice', 'timeline', 'prediction', 'true_false'
    
    -- AI generation metadata
    ai_generated BOOLEAN DEFAULT true,
    ai_model_version VARCHAR(50),
    generation_prompt_hash VARCHAR(64), -- For caching
    
    -- Lifecycle
    is_active BOOLEAN DEFAULT true,
    active_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    active_until TIMESTAMP WITH TIME ZONE,
    
    -- Usage statistics
    usage_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    incorrect_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_challenge_type CHECK (
        challenge_type IN ('multiple_choice', 'timeline', 'prediction', 'true_false', 'pattern')
    )
);

-- Indexes for challenges
CREATE INDEX idx_challenges_category ON challenges(category_id) WHERE is_active = true;
CREATE INDEX idx_challenges_difficulty ON challenges(difficulty_tier) WHERE is_active = true;
CREATE INDEX idx_challenges_active_time ON challenges(active_from, active_until) WHERE is_active = true;
CREATE INDEX idx_challenges_type ON challenges(challenge_type) WHERE is_active = true;
CREATE INDEX idx_challenges_prompt_hash ON challenges(generation_prompt_hash); -- For AI caching

-- GIN index for JSONB search
CREATE INDEX idx_challenges_question_data ON challenges USING GIN (question_data);

-- =======================
-- USER CHALLENGE ATTEMPTS TABLE
-- =======================
CREATE TABLE user_challenge_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    
    -- Attempt data
    is_correct BOOLEAN NOT NULL,
    points_earned INTEGER NOT NULL,
    time_taken_seconds INTEGER,
    
    -- Answer metadata (not storing actual answer for security)
    answer_hash VARCHAR(255),
    
    -- Timestamps
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent multiple attempts (per challenge design)
    CONSTRAINT unique_user_challenge UNIQUE(user_id, challenge_id)
);

-- Indexes for attempts
CREATE INDEX idx_attempts_user ON user_challenge_attempts(user_id, attempted_at DESC);
CREATE INDEX idx_attempts_challenge ON user_challenge_attempts(challenge_id);
CREATE INDEX idx_attempts_user_correct ON user_challenge_attempts(user_id, is_correct);

-- =======================
-- CATEGORY RANKINGS TABLE
-- =======================
CREATE TABLE category_rankings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    
    -- Ranking data
    points BIGINT DEFAULT 0,
    rank INTEGER,
    mastery_percentage DECIMAL(5,2) DEFAULT 0.00, -- 0.00 to 100.00
    
    -- Engagement metrics
    challenges_completed INTEGER DEFAULT 0,
    challenges_correct INTEGER DEFAULT 0,
    streak_days INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    
    -- Timestamps
    last_activity TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_category UNIQUE(user_id, category_id),
    CONSTRAINT valid_mastery CHECK (mastery_percentage >= 0 AND mastery_percentage <= 100)
);

-- Indexes for category rankings
CREATE INDEX idx_category_rankings_category ON category_rankings(category_id, rank);
CREATE INDEX idx_category_rankings_user ON category_rankings(user_id);
CREATE INDEX idx_category_rankings_points ON category_rankings(category_id, points DESC);

-- =======================
-- LEADERBOARD SNAPSHOTS TABLE
-- =======================
CREATE TABLE leaderboard_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL, -- NULL for global
    
    -- Snapshot data
    points BIGINT NOT NULL,
    rank INTEGER NOT NULL,
    snapshot_type VARCHAR(20) NOT NULL, -- 'daily', 'weekly', 'monthly', 'all_time'
    snapshot_date DATE NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_snapshot_type CHECK (
        snapshot_type IN ('daily', 'weekly', 'monthly', 'all_time')
    )
);

-- Composite index for efficient leaderboard queries
CREATE INDEX idx_leaderboard_lookup ON leaderboard_snapshots(
    category_id, 
    snapshot_type, 
    snapshot_date DESC, 
    rank
);
CREATE INDEX idx_leaderboard_user ON leaderboard_snapshots(user_id, snapshot_date DESC);

-- =======================
-- NOTIFICATIONS TABLE
-- =======================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Notification content (LEGALLY SAFE - quest-based only)
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    action_url TEXT,
    
    -- Metadata
    is_read BOOLEAN DEFAULT false,
    is_pushed BOOLEAN DEFAULT false, -- Sent via FCM
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_notification_type CHECK (
        notification_type IN ('rank_threat', 'challenge_unlock', 'streak_risk', 'difficulty_unlock', 'achievement')
    )
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(notification_type, created_at DESC);
CREATE INDEX idx_notifications_expires ON notifications(expires_at) WHERE expires_at IS NOT NULL;

-- =======================
-- USER DEVICE TOKENS TABLE (for FCM)
-- =======================
CREATE TABLE user_device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Device information
    fcm_token TEXT NOT NULL,
    device_type VARCHAR(20) NOT NULL, -- 'ios', 'android'
    device_id VARCHAR(255),
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_device_type CHECK (device_type IN ('ios', 'android')),
    CONSTRAINT unique_fcm_token UNIQUE(fcm_token)
);

-- Indexes for device tokens
CREATE INDEX idx_device_tokens_user ON user_device_tokens(user_id) WHERE is_active = true;
CREATE INDEX idx_device_tokens_active ON user_device_tokens(is_active, last_used);

-- =======================
-- STREAKS TABLE
-- =======================
CREATE TABLE user_streaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE, -- NULL for global
    
    -- Streak data
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    
    -- Timestamps
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_user_category_streak UNIQUE(user_id, category_id)
);

-- Indexes for streaks
CREATE INDEX idx_streaks_user ON user_streaks(user_id);
CREATE INDEX idx_streaks_last_activity ON user_streaks(last_activity_date);

-- =======================
-- FUNCTIONS & TRIGGERS
-- =======================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_challenges_updated_at BEFORE UPDATE ON challenges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_category_rankings_updated_at BEFORE UPDATE ON category_rankings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_streaks_updated_at BEFORE UPDATE ON user_streaks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =======================
-- VIEWS (for convenience)
-- =======================

-- Active users with stats
CREATE VIEW active_users_stats AS
SELECT 
    u.id,
    u.username,
    u.display_name,
    u.total_points,
    u.global_rank,
    COUNT(DISTINCT uca.challenge_id) as challenges_completed,
    COUNT(DISTINCT cr.category_id) as categories_active,
    MAX(us.current_streak) as best_current_streak,
    u.last_active
FROM users u
LEFT JOIN user_challenge_attempts uca ON u.id = uca.user_id
LEFT JOIN category_rankings cr ON u.id = cr.user_id
LEFT JOIN user_streaks us ON u.id = us.user_id
WHERE u.is_active = true
GROUP BY u.id;

-- Category statistics
CREATE VIEW category_stats AS
SELECT 
    c.id,
    c.name,
    c.slug,
    COUNT(DISTINCT ch.id) as total_challenges,
    COUNT(DISTINCT cr.user_id) as active_users,
    COALESCE(AVG(ch.correct_count::FLOAT / NULLIF(ch.usage_count, 0) * 100), 0) as avg_success_rate
FROM categories c
LEFT JOIN challenges ch ON c.id = ch.category_id AND ch.is_active = true
LEFT JOIN category_rankings cr ON c.id = cr.category_id
WHERE c.is_active = true
GROUP BY c.id;

-- =======================
-- SEED DATA (Basic Categories)
-- =======================

INSERT INTO categories (name, slug, description, icon_type, color_primary, color_secondary, sort_order) VALUES
('Afrobeats (2010s)', 'afrobeats-2010s', 'Test your knowledge of the Afrobeats revolution from 2010-2020', 'wave', '#00F2FF', '#8A2BE2', 1),
('West African Hip-Hop', 'west-african-hiphop', 'The evolution of hip-hop culture across West Africa', 'cube', '#FF00FF', '#00F2FF', 2),
('Modern African Cinema', 'modern-african-cinema', 'Contemporary African filmmaking and storytelling', 'triangle', '#8A2BE2', '#FF00FF', 3),
('Global Street Culture', 'global-street-culture', 'Street culture movements around the world', 'hexagon', '#00F2FF', '#FF00FF', 4),
('Contemporary Fusion', 'contemporary-fusion', 'Genre-blending and cultural fusion in modern music', 'sphere', '#FF00FF', '#8A2BE2', 5);

-- =======================
-- ANALYTICS & PERFORMANCE
-- =======================

-- Explain analyze helper for performance testing
COMMENT ON TABLE users IS 'Core user accounts with authentication and global stats';
COMMENT ON TABLE challenges IS 'AI-generated skill challenges with legal compliance safeguards';
COMMENT ON TABLE category_rankings IS 'Category-specific user rankings and mastery tracking';
COMMENT ON TABLE leaderboard_snapshots IS 'Time-scoped leaderboard snapshots for performance';

-- Grant permissions (adjust based on your DB user)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO fanmania_app;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO fanmania_app;
