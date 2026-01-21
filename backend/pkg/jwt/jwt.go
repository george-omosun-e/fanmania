package jwt

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// TokenGenerator handles JWT token generation and validation
type TokenGenerator struct {
	secret             []byte
	accessTokenExpiry  time.Duration
	refreshTokenExpiry time.Duration
}

// Claims represents JWT claims
type Claims struct {
	UserID   uuid.UUID `json:"user_id"`
	Username string    `json:"username"`
	TokenType string   `json:"token_type"` // "access" or "refresh"
	jwt.RegisteredClaims
}

// NewTokenGenerator creates a new TokenGenerator
func NewTokenGenerator(secret string, accessExpiry, refreshExpiry time.Duration) *TokenGenerator {
	return &TokenGenerator{
		secret:             []byte(secret),
		accessTokenExpiry:  accessExpiry,
		refreshTokenExpiry: refreshExpiry,
	}
}

// GenerateAccessToken generates an access token
func (tg *TokenGenerator) GenerateAccessToken(userID uuid.UUID, username string) (string, error) {
	claims := Claims{
		UserID:    userID,
		Username:  username,
		TokenType: "access",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(tg.accessTokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(tg.secret)
}

// GenerateRefreshToken generates a refresh token
func (tg *TokenGenerator) GenerateRefreshToken(userID uuid.UUID, username string) (string, error) {
	claims := Claims{
		UserID:    userID,
		Username:  username,
		TokenType: "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(tg.refreshTokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(tg.secret)
}

// ValidateToken validates a token and returns its claims
func (tg *TokenGenerator) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return tg.secret, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

// ValidateAccessToken validates an access token
func (tg *TokenGenerator) ValidateAccessToken(tokenString string) (*Claims, error) {
	claims, err := tg.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	if claims.TokenType != "access" {
		return nil, fmt.Errorf("not an access token")
	}

	return claims, nil
}

// ValidateRefreshToken validates a refresh token
func (tg *TokenGenerator) ValidateRefreshToken(tokenString string) (*Claims, error) {
	claims, err := tg.ValidateToken(tokenString)
	if err != nil {
		return nil, err
	}

	if claims.TokenType != "refresh" {
		return nil, fmt.Errorf("not a refresh token")
	}

	return claims, nil
}

// GetAccessTokenExpiry returns access token expiry duration
func (tg *TokenGenerator) GetAccessTokenExpiry() time.Duration {
	return tg.accessTokenExpiry
}

// GetRefreshTokenExpiry returns refresh token expiry duration
func (tg *TokenGenerator) GetRefreshTokenExpiry() time.Duration {
	return tg.refreshTokenExpiry
}
