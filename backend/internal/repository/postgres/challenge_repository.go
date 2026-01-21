package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// ChallengeRepository handles challenge database operations
type ChallengeRepository struct {
	db *DB
}

// NewChallengeRepository creates a new ChallengeRepository
func NewChallengeRepository(db *DB) *ChallengeRepository {
	return &ChallengeRepository{db: db}
}

// Create creates a new challenge
func (r *ChallengeRepository) Create(ctx context.Context, challenge *models.Challenge) error {
	query := `
		INSERT INTO challenges (
			category_id, title, description, question_data, correct_answer_hash,
			difficulty_tier, base_points, time_limit_seconds, challenge_type,
			ai_generated, ai_model_version, generation_prompt_hash, active_until
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		RETURNING id, is_active, created_at, usage_count
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		challenge.CategoryID,
		challenge.Title,
		challenge.Description,
		challenge.QuestionData,
		challenge.CorrectAnswerHash,
		challenge.DifficultyTier,
		challenge.BasePoints,
		challenge.TimeLimitSeconds,
		challenge.ChallengeType,
		challenge.AIGenerated,
		"", // AI model version (can be populated later)
		"", // Generation prompt hash (can be populated later)
		challenge.ActiveUntil,
	).Scan(
		&challenge.ID,
		&challenge.IsActive,
		&challenge.CreatedAt,
		&challenge.UsageCount,
	)

	if err != nil {
		return fmt.Errorf("failed to create challenge: %w", err)
	}

	return nil
}

// GetByID retrieves a challenge by ID
func (r *ChallengeRepository) GetByID(ctx context.Context, id uuid.UUID) (*models.Challenge, error) {
	query := `
		SELECT id, category_id, title, description, question_data, correct_answer_hash,
		       difficulty_tier, base_points, time_limit_seconds, challenge_type,
		       ai_generated, is_active, active_until, created_at, usage_count
		FROM challenges
		WHERE id = $1 AND is_active = true
	`

	var challenge models.Challenge
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&challenge.ID,
		&challenge.CategoryID,
		&challenge.Title,
		&challenge.Description,
		&challenge.QuestionData,
		&challenge.CorrectAnswerHash,
		&challenge.DifficultyTier,
		&challenge.BasePoints,
		&challenge.TimeLimitSeconds,
		&challenge.ChallengeType,
		&challenge.AIGenerated,
		&challenge.IsActive,
		&challenge.ActiveUntil,
		&challenge.CreatedAt,
		&challenge.UsageCount,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrChallengeNotFound
		}
		return nil, fmt.Errorf("failed to get challenge: %w", err)
	}

	return &challenge, nil
}

// GetByCategoryAndDifficulty retrieves challenges by category and difficulty
func (r *ChallengeRepository) GetByCategoryAndDifficulty(
	ctx context.Context,
	categoryID uuid.UUID,
	difficultyTier int,
	limit int,
) ([]models.Challenge, error) {
	query := `
		SELECT id, category_id, title, description, question_data, correct_answer_hash,
		       difficulty_tier, base_points, time_limit_seconds, challenge_type,
		       ai_generated, is_active, active_until, created_at, usage_count
		FROM challenges
		WHERE category_id = $1 
		  AND difficulty_tier = $2
		  AND is_active = true
		  AND (active_until IS NULL OR active_until > CURRENT_TIMESTAMP)
		ORDER BY RANDOM()
		LIMIT $3
	`

	rows, err := r.db.Pool.Query(ctx, query, categoryID, difficultyTier, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query challenges: %w", err)
	}
	defer rows.Close()

	var challenges []models.Challenge
	for rows.Next() {
		var challenge models.Challenge
		err := rows.Scan(
			&challenge.ID,
			&challenge.CategoryID,
			&challenge.Title,
			&challenge.Description,
			&challenge.QuestionData,
			&challenge.CorrectAnswerHash,
			&challenge.DifficultyTier,
			&challenge.BasePoints,
			&challenge.TimeLimitSeconds,
			&challenge.ChallengeType,
			&challenge.AIGenerated,
			&challenge.IsActive,
			&challenge.ActiveUntil,
			&challenge.CreatedAt,
			&challenge.UsageCount,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan challenge: %w", err)
		}
		challenges = append(challenges, challenge)
	}

	return challenges, nil
}

// GetAvailableChallengesForUser retrieves challenges user hasn't attempted yet
func (r *ChallengeRepository) GetAvailableChallengesForUser(
	ctx context.Context,
	userID uuid.UUID,
	categoryID uuid.UUID,
	difficultyTier *int,
	limit int,
) ([]models.Challenge, error) {
	query := `
		SELECT c.id, c.category_id, c.title, c.description, c.question_data, c.correct_answer_hash,
		       c.difficulty_tier, c.base_points, c.time_limit_seconds, c.challenge_type,
		       c.ai_generated, c.is_active, c.active_until, c.created_at, c.usage_count
		FROM challenges c
		LEFT JOIN user_challenge_attempts uca ON c.id = uca.challenge_id AND uca.user_id = $1
		WHERE c.category_id = $2
		  AND c.is_active = true
		  AND (c.active_until IS NULL OR c.active_until > CURRENT_TIMESTAMP)
		  AND uca.id IS NULL
	`

	args := []interface{}{userID, categoryID}
	argPos := 3

	if difficultyTier != nil {
		query += fmt.Sprintf(" AND c.difficulty_tier = $%d", argPos)
		args = append(args, *difficultyTier)
		argPos++
	}

	query += fmt.Sprintf(" ORDER BY RANDOM() LIMIT $%d", argPos)
	args = append(args, limit)

	rows, err := r.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query challenges: %w", err)
	}
	defer rows.Close()

	var challenges []models.Challenge
	for rows.Next() {
		var challenge models.Challenge
		err := rows.Scan(
			&challenge.ID,
			&challenge.CategoryID,
			&challenge.Title,
			&challenge.Description,
			&challenge.QuestionData,
			&challenge.CorrectAnswerHash,
			&challenge.DifficultyTier,
			&challenge.BasePoints,
			&challenge.TimeLimitSeconds,
			&challenge.ChallengeType,
			&challenge.AIGenerated,
			&challenge.IsActive,
			&challenge.ActiveUntil,
			&challenge.CreatedAt,
			&challenge.UsageCount,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan challenge: %w", err)
		}
		challenges = append(challenges, challenge)
	}

	return challenges, nil
}

// RecordAttempt records a user's challenge attempt
func (r *ChallengeRepository) RecordAttempt(ctx context.Context, attempt *models.ChallengeAttempt) error {
	query := `
		INSERT INTO user_challenge_attempts (
			user_id, challenge_id, is_correct, points_earned, 
			time_taken_seconds, answer_hash
		) VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, attempted_at
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		attempt.UserID,
		attempt.ChallengeID,
		attempt.IsCorrect,
		attempt.PointsEarned,
		attempt.TimeTakenSeconds,
		attempt.AnswerHash,
	).Scan(&attempt.ID, &attempt.AttemptedAt)

	if err != nil {
		// Check for duplicate attempt
		if err.Error() == `duplicate key value violates unique constraint "unique_user_challenge"` {
			return errors.ErrAlreadyAttempted
		}
		return fmt.Errorf("failed to record attempt: %w", err)
	}

	// Increment usage count
	_, _ = r.db.Pool.Exec(ctx, `
		UPDATE challenges 
		SET usage_count = usage_count + 1,
		    correct_count = correct_count + CASE WHEN $2 THEN 1 ELSE 0 END,
		    incorrect_count = incorrect_count + CASE WHEN $2 THEN 0 ELSE 1 END
		WHERE id = $1
	`, attempt.ChallengeID, attempt.IsCorrect)

	return nil
}

// HasUserAttempted checks if user has already attempted a challenge
func (r *ChallengeRepository) HasUserAttempted(ctx context.Context, userID, challengeID uuid.UUID) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM user_challenge_attempts 
			WHERE user_id = $1 AND challenge_id = $2
		)
	`

	var exists bool
	err := r.db.Pool.QueryRow(ctx, query, userID, challengeID).Scan(&exists)
	return exists, err
}

// GetUserAttemptCount gets the number of challenges user attempted today
func (r *ChallengeRepository) GetUserAttemptCount(ctx context.Context, userID uuid.UUID, since time.Time) (int, error) {
	query := `
		SELECT COUNT(*) FROM user_challenge_attempts
		WHERE user_id = $1 AND attempted_at >= $2
	`

	var count int
	err := r.db.Pool.QueryRow(ctx, query, userID, since).Scan(&count)
	return count, err
}

// GetAvailableDifficulties returns available difficulty tiers for a category
func (r *ChallengeRepository) GetAvailableDifficulties(ctx context.Context, categoryID uuid.UUID) ([]int, error) {
	query := `
		SELECT DISTINCT difficulty_tier 
		FROM challenges
		WHERE category_id = $1 AND is_active = true
		ORDER BY difficulty_tier ASC
	`

	rows, err := r.db.Pool.Query(ctx, query, categoryID)
	if err != nil {
		return nil, fmt.Errorf("failed to query difficulties: %w", err)
	}
	defer rows.Close()

	var tiers []int
	for rows.Next() {
		var tier int
		if err := rows.Scan(&tier); err != nil {
			return nil, err
		}
		tiers = append(tiers, tier)
	}

	return tiers, nil
}
