package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	App      AppConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	AI       AIConfig
}

type AppConfig struct {
	Env  string
	Port string
	Host string
	Name string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
	URL      string // Full connection URL (takes precedence)
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
	URL      string // Full connection URL (takes precedence)
}

type JWTConfig struct {
	Secret              string
	AccessTokenExpiry   time.Duration
	RefreshTokenExpiry  time.Duration
}

type AIConfig struct {
	AnthropicAPIKey string
	AnthropicModel  string
	OpenAIAPIKey    string
	OpenAIModel     string
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists (development)
	_ = godotenv.Load()

	cfg := &Config{
		App: AppConfig{
			Env:  getEnv("APP_ENV", "development"),
			Port: getEnv("APP_PORT", "8080"),
			Host: getEnv("APP_HOST", "0.0.0.0"),
			Name: getEnv("APP_NAME", "Fanmania API"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "fanmania"),
			Password: getEnv("DB_PASSWORD", "fanmania_dev_password"),
			Name:     getEnv("DB_NAME", "fanmania_dev"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
			URL:      getEnv("DATABASE_URL", ""),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
			URL:      getEnv("REDIS_URL", ""),
		},
		JWT: JWTConfig{
			Secret:              getEnv("JWT_SECRET", ""),
			AccessTokenExpiry:   getEnvAsDuration("JWT_ACCESS_TOKEN_EXPIRY", 15*time.Minute),
			RefreshTokenExpiry:  getEnvAsDuration("JWT_REFRESH_TOKEN_EXPIRY", 7*24*time.Hour),
		},
		AI: AIConfig{
			AnthropicAPIKey: getEnv("ANTHROPIC_API_KEY", ""),
			AnthropicModel:  getEnv("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
			OpenAIAPIKey:    getEnv("OPENAI_API_KEY", ""),
			OpenAIModel:     getEnv("OPENAI_MODEL", "gpt-4o-mini"),
		},
	}

	// Validate required fields
	if cfg.JWT.Secret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}

	return cfg, nil
}

// Helper functions
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	valueStr := getEnv(key, "")
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	valueStr := getEnv(key, "")
	if value, err := time.ParseDuration(valueStr); err == nil {
		return value
	}
	return defaultValue
}

// GetDatabaseURL returns the full PostgreSQL connection URL
func (c *Config) GetDatabaseURL() string {
	if c.Database.URL != "" {
		return c.Database.URL
	}
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		c.Database.User,
		c.Database.Password,
		c.Database.Host,
		c.Database.Port,
		c.Database.Name,
		c.Database.SSLMode,
	)
}

// GetRedisURL returns the full Redis connection URL
func (c *Config) GetRedisURL() string {
	if c.Redis.URL != "" {
		return c.Redis.URL
	}
	
	if c.Redis.Password != "" {
		return fmt.Sprintf("redis://:%s@%s:%s/%d",
			c.Redis.Password,
			c.Redis.Host,
			c.Redis.Port,
			c.Redis.DB,
		)
	}
	
	return fmt.Sprintf("redis://%s:%s/%d",
		c.Redis.Host,
		c.Redis.Port,
		c.Redis.DB,
	)
}
