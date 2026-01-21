package postgres

import (
	"context"
	"fmt"

	"github.com/fanmania/backend/internal/domain/models"
	"github.com/google/uuid"
)

// NotificationRepository handles notification database operations
type NotificationRepository struct {
	db *DB
}

// NewNotificationRepository creates a new NotificationRepository
func NewNotificationRepository(db *DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

// Create creates a new notification
func (r *NotificationRepository) Create(ctx context.Context, notification *models.Notification) error {
	query := `
		INSERT INTO notifications (
			user_id, title, body, notification_type, action_url, expires_at
		) VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, is_read, is_pushed, created_at
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		notification.UserID,
		notification.Title,
		notification.Body,
		notification.NotificationType,
		notification.ActionURL,
		notification.ExpiresAt,
	).Scan(
		&notification.ID,
		&notification.IsRead,
		&notification.IsPushed,
		&notification.CreatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create notification: %w", err)
	}

	return nil
}

// GetByUserID retrieves notifications for a user
func (r *NotificationRepository) GetByUserID(ctx context.Context, userID uuid.UUID, limit int) ([]models.Notification, error) {
	query := `
		SELECT id, user_id, title, body, notification_type, action_url,
		       is_read, is_pushed, created_at, expires_at, read_at
		FROM notifications
		WHERE user_id = $1
		  AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
		ORDER BY created_at DESC
		LIMIT $2
	`

	rows, err := r.db.Pool.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query notifications: %w", err)
	}
	defer rows.Close()

	var notifications []models.Notification
	for rows.Next() {
		var notif models.Notification
		err := rows.Scan(
			&notif.ID,
			&notif.UserID,
			&notif.Title,
			&notif.Body,
			&notif.NotificationType,
			&notif.ActionURL,
			&notif.IsRead,
			&notif.IsPushed,
			&notif.CreatedAt,
			&notif.ExpiresAt,
			&notif.ReadAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan notification: %w", err)
		}
		notifications = append(notifications, notif)
	}

	return notifications, nil
}

// MarkAsRead marks a notification as read
func (r *NotificationRepository) MarkAsRead(ctx context.Context, notificationID uuid.UUID, userID uuid.UUID) error {
	query := `
		UPDATE notifications
		SET is_read = true, read_at = CURRENT_TIMESTAMP
		WHERE id = $1 AND user_id = $2
	`

	result, err := r.db.Pool.Exec(ctx, query, notificationID, userID)
	if err != nil {
		return fmt.Errorf("failed to mark as read: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("notification not found")
	}

	return nil
}

// MarkAllAsRead marks all notifications as read for a user
func (r *NotificationRepository) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	query := `
		UPDATE notifications
		SET is_read = true, read_at = CURRENT_TIMESTAMP
		WHERE user_id = $1 AND is_read = false
	`

	_, err := r.db.Pool.Exec(ctx, query, userID)
	return err
}

// GetUnreadCount gets count of unread notifications
func (r *NotificationRepository) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `
		SELECT COUNT(*) FROM notifications
		WHERE user_id = $1 AND is_read = false
		  AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
	`

	var count int
	err := r.db.Pool.QueryRow(ctx, query, userID).Scan(&count)
	return count, err
}

// RegisterDeviceToken registers or updates a device token for push notifications
func (r *NotificationRepository) RegisterDeviceToken(ctx context.Context, token *models.UserDeviceToken) error {
	query := `
		INSERT INTO user_device_tokens (user_id, fcm_token, device_type, device_id, last_used)
		VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
		ON CONFLICT (user_id, fcm_token)
		DO UPDATE SET
			device_type = $3,
			device_id = $4,
			is_active = true,
			last_used = CURRENT_TIMESTAMP
		RETURNING id, is_active, created_at, last_used
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		token.UserID,
		token.FCMToken,
		token.DeviceType,
		token.DeviceID,
	).Scan(
		&token.ID,
		&token.IsActive,
		&token.CreatedAt,
		&token.LastUsed,
	)

	if err != nil {
		return fmt.Errorf("failed to register device token: %w", err)
	}

	return nil
}

// GetActiveDeviceTokens gets all active device tokens for a user
func (r *NotificationRepository) GetActiveDeviceTokens(ctx context.Context, userID uuid.UUID) ([]string, error) {
	query := `
		SELECT fcm_token FROM user_device_tokens
		WHERE user_id = $1 AND is_active = true
	`

	rows, err := r.db.Pool.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query device tokens: %w", err)
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err != nil {
			return nil, err
		}
		tokens = append(tokens, token)
	}

	return tokens, nil
}

// DeleteDeviceToken removes a device token
func (r *NotificationRepository) DeleteDeviceToken(ctx context.Context, userID uuid.UUID, fcmToken string) error {
	query := `
		UPDATE user_device_tokens
		SET is_active = false
		WHERE user_id = $1 AND fcm_token = $2
	`

	_, err := r.db.Pool.Exec(ctx, query, userID, fcmToken)
	return err
}

// DeleteExpiredNotifications removes expired notifications
func (r *NotificationRepository) DeleteExpiredNotifications(ctx context.Context) error {
	query := `
		DELETE FROM notifications
		WHERE expires_at < CURRENT_TIMESTAMP
	`

	_, err := r.db.Pool.Exec(ctx, query)
	return err
}

// GetPendingPushNotifications gets notifications that haven't been pushed yet
func (r *NotificationRepository) GetPendingPushNotifications(ctx context.Context, limit int) ([]models.Notification, error) {
	query := `
		SELECT id, user_id, title, body, notification_type, action_url,
		       is_read, is_pushed, created_at, expires_at, read_at
		FROM notifications
		WHERE is_pushed = false
		  AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP)
		ORDER BY created_at ASC
		LIMIT $1
	`

	rows, err := r.db.Pool.Query(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query pending notifications: %w", err)
	}
	defer rows.Close()

	var notifications []models.Notification
	for rows.Next() {
		var notif models.Notification
		err := rows.Scan(
			&notif.ID,
			&notif.UserID,
			&notif.Title,
			&notif.Body,
			&notif.NotificationType,
			&notif.ActionURL,
			&notif.IsRead,
			&notif.IsPushed,
			&notif.CreatedAt,
			&notif.ExpiresAt,
			&notif.ReadAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan notification: %w", err)
		}
		notifications = append(notifications, notif)
	}

	return notifications, nil
}

// MarkAsPushed marks a notification as pushed
func (r *NotificationRepository) MarkAsPushed(ctx context.Context, notificationID uuid.UUID) error {
	query := `
		UPDATE notifications
		SET is_pushed = true
		WHERE id = $1
	`

	_, err := r.db.Pool.Exec(ctx, query, notificationID)
	return err
}
