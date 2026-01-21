package handler

import (
	"strconv"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/middleware"
	"github.com/fanmania/backend/internal/service"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// LeaderboardHandler handles leaderboard HTTP requests
type LeaderboardHandler struct {
	rankingService *service.RankingService
}

// NewLeaderboardHandler creates a new LeaderboardHandler
func NewLeaderboardHandler(rankingService *service.RankingService) *LeaderboardHandler {
	return &LeaderboardHandler{
		rankingService: rankingService,
	}
}

// GetGlobalLeaderboard retrieves the global leaderboard
// GET /leaderboards/global?scope=weekly&limit=100
func (h *LeaderboardHandler) GetGlobalLeaderboard(c *fiber.Ctx) error {
	// Parse scope (optional, default: weekly)
	scope := c.Query("scope", "weekly")
	validScopes := map[string]bool{
		"daily":    true,
		"weekly":   true,
		"monthly":  true,
		"all_time": true,
	}
	if !validScopes[scope] {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid scope. Must be: daily, weekly, monthly, or all_time",
			"code":  "INVALID_REQUEST",
		})
	}

	// Parse limit (optional, default 100, max 500)
	limit := 100
	if limitStr := c.Query("limit"); limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit < 1 || parsedLimit > 500 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "limit must be between 1 and 500",
				"code":  "INVALID_REQUEST",
			})
		}
		limit = parsedLimit
	}

	// Get leaderboard
	leaderboard, err := h.rankingService.GetLeaderboard(
		c.Context(),
		nil, // nil = global leaderboard
		scope,
		limit,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get leaderboard",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	// Get current user's rank (if authenticated)
	if userID, err := middleware.GetUserID(c); err == nil {
		// Recalculate ranks to ensure they're up to date
		_ = h.rankingService.RecalculateGlobalRanks(c.Context())
		// TODO: Get user's actual rank after recalculation
		_ = userID
	}

	return c.Status(fiber.StatusOK).JSON(leaderboard)
}

// GetCategoryLeaderboard retrieves leaderboard for a specific category
// GET /leaderboards/category/:id?scope=weekly&limit=100
func (h *LeaderboardHandler) GetCategoryLeaderboard(c *fiber.Ctx) error {
	// Parse category ID
	categoryIDStr := c.Params("id")
	categoryID, err := uuid.Parse(categoryIDStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid category ID",
			"code":  "INVALID_ID",
		})
	}

	// Parse scope
	scope := c.Query("scope", "weekly")
	validScopes := map[string]bool{
		"daily":    true,
		"weekly":   true,
		"monthly":  true,
		"all_time": true,
	}
	if !validScopes[scope] {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid scope. Must be: daily, weekly, monthly, or all_time",
			"code":  "INVALID_REQUEST",
		})
	}

	// Parse limit
	limit := 100
	if limitStr := c.Query("limit"); limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err != nil || parsedLimit < 1 || parsedLimit > 500 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "limit must be between 1 and 500",
				"code":  "INVALID_REQUEST",
			})
		}
		limit = parsedLimit
	}

	// Get leaderboard
	leaderboard, err := h.rankingService.GetLeaderboard(
		c.Context(),
		&categoryID,
		scope,
		limit,
	)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to get leaderboard",
			"code":  errors.ErrInternalServer.Code,
		})
	}

	// Get current user's rank in this category (if authenticated)
	if userID, err := middleware.GetUserID(c); err == nil {
		userRank, err := h.rankingService.GetUserRankInCategory(c.Context(), userID, categoryID)
		if err == nil {
			leaderboard.UserRank = userRank
		}
	}

	return c.Status(fiber.StatusOK).JSON(leaderboard)
}
