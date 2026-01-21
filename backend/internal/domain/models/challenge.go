package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Category represents a fan category (e.g., "Afrobeats 2010s")
type Category struct {
	ID             uuid.UUID  `json:"id" db:"id"`
	Name           string     `json:"name" db:"name"`
	Slug           string     `json:"slug" db:"slug"`
	Description    *string    `json:"description,omitempty" db:"description"`
	IconType       string     `json:"icon_type" db:"icon_type"`
	ColorPrimary   string     `json:"color_primary" db:"color_primary"`
	ColorSecondary string     `json:"color_secondary" db:"color_secondary"`
	IsActive       bool       `json:"is_active" db:"is_active"`
	CreatedAt      time.Time  `json:"created_at" db:"created_at"`
	SortOrder      int        `json:"sort_order" db:"sort_order"`
	UserStats      *CategoryUserStats `json:"user_stats,omitempty" db:"-"`
}

// CategoryUserStats represents user-specific stats for a category
type CategoryUserStats struct {
	Points            int64   `json:"points"`
	Rank              *int    `json:"rank"`
	MasteryPercentage float64 `json:"mastery_percentage"`
	StreakDays        int     `json:"streak_days"`
}

// Challenge represents a skill-based challenge
type Challenge struct {
	ID                uuid.UUID       `json:"id" db:"id"`
	CategoryID        uuid.UUID       `json:"category_id" db:"category_id"`
	Title             string          `json:"title" db:"title"`
	Description       *string         `json:"description,omitempty" db:"description"`
	QuestionData      json.RawMessage `json:"question_data" db:"question_data"`
	CorrectAnswerHash string          `json:"-" db:"correct_answer_hash"` // Never expose
	DifficultyTier    int             `json:"difficulty_tier" db:"difficulty_tier"`
	BasePoints        int             `json:"base_points" db:"base_points"`
	TimeLimitSeconds  *int            `json:"time_limit_seconds,omitempty" db:"time_limit_seconds"`
	ChallengeType     string          `json:"challenge_type" db:"challenge_type"`
	AIGenerated       bool            `json:"ai_generated" db:"ai_generated"`
	IsActive          bool            `json:"is_active" db:"is_active"`
	ActiveUntil       *time.Time      `json:"active_until,omitempty" db:"active_until"`
	CreatedAt         time.Time       `json:"created_at" db:"created_at"`
	UsageCount        int             `json:"-" db:"usage_count"`
}

// QuestionData represents the structure of challenge questions
type QuestionData struct {
	Type     string          `json:"type"` // multiple_choice, timeline, prediction, true_false
	Question string          `json:"question"`
	Options  []QuestionOption `json:"options,omitempty"`
}

// QuestionOption represents a single option in a challenge
type QuestionOption struct {
	ID   string `json:"id"`
	Text string `json:"text"`
}

// ChallengeAttempt represents a user's attempt at a challenge
type ChallengeAttempt struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	UserID           uuid.UUID  `json:"user_id" db:"user_id"`
	ChallengeID      uuid.UUID  `json:"challenge_id" db:"challenge_id"`
	IsCorrect        bool       `json:"is_correct" db:"is_correct"`
	PointsEarned     int        `json:"points_earned" db:"points_earned"`
	TimeTakenSeconds *int       `json:"time_taken_seconds,omitempty" db:"time_taken_seconds"`
	AnswerHash       *string    `json:"-" db:"answer_hash"` // Hashed answer for security
	AttemptedAt      time.Time  `json:"attempted_at" db:"attempted_at"`
}

// SubmitChallengeRequest is the payload for submitting a challenge attempt
type SubmitChallengeRequest struct {
	ChallengeID      uuid.UUID `json:"challenge_id" validate:"required"`
	SelectedAnswer   string    `json:"selected_answer" validate:"required"`
	TimeTakenSeconds *int      `json:"time_taken_seconds,omitempty" validate:"omitempty,min=1"`
}

// ChallengeResult is returned after submitting a challenge
type ChallengeResult struct {
	IsCorrect       bool    `json:"is_correct"`
	PointsEarned    int     `json:"points_earned"`
	Explanation     *string `json:"explanation,omitempty"`
	NewTotalPoints  int64   `json:"new_total_points"`
	NewRank         *int    `json:"new_rank,omitempty"`
	StreakUpdated   bool    `json:"streak_updated"`
	StreakDays      int     `json:"streak_days"`
}

// CategoryRanking represents a user's ranking in a category
type CategoryRanking struct {
	ID                  uuid.UUID  `json:"id" db:"id"`
	UserID              uuid.UUID  `json:"user_id" db:"user_id"`
	CategoryID          uuid.UUID  `json:"category_id" db:"category_id"`
	Points              int64      `json:"points" db:"points"`
	Rank                *int       `json:"rank,omitempty" db:"rank"`
	MasteryPercentage   float64    `json:"mastery_percentage" db:"mastery_percentage"`
	ChallengesCompleted int        `json:"challenges_completed" db:"challenges_completed"`
	ChallengesCorrect   int        `json:"challenges_correct" db:"challenges_correct"`
	StreakDays          int        `json:"streak_days" db:"streak_days"`
	LongestStreak       int        `json:"longest_streak" db:"longest_streak"`
	LastActivity        *time.Time `json:"last_activity,omitempty" db:"last_activity"`
	UpdatedAt           time.Time  `json:"updated_at" db:"updated_at"`
}
