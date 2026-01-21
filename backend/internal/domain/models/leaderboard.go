package models

import (
	"time"

	"github.com/google/uuid"
)

// LeaderboardEntry represents a single entry in a leaderboard
type LeaderboardEntry struct {
	Rank              int        `json:"rank"`
	UserID            uuid.UUID  `json:"user_id"`
	Username          string     `json:"username"`
	DisplayName       *string    `json:"display_name,omitempty"`
	AvatarURL         *string    `json:"avatar_url,omitempty"`
	Points            int64      `json:"points"`
	MasteryPercentage *float64   `json:"mastery_percentage,omitempty"`
}

// LeaderboardResponse represents a leaderboard with metadata
type LeaderboardResponse struct {
	Scope      string              `json:"scope"` // daily, weekly, monthly, all_time
	CategoryID *uuid.UUID          `json:"category_id,omitempty"`
	Entries    []LeaderboardEntry  `json:"entries"`
	UserRank   *int                `json:"user_rank,omitempty"`
	TotalUsers int                 `json:"total_users"`
}

// LeaderboardSnapshot represents a saved leaderboard state
type LeaderboardSnapshot struct {
	ID           uuid.UUID  `json:"id" db:"id"`
	UserID       uuid.UUID  `json:"user_id" db:"user_id"`
	CategoryID   *uuid.UUID `json:"category_id,omitempty" db:"category_id"`
	Points       int64      `json:"points" db:"points"`
	Rank         int        `json:"rank" db:"rank"`
	SnapshotType string     `json:"snapshot_type" db:"snapshot_type"` // daily, weekly, monthly, all_time
	SnapshotDate time.Time  `json:"snapshot_date" db:"snapshot_date"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
}

// Notification represents a push notification
type Notification struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	UserID           uuid.UUID  `json:"user_id" db:"user_id"`
	Title            string     `json:"title" db:"title"`
	Body             string     `json:"body" db:"body"`
	NotificationType string     `json:"notification_type" db:"notification_type"`
	ActionURL        *string    `json:"action_url,omitempty" db:"action_url"`
	IsRead           bool       `json:"is_read" db:"is_read"`
	IsPushed         bool       `json:"is_pushed" db:"is_pushed"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	ExpiresAt        *time.Time `json:"expires_at,omitempty" db:"expires_at"`
	ReadAt           *time.Time `json:"read_at,omitempty" db:"read_at"`
}

// NotificationResponse represents the list of notifications
type NotificationResponse struct {
	Notifications []Notification `json:"notifications"`
	UnreadCount   int            `json:"unread_count"`
}

// RegisterDeviceRequest is the payload for registering FCM device token
type RegisterDeviceRequest struct {
	FCMToken   string `json:"fcm_token" validate:"required"`
	DeviceType string `json:"device_type" validate:"required,oneof=ios android"`
}

// UserDeviceToken represents a user's device for push notifications
type UserDeviceToken struct {
	ID         uuid.UUID  `json:"id" db:"id"`
	UserID     uuid.UUID  `json:"user_id" db:"user_id"`
	FCMToken   string     `json:"fcm_token" db:"fcm_token"`
	DeviceType string     `json:"device_type" db:"device_type"`
	DeviceID   *string    `json:"device_id,omitempty" db:"device_id"`
	IsActive   bool       `json:"is_active" db:"is_active"`
	CreatedAt  time.Time  `json:"created_at" db:"created_at"`
	LastUsed   time.Time  `json:"last_used" db:"last_used"`
}

// UserStreak represents a user's activity streak
type UserStreak struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	UserID           uuid.UUID  `json:"user_id" db:"user_id"`
	CategoryID       *uuid.UUID `json:"category_id,omitempty" db:"category_id"` // NULL for global
	CurrentStreak    int        `json:"current_streak" db:"current_streak"`
	LongestStreak    int        `json:"longest_streak" db:"longest_streak"`
	LastActivityDate *time.Time `json:"last_activity_date,omitempty" db:"last_activity_date"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}
