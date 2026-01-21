package handler

import (
	"strconv"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/middleware"
	"github.com/fanmania/backend/internal/service"
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// NotificationHandler handles notification HTTP requests
type NotificationHandler struct {
	notificationService *service.NotificationService
	validate            *validator.Validate
}

// NewNotificationHandler creates a new NotificationHandler
func NewNotificationHandler(notificationService *service.NotificationService) *NotificationHandler {
	return &NotificationHandler{
		notificationService: notificationService,
		validate:            validator.New(),
	}
}

// GetNotifications retrieves notifications for the current user
// GET /notifications?limit=50
func (h *NotificationHandler) GetNotifications(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// Parse limit (optional, default 50, max 200)
	limit := 50
	if limitStr := c.Query("limit"); limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit < 1 || parsedLimit > 200 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "limit must be between 1 and 200",
				"code":  "INVALID_REQUEST",
			})
		}
		limit = parsedLimit
	}

	// Get notifications
	response, err := h.notificationService.GetUserNotifications(c.Context(), userID, limit)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get notifications",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(response)
}

// MarkAsRead marks a notification as read
// POST /notifications/:id/read
func (h *NotificationHandler) MarkAsRead(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// Parse notification ID
	notificationIDStr := c.Params("id")
	notificationID, err := uuid.Parse(notificationIDStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid notification ID",
			"code":  "INVALID_ID",
		})
	}

	// Mark as read
	if err := h.notificationService.MarkAsRead(c.Context(), notificationID, userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to mark notification as read",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
	})
}

// MarkAllAsRead marks all notifications as read
// POST /notifications/read-all
func (h *NotificationHandler) MarkAllAsRead(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	if err := h.notificationService.MarkAllAsRead(c.Context(), userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to mark all notifications as read",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
	})
}

// RegisterDevice registers a device for push notifications
// POST /notifications/register-device
func (h *NotificationHandler) RegisterDevice(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	var req models.RegisterDeviceRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
			"code":  "INVALID_REQUEST",
		})
	}

	// Validate request
	if err := h.validate.Struct(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": err.Error(),
			"code":  errors.ErrInvalidInput.Code,
		})
	}

	// Register device
	if err := h.notificationService.RegisterDevice(
		c.Context(),
		userID,
		req.FCMToken,
		req.DeviceType,
		nil, // device_id is optional
	); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to register device",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
	})
}
