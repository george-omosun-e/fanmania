package service

import (
	"context"
	"fmt"
	"time"

	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/google/uuid"
)

// StreakService handles user streak tracking
type StreakService struct {
	db *postgres.DB
}

// NewStreakService creates a new StreakService
func NewStreakService(db *postgres.DB) *StreakService {
	return &StreakService{
		db: db,
	}
}

// UpdateStreak updates user's streak after completing a challenge
func (s *StreakService) UpdateStreak(ctx context.Context, userID uuid.UUID, categoryID *uuid.UUID) error {
	today := time.Now().Truncate(24 * time.Hour)
	yesterday := today.AddDate(0, 0, -1)

	// Start transaction
	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Get current streak
	query := `
		SELECT id, current_streak, longest_streak, last_activity_date
		FROM user_streaks
		WHERE user_id = $1 AND (category_id = $2 OR ($2 IS NULL AND category_id IS NULL))
		FOR UPDATE
	`

	var streakID uuid.UUID
	var currentStreak, longestStreak int
	var lastActivity *time.Time

	err = tx.QueryRow(ctx, query, userID, categoryID).Scan(
		&streakID, &currentStreak, &longestStreak, &lastActivity,
	)

	if err != nil {
		// No streak exists, create one
		insertQuery := `
			INSERT INTO user_streaks (user_id, category_id, current_streak, longest_streak, last_activity_date)
			VALUES ($1, $2, 1, 1, $3)
		`
		_, err = tx.Exec(ctx, insertQuery, userID, categoryID, today)
		if err != nil {
			return fmt.Errorf("failed to create streak: %w", err)
		}
		return tx.Commit(ctx)
	}

	// Determine new streak value
	newStreak := currentStreak
	if lastActivity == nil {
		// First activity
		newStreak = 1
	} else {
		lastActivityDate := lastActivity.Truncate(24 * time.Hour)
		
		if lastActivityDate.Equal(today) {
			// Already completed today, no change
			return tx.Commit(ctx)
		} else if lastActivityDate.Equal(yesterday) {
			// Consecutive day, increment streak
			newStreak = currentStreak + 1
		} else {
			// Streak broken, restart
			newStreak = 1
		}
	}

	// Update longest streak if necessary
	newLongestStreak := longestStreak
	if newStreak > longestStreak {
		newLongestStreak = newStreak
	}

	// Update streak
	updateQuery := `
		UPDATE user_streaks
		SET current_streak = $1,
		    longest_streak = $2,
		    last_activity_date = $3,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $4
	`

	_, err = tx.Exec(ctx, updateQuery, newStreak, newLongestStreak, today, streakID)
	if err != nil {
		return fmt.Errorf("failed to update streak: %w", err)
	}

	return tx.Commit(ctx)
}

// GetUserStreak gets user's current streak
func (s *StreakService) GetUserStreak(ctx context.Context, userID uuid.UUID, categoryID *uuid.UUID) (*models.UserStreak, error) {
	query := `
		SELECT id, user_id, category_id, current_streak, longest_streak, last_activity_date, updated_at
		FROM user_streaks
		WHERE user_id = $1 AND (category_id = $2 OR ($2 IS NULL AND category_id IS NULL))
	`

	var streak models.UserStreak
	err := s.db.Pool.QueryRow(ctx, query, userID, categoryID).Scan(
		&streak.ID,
		&streak.UserID,
		&streak.CategoryID,
		&streak.CurrentStreak,
		&streak.LongestStreak,
		&streak.LastActivityDate,
		&streak.UpdatedAt,
	)

	if err != nil {
		// Return zero streak if not found
		return &models.UserStreak{
			UserID:         userID,
			CategoryID:     categoryID,
			CurrentStreak:  0,
			LongestStreak:  0,
			LastActivityDate: nil,
		}, nil
	}

	// Check if streak is still valid (not broken)
	if streak.LastActivityDate != nil {
		today := time.Now().Truncate(24 * time.Hour)
		yesterday := today.AddDate(0, 0, -1)
		lastActivity := streak.LastActivityDate.Truncate(24 * time.Hour)

		// If last activity was before yesterday, streak is broken
		if lastActivity.Before(yesterday) {
			streak.CurrentStreak = 0
		}
	}

	return &streak, nil
}

// GetAllUserStreaks gets all streaks for a user
func (s *StreakService) GetAllUserStreaks(ctx context.Context, userID uuid.UUID) ([]models.UserStreak, error) {
	query := `
		SELECT id, user_id, category_id, current_streak, longest_streak, last_activity_date, updated_at
		FROM user_streaks
		WHERE user_id = $1
		ORDER BY current_streak DESC
	`

	rows, err := s.db.Pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query streaks: %w", err)
	}
	defer rows.Close()

	today := time.Now().Truncate(24 * time.Hour)
	yesterday := today.AddDate(0, 0, -1)

	var streaks []models.UserStreak
	for rows.Next() {
		var streak models.UserStreak
		err := rows.Scan(
			&streak.ID,
			&streak.UserID,
			&streak.CategoryID,
			&streak.CurrentStreak,
			&streak.LongestStreak,
			&streak.LastActivityDate,
			&streak.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan streak: %w", err)
		}

		// Validate streak is not broken
		if streak.LastActivityDate != nil {
			lastActivity := streak.LastActivityDate.Truncate(24 * time.Hour)
			if lastActivity.Before(yesterday) {
				streak.CurrentStreak = 0
			}
		}

		streaks = append(streaks, streak)
	}

	return streaks, nil
}

// CheckStreakAtRisk checks if user's streak is at risk (haven't completed today)
func (s *StreakService) CheckStreakAtRisk(ctx context.Context, userID uuid.UUID) (bool, int, error) {
	// Get global streak
	streak, err := s.GetUserStreak(ctx, userID, nil)
	if err != nil {
		return false, 0, err
	}

	if streak.CurrentStreak == 0 {
		return false, 0, nil // No streak to lose
	}

	today := time.Now().Truncate(24 * time.Hour)
	
	// Check if last activity was today
	if streak.LastActivityDate != nil {
		lastActivity := streak.LastActivityDate.Truncate(24 * time.Hour)
		if lastActivity.Equal(today) {
			return false, streak.CurrentStreak, nil // Safe for today
		}
	}

	// Streak is at risk
	return true, streak.CurrentStreak, nil
}
