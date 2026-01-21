package handler

import (
	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/middleware"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

// UserHandler handles user HTTP requests
type UserHandler struct {
	userRepo *postgres.UserRepository
	validate *validator.Validate
}

// NewUserHandler creates a new UserHandler
func NewUserHandler(userRepo *postgres.UserRepository) *UserHandler {
	return &UserHandler{
		userRepo: userRepo,
		validate: validator.New(),
	}
}

// GetMe retrieves the current user's profile
// GET /users/me
func (h *UserHandler) GetMe(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	user, err := h.userRepo.GetByID(c.Context(), userID)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			return c.Status(appErr.StatusCode).JSON(fiber.Map{
				"error": appErr.Message,
				"code":  appErr.Code,
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get user",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(user)
}

// GetStats retrieves the current user's statistics
// GET /users/me/stats
func (h *UserHandler) GetStats(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	stats, err := h.userRepo.GetStats(c.Context(), userID)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			return c.Status(appErr.StatusCode).JSON(fiber.Map{
				"error": appErr.Message,
				"code":  appErr.Code,
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get stats",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(stats)
}

// UpdateProfile updates the current user's profile
// PATCH /users/me
func (h *UserHandler) UpdateProfile(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	var req models.UpdateUserRequest
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

	// Get current user
	user, err := h.userRepo.GetByID(c.Context(), userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get user",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	// Update fields
	if req.DisplayName != nil {
		user.DisplayName = req.DisplayName
	}
	if req.AvatarURL != nil {
		user.AvatarURL = req.AvatarURL
	}

	// Save changes
	if err := h.userRepo.Update(c.Context(), user); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to update profile",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(user)
}
