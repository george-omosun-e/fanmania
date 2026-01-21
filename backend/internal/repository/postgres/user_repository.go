package postgres

import (
	"context"
	"fmt"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// UserRepository handles user database operations
type UserRepository struct {
	db *DB
}

// NewUserRepository creates a new UserRepository
func NewUserRepository(db *DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create creates a new user
func (r *UserRepository) Create(ctx context.Context, user *models.User) error {
	query := `
		INSERT INTO users (username, email, password_hash, display_name, avatar_url)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at, total_points, is_active, is_verified
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		user.Username,
		user.Email,
		user.PasswordHash,
		user.DisplayName,
		user.AvatarURL,
	).Scan(
		&user.ID,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.TotalPoints,
		&user.IsActive,
		&user.IsVerified,
	)

	if err != nil {
		// Check for unique constraint violations
		if err.Error() == "duplicate key value violates unique constraint \"users_username_key\"" {
			return errors.ErrUsernameExists
		}
		if err.Error() == "duplicate key value violates unique constraint \"users_email_key\"" {
			return errors.ErrEmailExists
		}
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

// GetByID retrieves a user by ID
func (r *UserRepository) GetByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	query := `
		SELECT id, username, email, password_hash, display_name, avatar_url,
		       total_points, global_rank, created_at, updated_at, last_active,
		       is_active, is_verified
		FROM users
		WHERE id = $1 AND is_active = true
	`

	var user models.User
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.TotalPoints,
		&user.GlobalRank,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.LastActive,
		&user.IsActive,
		&user.IsVerified,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// GetByUsername retrieves a user by username
func (r *UserRepository) GetByUsername(ctx context.Context, username string) (*models.User, error) {
	query := `
		SELECT id, username, email, password_hash, display_name, avatar_url,
		       total_points, global_rank, created_at, updated_at, last_active,
		       is_active, is_verified
		FROM users
		WHERE username = $1 AND is_active = true
	`

	var user models.User
	err := r.db.Pool.QueryRow(ctx, query, username).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.TotalPoints,
		&user.GlobalRank,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.LastActive,
		&user.IsActive,
		&user.IsVerified,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// GetByEmail retrieves a user by email
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*models.User, error) {
	query := `
		SELECT id, username, email, password_hash, display_name, avatar_url,
		       total_points, global_rank, created_at, updated_at, last_active,
		       is_active, is_verified
		FROM users
		WHERE email = $1 AND is_active = true
	`

	var user models.User
	err := r.db.Pool.QueryRow(ctx, query, email).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.AvatarURL,
		&user.TotalPoints,
		&user.GlobalRank,
		&user.CreatedAt,
		&user.UpdatedAt,
		&user.LastActive,
		&user.IsActive,
		&user.IsVerified,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// Update updates a user's profile
func (r *UserRepository) Update(ctx context.Context, user *models.User) error {
	query := `
		UPDATE users
		SET display_name = $1, avatar_url = $2, updated_at = CURRENT_TIMESTAMP
		WHERE id = $3 AND is_active = true
		RETURNING updated_at
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		user.DisplayName,
		user.AvatarURL,
		user.ID,
	).Scan(&user.UpdatedAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return errors.ErrUserNotFound
		}
		return fmt.Errorf("failed to update user: %w", err)
	}

	return nil
}

// UpdateLastActive updates the user's last active timestamp
func (r *UserRepository) UpdateLastActive(ctx context.Context, userID uuid.UUID) error {
	query := `
		UPDATE users
		SET last_active = CURRENT_TIMESTAMP
		WHERE id = $1
	`

	_, err := r.db.Pool.Exec(ctx, query, userID)
	return err
}

// UpdatePoints updates user's total points and rank
func (r *UserRepository) UpdatePoints(ctx context.Context, userID uuid.UUID, pointsDelta int) error {
	query := `
		UPDATE users
		SET total_points = total_points + $1,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $2
	`

	_, err := r.db.Pool.Exec(ctx, query, pointsDelta, userID)
	return err
}

// UsernameExists checks if a username already exists
func (r *UserRepository) UsernameExists(ctx context.Context, username string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE username = $1)`

	var exists bool
	err := r.db.Pool.QueryRow(ctx, query, username).Scan(&exists)
	if err != nil {
		return false, err
	}

	return exists, nil
}

// EmailExists checks if an email already exists
func (r *UserRepository) EmailExists(ctx context.Context, email string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)`

	var exists bool
	err := r.db.Pool.QueryRow(ctx, query, email).Scan(&exists)
	if err != nil {
		return false, err
	}

	return exists, nil
}

// GetStats retrieves user statistics
func (r *UserRepository) GetStats(ctx context.Context, userID uuid.UUID) (*models.UserStats, error) {
	query := `
		SELECT 
			u.total_points,
			u.global_rank,
			COUNT(DISTINCT cr.category_id) as categories_active,
			COUNT(DISTINCT uca.challenge_id) as challenges_completed,
			COALESCE(MAX(us.current_streak), 0) as current_streak,
			COALESCE(MAX(us.longest_streak), 0) as longest_streak,
			CASE 
				WHEN COUNT(uca.id) > 0 
				THEN (COUNT(CASE WHEN uca.is_correct THEN 1 END)::float / COUNT(uca.id)::float * 100)
				ELSE 0 
			END as accuracy_rate
		FROM users u
		LEFT JOIN category_rankings cr ON u.id = cr.user_id
		LEFT JOIN user_challenge_attempts uca ON u.id = uca.user_id
		LEFT JOIN user_streaks us ON u.id = us.user_id
		WHERE u.id = $1 AND u.is_active = true
		GROUP BY u.id, u.total_points, u.global_rank
	`

	var stats models.UserStats
	err := r.db.Pool.QueryRow(ctx, query, userID).Scan(
		&stats.TotalPoints,
		&stats.GlobalRank,
		&stats.CategoriesActive,
		&stats.ChallengesCompleted,
		&stats.CurrentStreak,
		&stats.LongestStreak,
		&stats.AccuracyRate,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user stats: %w", err)
	}

	return &stats, nil
}
