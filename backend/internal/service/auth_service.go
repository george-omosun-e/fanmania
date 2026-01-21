package service

import (
	"context"
	"fmt"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/fanmania/backend/pkg/jwt"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// AuthService handles authentication business logic
type AuthService struct {
	userRepo *postgres.UserRepository
	jwt      *jwt.TokenGenerator
}

// NewAuthService creates a new AuthService
func NewAuthService(userRepo *postgres.UserRepository, jwtGen *jwt.TokenGenerator) *AuthService {
	return &AuthService{
		userRepo: userRepo,
		jwt:      jwtGen,
	}
}

// Register registers a new user
func (s *AuthService) Register(ctx context.Context, req *models.RegisterRequest) (*models.AuthResponse, error) {
	// Check if username exists
	exists, err := s.userRepo.UsernameExists(ctx, req.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to check username: %w", err)
	}
	if exists {
		return nil, errors.ErrUsernameExists
	}

	// Check if email exists
	exists, err = s.userRepo.EmailExists(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("failed to check email: %w", err)
	}
	if exists {
		return nil, errors.ErrEmailExists
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &models.User{
		Username:     req.Username,
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		DisplayName:  req.DisplayName,
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate tokens
	accessToken, err := s.jwt.GenerateAccessToken(user.ID, user.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := s.jwt.GenerateRefreshToken(user.ID, user.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &models.AuthResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(s.jwt.GetAccessTokenExpiry().Seconds()),
	}, nil
}

// Login authenticates a user
func (s *AuthService) Login(ctx context.Context, req *models.LoginRequest) (*models.AuthResponse, error) {
	// Get user by username
	user, err := s.userRepo.GetByUsername(ctx, req.Username)
	if err != nil {
		if err == errors.ErrUserNotFound {
			return nil, errors.ErrInvalidCredentials
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errors.ErrInvalidCredentials
	}

	// Update last active
	_ = s.userRepo.UpdateLastActive(ctx, user.ID)

	// Generate tokens
	accessToken, err := s.jwt.GenerateAccessToken(user.ID, user.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := s.jwt.GenerateRefreshToken(user.ID, user.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &models.AuthResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(s.jwt.GetAccessTokenExpiry().Seconds()),
	}, nil
}

// RefreshToken generates new tokens from a refresh token
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*models.AuthResponse, error) {
	// Validate refresh token
	claims, err := s.jwt.ValidateRefreshToken(refreshToken)
	if err != nil {
		return nil, errors.ErrInvalidToken
	}

	// Get user to ensure they still exist and are active
	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return nil, errors.ErrInvalidToken
	}

	// Generate new tokens
	newAccessToken, err := s.jwt.GenerateAccessToken(user.ID, user.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	newRefreshToken, err := s.jwt.GenerateRefreshToken(user.ID, user.Username)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &models.AuthResponse{
		User:         user,
		AccessToken:  newAccessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    int64(s.jwt.GetAccessTokenExpiry().Seconds()),
	}, nil
}

// ValidateToken validates an access token and returns user ID
func (s *AuthService) ValidateToken(tokenString string) (uuid.UUID, error) {
	claims, err := s.jwt.ValidateAccessToken(tokenString)
	if err != nil {
		return uuid.Nil, errors.ErrInvalidToken
	}

	return claims.UserID, nil
}
