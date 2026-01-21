package errors

import (
	"fmt"
	"net/http"
)

// AppError represents a custom application error
type AppError struct {
	Code       string `json:"code"`
	Message    string `json:"message"`
	StatusCode int    `json:"-"`
}

func (e *AppError) Error() string {
	return e.Message
}

// NewAppError creates a new AppError
func NewAppError(code, message string, statusCode int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		StatusCode: statusCode,
	}
}

// Common errors
var (
	// Authentication errors
	ErrUnauthorized     = NewAppError("AUTH_001", "Unauthorized", http.StatusUnauthorized)
	ErrInvalidToken     = NewAppError("AUTH_002", "Invalid or expired token", http.StatusUnauthorized)
	ErrInvalidCredentials = NewAppError("AUTH_003", "Invalid credentials", http.StatusUnauthorized)
	ErrUserNotFound     = NewAppError("AUTH_004", "User not found", http.StatusNotFound)
	
	// Registration errors
	ErrUsernameExists   = NewAppError("REG_001", "Username already exists", http.StatusConflict)
	ErrEmailExists      = NewAppError("REG_002", "Email already exists", http.StatusConflict)
	ErrInvalidInput     = NewAppError("REG_003", "Invalid input data", http.StatusBadRequest)
	
	// Challenge errors
	ErrChallengeNotFound = NewAppError("CHAL_001", "Challenge not found", http.StatusNotFound)
	ErrAlreadyAttempted  = NewAppError("CHAL_002", "Challenge already attempted", http.StatusConflict)
	ErrChallengeExpired  = NewAppError("CHAL_003", "Challenge has expired", http.StatusGone)
	
	// Category errors
	ErrCategoryNotFound = NewAppError("CAT_001", "Category not found", http.StatusNotFound)
	
	// Rate limiting errors
	ErrRateLimitExceeded = NewAppError("RATE_001", "Rate limit exceeded", http.StatusTooManyRequests)
	
	// Database errors
	ErrDatabaseError = NewAppError("DB_001", "Database error", http.StatusInternalServerError)
	
	// Internal errors
	ErrInternalServer = NewAppError("INT_001", "Internal server error", http.StatusInternalServerError)
)

// WrapError wraps a generic error into an AppError
func WrapError(err error, code string, message string, statusCode int) *AppError {
	return &AppError{
		Code:       code,
		Message:    fmt.Sprintf("%s: %v", message, err),
		StatusCode: statusCode,
	}
}
