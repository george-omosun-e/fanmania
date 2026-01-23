package postgres

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// DB wraps the pgxpool connection
type DB struct {
	Pool *pgxpool.Pool
}

// NewDB creates a new database connection pool
func NewDB(databaseURL string) (*DB, error) {
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database URL: %w", err)
	}

	// Connection pool settings
	config.MaxConns = 25
	config.MinConns = 5
	config.MaxConnLifetime = 5 * time.Minute
	config.MaxConnIdleTime = 1 * time.Minute
	config.HealthCheckPeriod = 1 * time.Minute

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Test connection
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &DB{Pool: pool}, nil
}

// Close closes the database connection pool
func (db *DB) Close() {
	db.Pool.Close()
}

// Health checks database health
func (db *DB) Health(ctx context.Context) error {
	return db.Pool.Ping(ctx)
}

// RunMigrations runs database migrations
func (db *DB) RunMigrations(ctx context.Context) error {
	log.Println("Running database migrations...")

	migrations := []string{
		// Enable extensions
		`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`,
		`CREATE EXTENSION IF NOT EXISTS "pg_trgm"`,

		// Users table
		`CREATE TABLE IF NOT EXISTS users (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			username VARCHAR(30) UNIQUE NOT NULL,
			email VARCHAR(255) UNIQUE NOT NULL,
			password_hash VARCHAR(255) NOT NULL,
			display_name VARCHAR(50),
			avatar_url TEXT,
			total_points BIGINT DEFAULT 0,
			global_rank INTEGER,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			last_active TIMESTAMP WITH TIME ZONE,
			is_active BOOLEAN DEFAULT true,
			is_verified BOOLEAN DEFAULT false
		)`,

		// Categories table
		`CREATE TABLE IF NOT EXISTS categories (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			name VARCHAR(100) NOT NULL,
			slug VARCHAR(100) UNIQUE NOT NULL,
			description TEXT,
			icon_type VARCHAR(50) NOT NULL DEFAULT 'cube',
			color_primary VARCHAR(7) NOT NULL DEFAULT '#00F2FF',
			color_secondary VARCHAR(7) NOT NULL DEFAULT '#8A2BE2',
			is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			sort_order INTEGER DEFAULT 0
		)`,

		// Challenges table
		`CREATE TABLE IF NOT EXISTS challenges (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
			title VARCHAR(255) NOT NULL,
			description TEXT,
			question_data JSONB NOT NULL,
			correct_answer_hash VARCHAR(255) NOT NULL,
			difficulty_tier INTEGER NOT NULL CHECK (difficulty_tier BETWEEN 1 AND 5),
			base_points INTEGER NOT NULL DEFAULT 100,
			time_limit_seconds INTEGER DEFAULT 60,
			challenge_type VARCHAR(50) NOT NULL,
			ai_generated BOOLEAN DEFAULT true,
			ai_model_version VARCHAR(50),
			generation_prompt_hash VARCHAR(64),
			is_active BOOLEAN DEFAULT true,
			active_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			active_until TIMESTAMP WITH TIME ZONE,
			usage_count INTEGER DEFAULT 0,
			correct_count INTEGER DEFAULT 0,
			incorrect_count INTEGER DEFAULT 0,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
		)`,

		// User challenge attempts table
		`CREATE TABLE IF NOT EXISTS user_challenge_attempts (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
			is_correct BOOLEAN NOT NULL,
			points_earned INTEGER NOT NULL,
			time_taken_seconds INTEGER,
			answer_hash VARCHAR(255),
			attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT unique_user_challenge UNIQUE(user_id, challenge_id)
		)`,

		// Category rankings table
		`CREATE TABLE IF NOT EXISTS category_rankings (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
			points BIGINT DEFAULT 0,
			rank INTEGER,
			mastery_percentage DECIMAL(5,2) DEFAULT 0.00,
			challenges_completed INTEGER DEFAULT 0,
			challenges_correct INTEGER DEFAULT 0,
			streak_days INTEGER DEFAULT 0,
			longest_streak INTEGER DEFAULT 0,
			last_activity TIMESTAMP WITH TIME ZONE,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT unique_user_category UNIQUE(user_id, category_id)
		)`,

		// Notifications table
		`CREATE TABLE IF NOT EXISTS notifications (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			title VARCHAR(100) NOT NULL,
			body TEXT NOT NULL,
			notification_type VARCHAR(50) NOT NULL,
			action_url TEXT,
			is_read BOOLEAN DEFAULT false,
			is_pushed BOOLEAN DEFAULT false,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			expires_at TIMESTAMP WITH TIME ZONE,
			read_at TIMESTAMP WITH TIME ZONE
		)`,

		// User device tokens table
		`CREATE TABLE IF NOT EXISTS user_device_tokens (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			fcm_token TEXT NOT NULL,
			device_type VARCHAR(20) NOT NULL,
			device_id VARCHAR(255),
			is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			last_used TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT unique_fcm_token UNIQUE(fcm_token)
		)`,

		// User streaks table
		`CREATE TABLE IF NOT EXISTS user_streaks (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
			category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
			current_streak INTEGER DEFAULT 0,
			longest_streak INTEGER DEFAULT 0,
			last_activity_date DATE,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			CONSTRAINT unique_user_category_streak UNIQUE(user_id, category_id)
		)`,

		// Seed categories
		`INSERT INTO categories (name, slug, description, icon_type, color_primary, color_secondary, sort_order)
		VALUES
			('Afrobeats (2010s)', 'afrobeats-2010s', 'Test your knowledge of the Afrobeats revolution from 2010-2020', 'wave', '#00F2FF', '#8A2BE2', 1),
			('West African Hip-Hop', 'west-african-hiphop', 'The evolution of hip-hop culture across West Africa', 'cube', '#FF00FF', '#00F2FF', 2),
			('Modern African Cinema', 'modern-african-cinema', 'Contemporary African filmmaking and storytelling', 'triangle', '#8A2BE2', '#FF00FF', 3),
			('Global Street Culture', 'global-street-culture', 'Street culture movements around the world', 'hexagon', '#00F2FF', '#FF00FF', 4),
			('Contemporary Fusion', 'contemporary-fusion', 'Genre-blending and cultural fusion in modern music', 'sphere', '#FF00FF', '#8A2BE2', 5)
		ON CONFLICT (slug) DO NOTHING`,
	}

	for i, migration := range migrations {
		_, err := db.Pool.Exec(ctx, migration)
		if err != nil {
			log.Printf("Migration %d failed: %v", i+1, err)
			// Continue with other migrations, some might fail due to already existing objects
			continue
		}
		log.Printf("Migration %d completed", i+1)
	}

	log.Println("Database migrations completed")
	return nil
}
