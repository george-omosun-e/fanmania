package handler

import (
	"strconv"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/middleware"
	"github.com/fanmania/backend/internal/service"
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// AdminHandler handles admin operations
type AdminHandler struct {
	aiChallengeService *service.AIChallengeService
	validate           *validator.Validate
}

// NewAdminHandler creates a new AdminHandler
func NewAdminHandler(aiChallengeService *service.AIChallengeService) *AdminHandler {
	return &AdminHandler{
		aiChallengeService: aiChallengeService,
		validate:           validator.New(),
	}
}

// GenerateChallenge generates a single challenge using AI
// POST /admin/challenges/generate
func (h *AdminHandler) GenerateChallenge(c *fiber.Ctx) error {
	// For now, we'll skip admin authentication
	// In production, add admin middleware check
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// TODO: Check if user is admin
	_ = userID

	var req struct {
		CategoryID     string `json:"category_id" validate:"required,uuid"`
		DifficultyTier int    `json:"difficulty_tier" validate:"required,min=1,max=5"`
		ChallengeType  string `json:"challenge_type" validate:"required,oneof=multiple_choice timeline true_false"`
		SaveToDatabase bool   `json:"save_to_database"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
			"code":  "INVALID_REQUEST",
		})
	}

	if err := h.validate.Struct(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": err.Error(),
			"code":  errors.ErrInvalidInput.Code,
		})
	}

	categoryID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category ID",
			"code":  "INVALID_ID",
		})
	}

	// Generate challenge
	var result *service.GenerateChallengeResult
	if req.SaveToDatabase {
		result, err = h.aiChallengeService.GenerateAndSaveChallenge(
			c.Context(),
			categoryID,
			req.DifficultyTier,
			req.ChallengeType,
		)
	} else {
		result, err = h.aiChallengeService.GenerateChallenge(
			c.Context(),
			categoryID,
			req.DifficultyTier,
			req.ChallengeType,
		)
	}

	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(result)
}

// GenerateBatch generates multiple challenges at once
// POST /admin/challenges/generate-batch
func (h *AdminHandler) GenerateBatch(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// TODO: Check if user is admin
	_ = userID

	var req struct {
		CategoryID      string `json:"category_id" validate:"required,uuid"`
		DifficultyTiers []int  `json:"difficulty_tiers" validate:"required,min=1"`
		ChallengeType   string `json:"challenge_type" validate:"required,oneof=multiple_choice timeline true_false"`
		CountPerTier    int    `json:"count_per_tier" validate:"required,min=1,max=10"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
			"code":  "INVALID_REQUEST",
		})
	}

	if err := h.validate.Struct(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": err.Error(),
			"code":  errors.ErrInvalidInput.Code,
		})
	}

	// Validate difficulty tiers
	for _, tier := range req.DifficultyTiers {
		if tier < 1 || tier > 5 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Difficulty tier must be between 1 and 5",
				"code":  "INVALID_REQUEST",
			})
		}
	}

	categoryID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category ID",
			"code":  "INVALID_ID",
		})
	}

	// Generate batch
	results, err := h.aiChallengeService.GenerateBatch(
		c.Context(),
		categoryID,
		req.DifficultyTiers,
		req.ChallengeType,
		req.CountPerTier,
	)

	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
			"code":  errors.ErrInternalServer.Code,
		})
	}

	// Count successes and failures
	successCount := 0
	failureCount := 0
	for _, r := range results {
		if r.Success {
			successCount++
		} else {
			failureCount++
		}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"results":       results,
		"total":         len(results),
		"success_count": successCount,
		"failure_count": failureCount,
	})
}

// ValidateAPIKey validates the Anthropic API key
// GET /admin/ai/validate-key
func (h *AdminHandler) ValidateAPIKey(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// TODO: Check if user is admin
	_ = userID

	err = h.aiChallengeService.ValidateAPIKey(c.Context())
	if err != nil {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"valid": false,
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"valid":   true,
		"message": "API key is valid",
	})
}

// GenerateCategories generates new category ideas using AI
// POST /admin/categories/generate
func (h *AdminHandler) GenerateCategories(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// TODO: Check if user is admin
	_ = userID

	var req struct {
		Count          int  `json:"count" validate:"required,min=1,max=10"`
		SaveToDatabase bool `json:"save_to_database"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
			"code":  "INVALID_REQUEST",
		})
	}

	if req.Count == 0 {
		req.Count = 3 // Default to 3 categories
	}

	// Generate categories
	var result *service.GenerateCategoryResult
	if req.SaveToDatabase {
		result, err = h.aiChallengeService.GenerateAndSaveCategories(c.Context(), req.Count)
	} else {
		result, err = h.aiChallengeService.GenerateCategories(c.Context(), req.Count)
	}

	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
			"code":  errors.ErrInternalServer.Code,
		})
	}

	return c.Status(fiber.StatusOK).JSON(result)
}

// GetGenerationStats returns statistics about AI-generated challenges
// GET /admin/challenges/stats
func (h *AdminHandler) GetGenerationStats(c *fiber.Ctx) error {
	userID, err := middleware.GetUserID(c)
	if err != nil {
		return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
			"error": errors.ErrUnauthorized.Message,
			"code":  errors.ErrUnauthorized.Code,
		})
	}

	// TODO: Check if user is admin
	_ = userID

	// Parse optional filters
	categoryIDStr := c.Query("category_id")
	var categoryID *uuid.UUID
	if categoryIDStr != "" {
		parsed, err := uuid.Parse(categoryIDStr)
		if err == nil {
			categoryID = &parsed
		}
	}

	difficultyStr := c.Query("difficulty_tier")
	var difficulty *int
	if difficultyStr != "" {
		parsed, err := strconv.Atoi(difficultyStr)
		if err == nil && parsed >= 1 && parsed <= 5 {
			difficulty = &parsed
		}
	}

	// TODO: Implement actual stats query
	// For now, return placeholder
	_ = categoryID
	_ = difficulty

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"total_generated":    0,
		"total_active":       0,
		"by_difficulty":      map[int]int{},
		"by_category":        map[string]int{},
		"average_usage":      0,
		"validation_rate":    0,
		"message":            "Stats endpoint placeholder - implement actual queries",
	})
}
