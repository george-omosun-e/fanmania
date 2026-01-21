package handler

import (
	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/middleware"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// CategoryHandler handles category HTTP requests
type CategoryHandler struct {
	categoryRepo *postgres.CategoryRepository
}

// NewCategoryHandler creates a new CategoryHandler
func NewCategoryHandler(categoryRepo *postgres.CategoryRepository) *CategoryHandler {
	return &CategoryHandler{
		categoryRepo: categoryRepo,
	}
}

// GetAll retrieves all categories
// GET /categories
func (h *CategoryHandler) GetAll(c *fiber.Ctx) error {
	// Try to get user ID from context (optional)
	var userIDPtr *uuid.UUID
	if userID, err := middleware.GetUserID(c); err == nil {
		userIDPtr = &userID
	}

	categories, err := h.categoryRepo.GetAll(c.Context(), userIDPtr)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get categories",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"categories": categories,
	})
}

// GetByID retrieves a category by ID
// GET /categories/:id
func (h *CategoryHandler) GetByID(c *fiber.Ctx) error {
	// Parse category ID
	categoryIDStr := c.Params("id")
	categoryID, err := uuid.Parse(categoryIDStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category ID",
			"code":  "INVALID_ID",
		})
	}

	// Try to get user ID from context (optional)
	var userIDPtr *uuid.UUID
	if userID, err := middleware.GetUserID(c); err == nil {
		userIDPtr = &userID
	}

	category, err := h.categoryRepo.GetByID(c.Context(), categoryID, userIDPtr)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			return c.Status(appErr.StatusCode).JSON(fiber.Map{
				"error": appErr.Message,
				"code":  appErr.Code,
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get category",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(category)
}
