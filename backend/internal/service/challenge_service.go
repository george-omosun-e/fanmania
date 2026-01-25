package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/google/uuid"
)

// ChallengeService handles challenge business logic
type ChallengeService struct {
	challengeRepo      *postgres.ChallengeRepository
	userRepo           *postgres.UserRepository
	categoryRepo       *postgres.CategoryRepository
	aiChallengeService *AIChallengeService
}

// NewChallengeService creates a new ChallengeService
func NewChallengeService(
	challengeRepo *postgres.ChallengeRepository,
	userRepo *postgres.UserRepository,
	categoryRepo *postgres.CategoryRepository,
) *ChallengeService {
	return &ChallengeService{
		challengeRepo: challengeRepo,
		userRepo:      userRepo,
		categoryRepo:  categoryRepo,
	}
}

// SetAIChallengeService sets the AI challenge service for on-demand generation
func (s *ChallengeService) SetAIChallengeService(aiService *AIChallengeService) {
	s.aiChallengeService = aiService
}

// GetChallengesForUser retrieves available challenges for a user
func (s *ChallengeService) GetChallengesForUser(
	ctx context.Context,
	userID uuid.UUID,
	categoryID uuid.UUID,
	difficultyTier *int,
	limit int,
) ([]models.Challenge, error) {
	// Verify category exists
	_, err := s.categoryRepo.GetByID(ctx, categoryID, nil)
	if err != nil {
		return nil, err
	}

	// Get challenges user hasn't attempted
	challenges, err := s.challengeRepo.GetAvailableChallengesForUser(
		ctx, userID, categoryID, difficultyTier, limit,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get challenges: %w", err)
	}

	// If not enough challenges and AI service is configured, generate more
	// Generate when pool is less than requested limit
	if len(challenges) < limit && s.aiChallengeService != nil {
		tier := 1
		if difficultyTier != nil {
			tier = *difficultyTier
		}

		// How many more do we need?
		needed := limit - len(challenges)

		// Generate a few challenges synchronously (to avoid timeout)
		// Limit to 5 synchronous generations to keep response time reasonable
		syncLimit := 5
		if needed < syncLimit {
			syncLimit = needed
		}

		for i := 0; i < syncLimit; i++ {
			result, err := s.aiChallengeService.GenerateAndSaveChallenge(
				ctx, categoryID, tier, "multiple_choice",
			)
			if err != nil || !result.Success {
				continue
			}
			challenges = append(challenges, *result.Challenge)
		}

		// Generate more challenges in background for future requests
		if needed > syncLimit {
			go func() {
				bgCtx := context.Background()
				for i := 0; i < needed-syncLimit; i++ {
					s.aiChallengeService.GenerateAndSaveChallenge(
						bgCtx, categoryID, tier, "multiple_choice",
					)
				}
			}()
		}
	}

	// Remove correct answer hash before returning
	for i := range challenges {
		challenges[i].CorrectAnswerHash = ""
	}

	return challenges, nil
}

// SubmitChallengeAttempt handles a user's challenge submission
func (s *ChallengeService) SubmitChallengeAttempt(
	ctx context.Context,
	userID uuid.UUID,
	req *models.SubmitChallengeRequest,
) (*models.ChallengeResult, error) {
	// Get challenge
	challenge, err := s.challengeRepo.GetByID(ctx, req.ChallengeID)
	if err != nil {
		return nil, err
	}

	// Check if challenge is expired
	if challenge.ActiveUntil != nil && challenge.ActiveUntil.Before(time.Now()) {
		return nil, errors.ErrChallengeExpired
	}

	// Check if user already attempted
	attempted, err := s.challengeRepo.HasUserAttempted(ctx, userID, req.ChallengeID)
	if err != nil {
		return nil, fmt.Errorf("failed to check attempt: %w", err)
	}
	if attempted {
		return nil, errors.ErrAlreadyAttempted
	}

	// Validate answer
	isCorrect := s.validateAnswer(req.SelectedAnswer, challenge.CorrectAnswerHash)

	// Calculate points
	pointsEarned := s.calculatePoints(challenge, isCorrect, req.TimeTakenSeconds)

	// Hash the submitted answer (for analytics, don't store plaintext)
	answerHash := s.hashAnswer(req.SelectedAnswer)

	// Record attempt
	attempt := &models.ChallengeAttempt{
		UserID:           userID,
		ChallengeID:      req.ChallengeID,
		IsCorrect:        isCorrect,
		PointsEarned:     pointsEarned,
		TimeTakenSeconds: req.TimeTakenSeconds,
		AnswerHash:       &answerHash,
	}

	if err := s.challengeRepo.RecordAttempt(ctx, attempt); err != nil {
		return nil, fmt.Errorf("failed to record attempt: %w", err)
	}

	// Update user points
	if err := s.userRepo.UpdatePoints(ctx, userID, pointsEarned); err != nil {
		return nil, fmt.Errorf("failed to update points: %w", err)
	}

	// Get updated user data
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// TODO: Update streak (will implement in streak service)
	streakUpdated := false
	streakDays := 0

	result := &models.ChallengeResult{
		IsCorrect:      isCorrect,
		PointsEarned:   pointsEarned,
		NewTotalPoints: user.TotalPoints,
		NewRank:        user.GlobalRank,
		StreakUpdated:  streakUpdated,
		StreakDays:     streakDays,
	}

	// Add explanation if incorrect
	if !isCorrect {
		explanation := "Incorrect answer. Keep practicing!"
		result.Explanation = &explanation
	}

	return result, nil
}

// validateAnswer checks if the submitted answer matches the correct answer hash
func (s *ChallengeService) validateAnswer(submittedAnswer, correctHash string) bool {
	submittedHash := s.hashAnswer(submittedAnswer)
	return submittedHash == correctHash
}

// hashAnswer creates a SHA256 hash of an answer
func (s *ChallengeService) hashAnswer(answer string) string {
	// Normalize: trim and lowercase
	normalized := strings.ToLower(strings.TrimSpace(answer))
	hash := sha256.Sum256([]byte(normalized))
	return hex.EncodeToString(hash[:])
}

// calculatePoints determines points earned based on difficulty, speed, and correctness
func (s *ChallengeService) calculatePoints(
	challenge *models.Challenge,
	isCorrect bool,
	timeTaken *int,
) int {
	if !isCorrect {
		// Penalty for wrong answer: lose 30% of base points
		return -int(float64(challenge.BasePoints) * 0.3)
	}

	basePoints := float64(challenge.BasePoints)

	// Difficulty multiplier
	var difficultyMultiplier float64
	switch challenge.DifficultyTier {
	case 1:
		difficultyMultiplier = 1.0
	case 2:
		difficultyMultiplier = 1.5
	case 3:
		difficultyMultiplier = 2.0
	case 4:
		difficultyMultiplier = 3.0
	case 5:
		difficultyMultiplier = 5.0
	default:
		difficultyMultiplier = 1.0
	}

	points := basePoints * difficultyMultiplier

	// Speed bonus: if completed in less than 50% of time limit
	if timeTaken != nil && challenge.TimeLimitSeconds != nil {
		timeLimit := float64(*challenge.TimeLimitSeconds)
		timeTakenFloat := float64(*timeTaken)

		if timeTakenFloat < timeLimit*0.5 {
			points *= 1.2 // 20% bonus for speed
		}
	}

	return int(points)
}

// GetAvailableDifficulties returns available difficulty tiers for a category
func (s *ChallengeService) GetAvailableDifficulties(ctx context.Context, categoryID uuid.UUID) ([]int, error) {
	return s.challengeRepo.GetAvailableDifficulties(ctx, categoryID)
}

// CreateChallenge creates a new challenge (for AI generation or admin)
func (s *ChallengeService) CreateChallenge(ctx context.Context, challenge *models.Challenge) error {
	// Verify category exists
	_, err := s.categoryRepo.GetByID(ctx, challenge.CategoryID, nil)
	if err != nil {
		return err
	}

	// Parse question data to validate format
	var questionData models.QuestionData
	if err := json.Unmarshal(challenge.QuestionData, &questionData); err != nil {
		return fmt.Errorf("invalid question data format: %w", err)
	}

	// Validate challenge type
	validTypes := []string{"multiple_choice", "timeline", "prediction", "true_false", "pattern"}
	isValidType := false
	for _, validType := range validTypes {
		if challenge.ChallengeType == validType {
			isValidType = true
			break
		}
	}
	if !isValidType {
		return fmt.Errorf("invalid challenge type: %s", challenge.ChallengeType)
	}

	// Validate difficulty tier
	if challenge.DifficultyTier < 1 || challenge.DifficultyTier > 5 {
		return fmt.Errorf("difficulty tier must be between 1 and 5")
	}

	return s.challengeRepo.Create(ctx, challenge)
}

// GetUserAttemptStats gets user's attempt statistics
func (s *ChallengeService) GetUserAttemptStats(ctx context.Context, userID uuid.UUID) (map[string]interface{}, error) {
	// Get today's attempts
	today := time.Now().Truncate(24 * time.Hour)
	todayCount, err := s.challengeRepo.GetUserAttemptCount(ctx, userID, today)
	if err != nil {
		return nil, err
	}

	// Get this week's attempts
	weekStart := time.Now().AddDate(0, 0, -7)
	weekCount, err := s.challengeRepo.GetUserAttemptCount(ctx, userID, weekStart)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"today": todayCount,
		"week":  weekCount,
	}, nil
}
