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

// ChallengeHandler handles challenge HTTP requests
type ChallengeHandler struct {
	challengeService *service.ChallengeService
	validate         *validator.Validate
}

// NewChallengeHandler creates a new ChallengeHandler
func NewChallengeHandler(challengeService *service.ChallengeService) *ChallengeHandler {
	return &ChallengeHandler{
		challengeService: challengeService,
		validate:         validator.New(),
	}
}

// GetChallenges retrieves available challenges for the current user
// GET /challenges?category_id=xxx&difficulty_tier=1&limit=10
func (h *ChallengeHandler) GetChallenges(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// Parse category_id (required)
	categoryIDStr := c.Query("category_id")
	if categoryIDStr == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "category_id is required",
			"code":  "INVALID_REQUEST",
		})
	}

	categoryID, err := uuid.Parse(categoryIDStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category_id format",
			"code":  "INVALID_ID",
		})
	}

	// Parse difficulty_tier (optional)
	var difficultyTier *int
	if diffStr := c.Query("difficulty_tier"); diffStr != "" {
		diff, err := strconv.Atoi(diffStr)
		if err != nil || diff < 1 || diff > 5 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "difficulty_tier must be between 1 and 5",
				"code":  "INVALID_REQUEST",
			})
		}
		difficultyTier = &diff
	}

	// Parse limit (optional, default 10, max 50)
	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit < 1 || parsedLimit > 50 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "limit must be between 1 and 50",
				"code":  "INVALID_REQUEST",
			})
		}
		limit = parsedLimit
	}

	// Get challenges
	challenges, err := h.challengeService.GetChallengesForUser(
		c.Context(),
		userID,
		categoryID,
		difficultyTier,
		limit,
	)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			return c.Status(appErr.StatusCode).JSON(fiber.Map{
				"error": appErr.Message,
				"code":  appErr.Code,
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get challenges",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	// Get available difficulties for this category
	availableTiers, _ := h.challengeService.GetAvailableDifficulties(c.Context(), categoryID)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"challenges":       challenges,
		"available_tiers":  availableTiers,
		"count":            len(challenges),
	})
}

// SubmitChallenge handles challenge submission
// POST /challenges/:id/attempt
func (h *ChallengeHandler) SubmitChallenge(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// Parse challenge ID from URL
	challengeIDStr := c.Params("id")
	challengeID, err := uuid.Parse(challengeIDStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid challenge ID",
			"code":  "INVALID_ID",
		})
	}

	// Parse request body
	var req struct {
		SelectedAnswer   string `json:"selected_answer" validate:"required"`
		TimeTakenSeconds *int   `json:"time_taken_seconds,omitempty" validate:"omitempty,min=1"`
	}

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

	// Create submission request
	submission := &models.SubmitChallengeRequest{
		ChallengeID:      challengeID,
		SelectedAnswer:   req.SelectedAnswer,
		TimeTakenSeconds: req.TimeTakenSeconds,
	}

	// Submit attempt
	result, err := h.challengeService.SubmitChallengeAttempt(
		c.Context(),
		userID,
		submission,
	)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			return c.Status(appErr.StatusCode).JSON(fiber.Map{
				"error": appErr.Message,
				"code":  appErr.Code,
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to submit challenge",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(result)
}

// GetUserAttemptStats retrieves user's challenge attempt statistics
// GET /challenges/stats
func (h *ChallengeHandler) GetUserAttemptStats(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	stats, err := h.challengeService.GetUserAttemptStats(c.Context(), userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get stats",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(stats)
}
