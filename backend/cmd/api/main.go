package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fanmania/backend/internal/config"
	"github.com/fanmania/backend/internal/handler"
	"github.com/fanmania/backend/internal/middleware"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/fanmania/backend/internal/service"
	"github.com/fanmania/backend/pkg/jwt"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize database
	db, err := postgres.NewDB(cfg.GetDatabaseURL())
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	log.Println("✓ Connected to PostgreSQL")

	// Run database migrations
	if err := db.RunMigrations(context.Background()); err != nil {
		log.Printf("⚠ Migration warning: %v", err)
	}

	// Initialize repositories
	userRepo := postgres.NewUserRepository(db)
	categoryRepo := postgres.NewCategoryRepository(db)
	challengeRepo := postgres.NewChallengeRepository(db)
	notificationRepo := postgres.NewNotificationRepository(db)

	// Initialize JWT token generator
	jwtGen := jwt.NewTokenGenerator(
		cfg.JWT.Secret,
		cfg.JWT.AccessTokenExpiry,
		cfg.JWT.RefreshTokenExpiry,
	)

	// Initialize services
	authService := service.NewAuthService(userRepo, jwtGen)
	challengeService := service.NewChallengeService(challengeRepo, userRepo, categoryRepo)
	rankingService := service.NewRankingService(db, userRepo, categoryRepo)
	_ = service.NewStreakService(db) // TODO: Use streakService when implementing streak features
	notificationService := service.NewNotificationService(notificationRepo, userRepo)
	
	// Initialize AI service (only if API key is provided)
	var aiChallengeService *service.AIChallengeService
	if cfg.AI.AnthropicAPIKey != "" {
		aiChallengeService = service.NewAIChallengeService(
			cfg.AI.AnthropicAPIKey,
			challengeRepo,
			categoryRepo,
		)
		// Wire AI service to challenge service for on-demand generation
		challengeService.SetAIChallengeService(aiChallengeService)
		log.Println("✓ AI Challenge Service initialized and connected")
	} else {
		log.Println("⚠ AI Challenge Service disabled (no ANTHROPIC_API_KEY)")
	}

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	userHandler := handler.NewUserHandler(userRepo)
	categoryHandler := handler.NewCategoryHandler(categoryRepo)
	challengeHandler := handler.NewChallengeHandler(challengeService)
	leaderboardHandler := handler.NewLeaderboardHandler(rankingService)
	notificationHandler := handler.NewNotificationHandler(notificationService)
	
	// Initialize admin handler (only if AI service is available)
	var adminHandler *handler.AdminHandler
	if aiChallengeService != nil {
		adminHandler = handler.NewAdminHandler(aiChallengeService)
	}

	// Initialize Fiber app
	app := fiber.New(fiber.Config{
		AppName:      cfg.App.Name,
		ErrorHandler: customErrorHandler,
	})

	// Global middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${latency} ${method} ${path}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,PATCH,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		// Check database health
		if err := db.Health(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":    "unhealthy",
				"database":  "disconnected",
				"timestamp": time.Now(),
			})
		}

		return c.JSON(fiber.Map{
			"status":    "healthy",
			"database":  "connected",
			"timestamp": time.Now(),
		})
	})

	// API v1 routes
	v1 := app.Group("/v1")

	// Public authentication routes
	auth := v1.Group("/auth")
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)
	auth.Post("/refresh", authHandler.RefreshToken)

	// Protected user routes
	users := v1.Group("/users")
	users.Use(middleware.AuthMiddleware(authService))
	users.Get("/me", userHandler.GetMe)
	users.Get("/me/stats", userHandler.GetStats)
	users.Patch("/me", userHandler.UpdateProfile)

	// Category routes (some public, some protected)
	categories := v1.Group("/categories")
	categories.Get("/", categoryHandler.GetAll)           // Public
	categories.Get("/:id", categoryHandler.GetByID)       // Public

	// Protected challenge routes
	challenges := v1.Group("/challenges")
	challenges.Use(middleware.AuthMiddleware(authService))
	challenges.Get("/", challengeHandler.GetChallenges)           // GET /challenges?category_id=xxx&difficulty_tier=1
	challenges.Post("/:id/attempt", challengeHandler.SubmitChallenge) // POST /challenges/:id/attempt
	challenges.Get("/stats", challengeHandler.GetUserAttemptStats)    // GET /challenges/stats

	// Protected leaderboard routes
	leaderboards := v1.Group("/leaderboards")
	leaderboards.Get("/global", leaderboardHandler.GetGlobalLeaderboard)        // GET /leaderboards/global?scope=weekly
	leaderboards.Get("/category/:id", leaderboardHandler.GetCategoryLeaderboard) // GET /leaderboards/category/:id?scope=weekly

	// Protected notification routes
	notifications := v1.Group("/notifications")
	notifications.Use(middleware.AuthMiddleware(authService))
	notifications.Get("/", notificationHandler.GetNotifications)               // GET /notifications?limit=50
	notifications.Post("/:id/read", notificationHandler.MarkAsRead)           // POST /notifications/:id/read
	notifications.Post("/read-all", notificationHandler.MarkAllAsRead)        // POST /notifications/read-all
	notifications.Post("/register-device", notificationHandler.RegisterDevice) // POST /notifications/register-device

	// Admin routes (protected, for AI challenge generation)
	if adminHandler != nil {
		admin := v1.Group("/admin")
		admin.Use(middleware.AuthMiddleware(authService)) // TODO: Add admin check
		
		admin.Post("/challenges/generate", adminHandler.GenerateChallenge)           // POST /admin/challenges/generate
		admin.Post("/challenges/generate-batch", adminHandler.GenerateBatch)         // POST /admin/challenges/generate-batch
		admin.Get("/challenges/stats", adminHandler.GetGenerationStats)              // GET /admin/challenges/stats
		admin.Get("/ai/validate-key", adminHandler.ValidateAPIKey)                   // GET /admin/ai/validate-key
		admin.Post("/categories/generate", adminHandler.GenerateCategories)          // POST /admin/categories/generate
		
		log.Println("✓ Admin routes registered")
	}

	// Start server
	address := fmt.Sprintf("%s:%s", cfg.App.Host, cfg.App.Port)
	log.Printf("🚀 Starting %s on %s", cfg.App.Name, address)
	log.Printf("📝 Environment: %s", cfg.App.Env)
	log.Printf("🔗 Health check: http://localhost:%s/health", cfg.App.Port)
	log.Printf("🔗 API endpoints: http://localhost:%s/v1", cfg.App.Port)

	// Graceful shutdown
	go func() {
		if err := app.Listen(address); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("✓ Server stopped gracefully")
}

// customErrorHandler handles errors globally
func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error": err.Error(),
		"code":  "ERROR",
	})
}
