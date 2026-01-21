package middleware

import (
	"strings"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/service"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// AuthMiddleware protects routes that require authentication
func AuthMiddleware(authService *service.AuthService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Get Authorization header
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
				"error": errors.ErrUnauthorized.Message,
				"code":  errors.ErrUnauthorized.Code,
			})
		}

		// Extract token (format: "Bearer <token>")
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(errors.ErrUnauthorized.StatusCode).JSON(fiber.Map{
				"error": "Invalid authorization header format",
				"code":  errors.ErrUnauthorized.Code,
			})
		}

		token := parts[1]

		// Validate token
		userID, err := authService.ValidateToken(token)
		if err != nil {
			return c.Status(errors.ErrInvalidToken.StatusCode).JSON(fiber.Map{
				"error": errors.ErrInvalidToken.Message,
				"code":  errors.ErrInvalidToken.Code,
			})
		}

		// Store user ID in context
		c.Locals("userID", userID)

		return c.Next()
	}
}

// GetUserID extracts user ID from context
func GetUserID(c *fiber.Ctx) (uuid.UUID, error) {
	userID, ok := c.Locals("userID").(uuid.UUID)
	if !ok {
		return uuid.Nil, errors.ErrUnauthorized
	}
	return userID, nil
}
