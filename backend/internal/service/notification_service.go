package service

import (
	"context"
	"fmt"
	"time"

	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/google/uuid"
)

// NotificationService handles notification business logic
type NotificationService struct {
	notificationRepo *postgres.NotificationRepository
	userRepo         *postgres.UserRepository
}

// NewNotificationService creates a new NotificationService
func NewNotificationService(
	notificationRepo *postgres.NotificationRepository,
	userRepo *postgres.UserRepository,
) *NotificationService {
	return &NotificationService{
		notificationRepo: notificationRepo,
		userRepo:         userRepo,
	}
}

// CreateNotification creates a new notification
func (s *NotificationService) CreateNotification(
	ctx context.Context,
	userID uuid.UUID,
	title, body, notificationType string,
	actionURL *string,
	expiresIn *time.Duration,
) error {
	var expiresAt *time.Time
	if expiresIn != nil {
		expiry := time.Now().Add(*expiresIn)
		expiresAt = &expiry
	}

	notification := &models.Notification{
		UserID:           userID,
		Title:            title,
		Body:             body,
		NotificationType: notificationType,
		ActionURL:        actionURL,
		ExpiresAt:        expiresAt,
	}

	return s.notificationRepo.Create(ctx, notification)
}

// GetUserNotifications retrieves notifications for a user
func (s *NotificationService) GetUserNotifications(
	ctx context.Context,
	userID uuid.UUID,
	limit int,
) (*models.NotificationResponse, error) {
	notifications, err := s.notificationRepo.GetByUserID(ctx, userID, limit)
	if err != nil {
		return nil, err
	}

	unreadCount, err := s.notificationRepo.GetUnreadCount(ctx, userID)
	if err != nil {
		unreadCount = 0
	}

	return &models.NotificationResponse{
		Notifications: notifications,
		UnreadCount:   unreadCount,
	}, nil
}

// MarkAsRead marks a notification as read
func (s *NotificationService) MarkAsRead(ctx context.Context, notificationID, userID uuid.UUID) error {
	return s.notificationRepo.MarkAsRead(ctx, notificationID, userID)
}

// MarkAllAsRead marks all notifications as read
func (s *NotificationService) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	return s.notificationRepo.MarkAllAsRead(ctx, userID)
}

// RegisterDevice registers a device for push notifications
func (s *NotificationService) RegisterDevice(
	ctx context.Context,
	userID uuid.UUID,
	fcmToken, deviceType string,
	deviceID *string,
) error {
	token := &models.UserDeviceToken{
		UserID:     userID,
		FCMToken:   fcmToken,
		DeviceType: deviceType,
		DeviceID:   deviceID,
	}

	return s.notificationRepo.RegisterDeviceToken(ctx, token)
}

// SendStreakReminderNotification sends a notification when streak is at risk
func (s *NotificationService) SendStreakReminderNotification(
	ctx context.Context,
	userID uuid.UUID,
	streakDays int,
) error {
	title := "Your streak is at risk!"
	body := fmt.Sprintf("Complete a challenge to maintain your %d-day streak", streakDays)
	
	expiresIn := 24 * time.Hour
	
	return s.CreateNotification(
		ctx,
		userID,
		title,
		body,
		"streak_reminder",
		nil,
		&expiresIn,
	)
}

// SendRankThreatNotification sends a notification when user's rank is threatened
func (s *NotificationService) SendRankThreatNotification(
	ctx context.Context,
	userID uuid.UUID,
	categoryName string,
) error {
	title := "Your rank is under threat"
	body := fmt.Sprintf("Others are catching up in %s. Complete challenges to defend your position!", categoryName)
	
	expiresIn := 48 * time.Hour
	
	return s.CreateNotification(
		ctx,
		userID,
		title,
		body,
		"rank_threat",
		nil,
		&expiresIn,
	)
}

// SendNewChallengeNotification sends a notification for new high-difficulty challenges
func (s *NotificationService) SendNewChallengeNotification(
	ctx context.Context,
	userID uuid.UUID,
	categoryName string,
	difficulty int,
) error {
	title := "New challenge unlocked!"
	body := fmt.Sprintf("A difficulty %d challenge is now available in %s", difficulty, categoryName)
	
	expiresIn := 7 * 24 * time.Hour
	
	return s.CreateNotification(
		ctx,
		userID,
		title,
		body,
		"new_challenge",
		nil,
		&expiresIn,
	)
}

// SendAchievementNotification sends a notification for achievements
func (s *NotificationService) SendAchievementNotification(
	ctx context.Context,
	userID uuid.UUID,
	achievement string,
) error {
	title := "Achievement unlocked!"
	body := achievement
	
	expiresIn := 30 * 24 * time.Hour
	
	return s.CreateNotification(
		ctx,
		userID,
		title,
		body,
		"achievement",
		nil,
		&expiresIn,
	)
}

// SendDifficultyProgressNotification sends notification when user reaches high difficulty
func (s *NotificationService) SendDifficultyProgressNotification(
	ctx context.Context,
	userID uuid.UUID,
	percentage float64,
) error {
	title := "Impressive performance!"
	body := fmt.Sprintf("Only %.0f%% of users have reached this difficulty level", 100-percentage)
	
	expiresIn := 7 * 24 * time.Hour
	
	return s.CreateNotification(
		ctx,
		userID,
		title,
		body,
		"difficulty_progress",
		nil,
		&expiresIn,
	)
}

// CleanupExpiredNotifications removes expired notifications
func (s *NotificationService) CleanupExpiredNotifications(ctx context.Context) error {
	return s.notificationRepo.DeleteExpiredNotifications(ctx)
}
