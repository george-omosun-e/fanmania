package service

import (
	"context"
	"fmt"
	"time"

	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// RankingService handles ranking and leaderboard logic
type RankingService struct {
	db           *postgres.DB
	userRepo     *postgres.UserRepository
	categoryRepo *postgres.CategoryRepository
}

// NewRankingService creates a new RankingService
func NewRankingService(
	db *postgres.DB,
	userRepo *postgres.UserRepository,
	categoryRepo *postgres.CategoryRepository,
) *RankingService {
	return &RankingService{
		db:           db,
		userRepo:     userRepo,
		categoryRepo: categoryRepo,
	}
}

// UpdateCategoryRanking updates a user's ranking in a category
func (s *RankingService) UpdateCategoryRanking(
	ctx context.Context,
	userID uuid.UUID,
	categoryID uuid.UUID,
	pointsDelta int,
	isCorrect bool,
) error {
	// Start transaction
	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Upsert category ranking
	query := `
		INSERT INTO category_rankings (
			user_id, category_id, points, 
			challenges_completed, challenges_correct, 
			last_activity, updated_at
		) VALUES ($1, $2, $3, 1, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		ON CONFLICT (user_id, category_id) 
		DO UPDATE SET
			points = category_rankings.points + $3,
			challenges_completed = category_rankings.challenges_completed + 1,
			challenges_correct = category_rankings.challenges_correct + CASE WHEN $4 THEN 1 ELSE 0 END,
			last_activity = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP
		RETURNING points, challenges_completed, challenges_correct
	`

	var totalPoints int64
	var completed, correct int
	err = tx.QueryRow(ctx, query, userID, categoryID, pointsDelta, isCorrect).Scan(
		&totalPoints, &completed, &correct,
	)
	if err != nil {
		return fmt.Errorf("failed to update category ranking: %w", err)
	}

	// Calculate mastery percentage
	masteryPercentage := float64(0)
	if completed > 0 {
		masteryPercentage = (float64(correct) / float64(completed)) * 100
	}

	// Update mastery percentage
	_, err = tx.Exec(ctx, `
		UPDATE category_rankings 
		SET mastery_percentage = $1
		WHERE user_id = $2 AND category_id = $3
	`, masteryPercentage, userID, categoryID)
	if err != nil {
		return fmt.Errorf("failed to update mastery: %w", err)
	}

	// Recalculate ranks for this category
	if err := s.recalculateCategoryRanks(ctx, tx, categoryID); err != nil {
		return fmt.Errorf("failed to recalculate ranks: %w", err)
	}

	// Commit transaction
	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// recalculateCategoryRanks recalculates all ranks for a category
func (s *RankingService) recalculateCategoryRanks(ctx context.Context, tx pgx.Tx, categoryID uuid.UUID) error {
	query := `
		WITH ranked_users AS (
			SELECT 
				user_id,
				ROW_NUMBER() OVER (ORDER BY points DESC, updated_at ASC) as new_rank
			FROM category_rankings
			WHERE category_id = $1
		)
		UPDATE category_rankings cr
		SET rank = ru.new_rank
		FROM ranked_users ru
		WHERE cr.user_id = ru.user_id AND cr.category_id = $1
	`

	result, err := tx.Exec(ctx, query, categoryID)
	_ = result // Ignore result, only check error
	return err
}

// RecalculateGlobalRanks recalculates global user ranks
func (s *RankingService) RecalculateGlobalRanks(ctx context.Context) error {
	query := `
		WITH ranked_users AS (
			SELECT 
				id,
				ROW_NUMBER() OVER (ORDER BY total_points DESC, created_at ASC) as new_rank
			FROM users
			WHERE is_active = true
		)
		UPDATE users u
		SET global_rank = ru.new_rank
		FROM ranked_users ru
		WHERE u.id = ru.id
	`

	_, err := s.db.Pool.Exec(ctx, query)
	return err
}

// GetLeaderboard retrieves leaderboard for a category
func (s *RankingService) GetLeaderboard(
	ctx context.Context,
	categoryID *uuid.UUID,
	scope string,
	limit int,
) (*models.LeaderboardResponse, error) {
	var query string
	var args []interface{}

	// Determine time range based on scope
	var timeFilter string
	switch scope {
	case "daily":
		timeFilter = "AND cr.last_activity >= CURRENT_DATE"
	case "weekly":
		timeFilter = "AND cr.last_activity >= CURRENT_DATE - INTERVAL '7 days'"
	case "monthly":
		timeFilter = "AND cr.last_activity >= CURRENT_DATE - INTERVAL '30 days'"
	case "all_time":
		timeFilter = ""
	default:
		timeFilter = ""
	}

	if categoryID != nil {
		// Category-specific leaderboard
		query = fmt.Sprintf(`
			SELECT 
				cr.rank,
				u.id,
				u.username,
				u.display_name,
				u.avatar_url,
				cr.points,
				cr.mastery_percentage
			FROM category_rankings cr
			JOIN users u ON cr.user_id = u.id
			WHERE cr.category_id = $1
			  AND u.is_active = true
			  %s
			ORDER BY cr.rank ASC
			LIMIT $2
		`, timeFilter)
		args = []interface{}{categoryID, limit}
	} else {
		// Global leaderboard
		query = `
			SELECT 
				u.global_rank as rank,
				u.id,
				u.username,
				u.display_name,
				u.avatar_url,
				u.total_points as points,
				NULL as mastery_percentage
			FROM users u
			WHERE u.is_active = true
			  AND u.global_rank IS NOT NULL
			ORDER BY u.global_rank ASC
			LIMIT $1
		`
		args = []interface{}{limit}
	}

	rows, err := s.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query leaderboard: %w", err)
	}
	defer rows.Close()

	var entries []models.LeaderboardEntry
	for rows.Next() {
		var entry models.LeaderboardEntry
		err := rows.Scan(
			&entry.Rank,
			&entry.UserID,
			&entry.Username,
			&entry.DisplayName,
			&entry.AvatarURL,
			&entry.Points,
			&entry.MasteryPercentage,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan leaderboard entry: %w", err)
		}
		entries = append(entries, entry)
	}

	// Get total users count
	var totalUsers int
	if categoryID != nil {
		err = s.db.Pool.QueryRow(ctx, `
			SELECT COUNT(*) FROM category_rankings WHERE category_id = $1
		`, categoryID).Scan(&totalUsers)
	} else {
		err = s.db.Pool.QueryRow(ctx, `
			SELECT COUNT(*) FROM users WHERE is_active = true
		`).Scan(&totalUsers)
	}
	if err != nil {
		totalUsers = 0
	}

	return &models.LeaderboardResponse{
		Scope:      scope,
		CategoryID: categoryID,
		Entries:    entries,
		TotalUsers: totalUsers,
	}, nil
}

// GetUserRankInCategory gets user's current rank in a category
func (s *RankingService) GetUserRankInCategory(
	ctx context.Context,
	userID uuid.UUID,
	categoryID uuid.UUID,
) (*int, error) {
	query := `
		SELECT rank FROM category_rankings
		WHERE user_id = $1 AND category_id = $2
	`

	var rank *int
	err := s.db.Pool.QueryRow(ctx, query, userID, categoryID).Scan(&rank)
	if err != nil {
		return nil, err
	}

	return rank, nil
}

// CreateLeaderboardSnapshot creates a snapshot of current leaderboard state
func (s *RankingService) CreateLeaderboardSnapshot(ctx context.Context, snapshotType string) error {
	now := time.Now()
	snapshotDate := now.Truncate(24 * time.Hour)

	// Category snapshots
	query := `
		INSERT INTO leaderboard_snapshots (
			user_id, category_id, points, rank, snapshot_type, snapshot_date
		)
		SELECT 
			user_id, category_id, points, rank, $1, $2
		FROM category_rankings
		WHERE last_activity >= $3
	`

	var since time.Time
	switch snapshotType {
	case "daily":
		since = now.AddDate(0, 0, -1)
	case "weekly":
		since = now.AddDate(0, 0, -7)
	case "monthly":
		since = now.AddDate(0, -1, 0)
	default:
		since = time.Time{} // All time
	}

	_, err := s.db.Pool.Exec(ctx, query, snapshotType, snapshotDate, since)
	if err != nil {
		return fmt.Errorf("failed to create snapshot: %w", err)
	}

	// Global snapshots
	globalQuery := `
		INSERT INTO leaderboard_snapshots (
			user_id, category_id, points, rank, snapshot_type, snapshot_date
		)
		SELECT 
			id, NULL, total_points, global_rank, $1, $2
		FROM users
		WHERE is_active = true AND global_rank IS NOT NULL
	`

	_, err = s.db.Pool.Exec(ctx, globalQuery, snapshotType, snapshotDate)
	return err
}
