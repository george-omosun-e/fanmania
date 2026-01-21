package models

import (
	"time"

	"github.com/google/uuid"
)

// User represents a user account
type User struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	Username     string     `json:"username" db:"username"`
	Email        string     `json:"email" db:"email"`
	PasswordHash string     `json:"-" db:"password_hash"` // Never expose in JSON
	DisplayName  *string    `json:"display_name,omitempty" db:"display_name"`
	AvatarURL    *string    `json:"avatar_url,omitempty" db:"avatar_url"`
	TotalPoints  int64      `json:"total_points" db:"total_points"`
	GlobalRank   *int       `json:"global_rank,omitempty" db:"global_rank"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
	LastActive   *time.Time `json:"last_active,omitempty" db:"last_active"`
	IsActive     bool       `json:"is_active" db:"is_active"`
	IsVerified   bool       `json:"is_verified" db:"is_verified"`
}

// RegisterRequest is the payload for user registration
type RegisterRequest struct {
	Username    string  `json:"username" validate:"required,min=3,max=30,alphanum"`
	Email       string  `json:"email" validate:"required,email"`
	Password    string  `json:"password" validate:"required,min=8"`
	DisplayName *string `json:"display_name,omitempty" validate:"omitempty,max=50"`
}

// LoginRequest is the payload for user login
type LoginRequest struct {
	Username string `json:"username" validate:"required"`
	Password string `json:"password" validate:"required"`
}

// AuthResponse is returned after successful authentication
type AuthResponse struct {
	User         *User  `json:"user"`
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"` // seconds
}

// UpdateUserRequest is the payload for updating user profile
type UpdateUserRequest struct {
	DisplayName *string `json:"display_name,omitempty" validate:"omitempty,max=50"`
	AvatarURL   *string `json:"avatar_url,omitempty" validate:"omitempty,url"`
}

// UserStats represents user statistics
type UserStats struct {
	TotalPoints         int64   `json:"total_points"`
	GlobalRank          *int    `json:"global_rank"`
	CategoriesActive    int     `json:"categories_active"`
	ChallengesCompleted int     `json:"challenges_completed"`
	CurrentStreak       int     `json:"current_streak"`
	LongestStreak       int     `json:"longest_streak"`
	AccuracyRate        float64 `json:"accuracy_rate"` // percentage
}
