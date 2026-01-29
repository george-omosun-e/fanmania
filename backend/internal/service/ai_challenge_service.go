package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/fanmania/backend/internal/ai"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/fanmania/backend/internal/repository/postgres"
	"github.com/google/uuid"
)

// AIChallengeService handles AI-powered challenge generation
type AIChallengeService struct {
	anthropicClient  *ai.AnthropicClient
	promptBuilder    *ai.ChallengePromptBuilder
	legalValidator   *ai.LegalValidator
	challengeRepo    *postgres.ChallengeRepository
	categoryRepo     *postgres.CategoryRepository
}

// NewAIChallengeService creates a new AI challenge service
func NewAIChallengeService(
	anthropicAPIKey string,
	challengeRepo *postgres.ChallengeRepository,
	categoryRepo *postgres.CategoryRepository,
) *AIChallengeService {
	return &AIChallengeService{
		anthropicClient: ai.NewAnthropicClient(anthropicAPIKey),
		promptBuilder:   ai.NewChallengePromptBuilder(),
		legalValidator:  ai.NewLegalValidator(),
		challengeRepo:   challengeRepo,
		categoryRepo:    categoryRepo,
	}
}

// GenerateChallengeResult represents the result of challenge generation
type GenerateChallengeResult struct {
	Challenge      *models.Challenge        `json:"challenge,omitempty"`
	Validation     *ai.ValidationResult     `json:"validation"`
	GeneratedJSON  string                   `json:"generated_json,omitempty"`
	Success        bool                     `json:"success"`
	Error          string                   `json:"error,omitempty"`
}

// GenerateChallenge generates a new challenge using AI
func (s *AIChallengeService) GenerateChallenge(
	ctx context.Context,
	categoryID uuid.UUID,
	difficultyTier int,
	challengeType string,
) (*GenerateChallengeResult, error) {
	// Get category details
	category, err := s.categoryRepo.GetByID(ctx, categoryID, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to get category: %w", err)
	}

	// Get existing challenges to avoid duplicates (get more for better deduplication)
	existingChallenges, _ := s.challengeRepo.GetByCategoryAndDifficulty(
		ctx, categoryID, difficultyTier, 100,
	)

	existingTitles := []string{}
	for _, ch := range existingChallenges {
		// Include title and question text for better deduplication
		var qd models.QuestionData
		if err := json.Unmarshal(ch.QuestionData, &qd); err == nil {
			existingTitles = append(existingTitles, fmt.Sprintf("- %s: %s", ch.Title, qd.Question))
		} else {
			existingTitles = append(existingTitles, fmt.Sprintf("- %s", ch.Title))
		}
	}

	// Build prompt based on challenge type
	var prompt string
	systemPrompt := s.promptBuilder.GetSystemPrompt()

	switch challengeType {
	case "multiple_choice":
		prompt = s.promptBuilder.BuildMultipleChoicePrompt(
			category.Name,
			*category.Description,
			difficultyTier,
			existingTitles,
		)
	case "timeline":
		prompt = s.promptBuilder.BuildTimelinePrompt(
			category.Name,
			*category.Description,
			difficultyTier,
		)
	case "true_false":
		prompt = s.promptBuilder.BuildTrueFalsePrompt(
			category.Name,
			*category.Description,
			difficultyTier,
		)
	default:
		return nil, fmt.Errorf("unsupported challenge type: %s", challengeType)
	}

	// Generate challenge with AI
	response, err := s.anthropicClient.GenerateChallenge(ctx, prompt, systemPrompt)
	if err != nil {
		return &GenerateChallengeResult{
			Success: false,
			Error:   fmt.Sprintf("AI generation failed: %v", err),
			Validation: &ai.ValidationResult{
				IsValid: false,
				Passed:  false,
			},
		}, nil
	}

	// Clean and parse JSON response
	cleanedJSON := ai.CleanJSONResponse(response)
	
	var generatedChallenge ai.GeneratedChallenge
	if err := json.Unmarshal([]byte(cleanedJSON), &generatedChallenge); err != nil {
		return &GenerateChallengeResult{
			Success:       false,
			Error:         fmt.Sprintf("Failed to parse AI response: %v", err),
			GeneratedJSON: response,
			Validation: &ai.ValidationResult{
				IsValid: false,
				Passed:  false,
				Errors:  []string{"Invalid JSON format"},
			},
		}, nil
	}

	// Validate legal compliance
	validation := s.legalValidator.ValidateChallenge(&generatedChallenge)
	
	if !validation.Passed {
		return &GenerateChallengeResult{
			Success:       false,
			Error:         "Challenge failed legal validation",
			GeneratedJSON: cleanedJSON,
			Validation:    validation,
		}, nil
	}

	// Sanitize content
	sanitized := s.legalValidator.SanitizeChallenge(&generatedChallenge)

	// Check quality
	qualityIssues := s.legalValidator.ValidateQuestionQuality(sanitized)
	if len(qualityIssues) > 0 {
		validation.Warnings = append(validation.Warnings, qualityIssues...)
	}

	// Convert to challenge model
	challenge, err := s.convertToChallenge(categoryID, difficultyTier, challengeType, sanitized)
	if err != nil {
		return &GenerateChallengeResult{
			Success:       false,
			Error:         fmt.Sprintf("Failed to convert to challenge: %v", err),
			GeneratedJSON: cleanedJSON,
			Validation:    validation,
		}, nil
	}

	return &GenerateChallengeResult{
		Challenge:     challenge,
		Validation:    validation,
		GeneratedJSON: cleanedJSON,
		Success:       true,
	}, nil
}

// GenerateAndSaveChallenge generates and saves a challenge to database
func (s *AIChallengeService) GenerateAndSaveChallenge(
	ctx context.Context,
	categoryID uuid.UUID,
	difficultyTier int,
	challengeType string,
) (*GenerateChallengeResult, error) {
	result, err := s.GenerateChallenge(ctx, categoryID, difficultyTier, challengeType)
	if err != nil {
		return nil, err
	}

	if !result.Success {
		return result, nil
	}

	// Check for duplicate content before saving
	if s.isDuplicateQuestion(ctx, categoryID, result.Challenge.QuestionData) {
		result.Success = false
		result.Error = "Generated question is too similar to existing questions"
		return result, nil
	}

	// Save to database
	if err := s.challengeRepo.Create(ctx, result.Challenge); err != nil {
		result.Success = false
		result.Error = fmt.Sprintf("Failed to save challenge: %v", err)
		return result, nil
	}

	return result, nil
}

// isDuplicateQuestion checks if a similar question already exists
func (s *AIChallengeService) isDuplicateQuestion(ctx context.Context, categoryID uuid.UUID, questionData json.RawMessage) bool {
	// Parse the question
	var newQD models.QuestionData
	if err := json.Unmarshal(questionData, &newQD); err != nil {
		return false
	}

	// Create a normalized hash of the question
	newHash := s.hashQuestion(newQD.Question)

	// Get existing challenges
	existingChallenges, err := s.challengeRepo.GetByCategoryAndDifficulty(ctx, categoryID, 0, 200)
	if err != nil {
		return false
	}

	// Check for duplicates
	for _, ch := range existingChallenges {
		var existingQD models.QuestionData
		if err := json.Unmarshal(ch.QuestionData, &existingQD); err != nil {
			continue
		}
		if s.hashQuestion(existingQD.Question) == newHash {
			return true
		}
	}

	return false
}

// hashQuestion creates a normalized hash for question comparison
func (s *AIChallengeService) hashQuestion(question string) string {
	// Normalize: lowercase, remove extra spaces, trim
	normalized := strings.ToLower(strings.TrimSpace(question))
	normalized = strings.Join(strings.Fields(normalized), " ")
	hash := sha256.Sum256([]byte(normalized))
	return hex.EncodeToString(hash[:])
}

// GenerateBatch generates multiple challenges at once
func (s *AIChallengeService) GenerateBatch(
	ctx context.Context,
	categoryID uuid.UUID,
	difficultyTiers []int,
	challengeType string,
	count int,
) ([]*GenerateChallengeResult, error) {
	results := []*GenerateChallengeResult{}

	for _, tier := range difficultyTiers {
		for i := 0; i < count; i++ {
			result, err := s.GenerateAndSaveChallenge(ctx, categoryID, tier, challengeType)
			if err != nil {
				// Log error but continue
				results = append(results, &GenerateChallengeResult{
					Success: false,
					Error:   err.Error(),
				})
				continue
			}
			
			results = append(results, result)
			
			// Rate limiting - wait 2 seconds between calls
			time.Sleep(2 * time.Second)
		}
	}

	return results, nil
}

// convertToChallenge converts AI-generated challenge to domain model
func (s *AIChallengeService) convertToChallenge(
	categoryID uuid.UUID,
	difficultyTier int,
	challengeType string,
	generated *ai.GeneratedChallenge,
) (*models.Challenge, error) {
	// Build question data JSON with shuffled options
	questionData := models.QuestionData{
		Type:     challengeType,
		Question: generated.Question,
		Options:  []models.QuestionOption{},
	}

	// Create options and shuffle them
	options := make([]models.QuestionOption, 0, len(generated.Options))
	for _, opt := range generated.Options {
		options = append(options, models.QuestionOption{
			ID:   opt.ID,
			Text: opt.Text,
		})
	}

	// Shuffle options randomly
	rand.Shuffle(len(options), func(i, j int) {
		options[i], options[j] = options[j], options[i]
	})

	questionData.Options = options

	questionJSON, err := json.Marshal(questionData)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal question data: %w", err)
	}

	// Hash the correct answer
	correctAnswerHash := s.hashAnswer(generated.CorrectAnswer)

	// Calculate base points (100 for all)
	basePoints := 100

	// Calculate time limit based on difficulty
	timeLimitSeconds := s.calculateTimeLimit(difficultyTier, challengeType)

	// Set active until (30 days from now)
	activeUntil := time.Now().AddDate(0, 0, 30)

	description := generated.Description
	challenge := &models.Challenge{
		CategoryID:        categoryID,
		Title:             generated.Title,
		Description:       &description,
		QuestionData:      questionJSON,
		CorrectAnswerHash: correctAnswerHash,
		DifficultyTier:    difficultyTier,
		BasePoints:        basePoints,
		TimeLimitSeconds:  &timeLimitSeconds,
		ChallengeType:     challengeType,
		AIGenerated:       true,
		IsActive:          true,
		ActiveUntil:       &activeUntil,
	}

	return challenge, nil
}

// hashAnswer creates SHA256 hash of answer
func (s *AIChallengeService) hashAnswer(answer string) string {
	normalized := strings.ToLower(strings.TrimSpace(answer))
	hash := sha256.Sum256([]byte(normalized))
	return hex.EncodeToString(hash[:])
}

// calculateTimeLimit determines time limit based on difficulty and type
func (s *AIChallengeService) calculateTimeLimit(difficultyTier int, challengeType string) int {
	baseTime := 30 // seconds

	switch challengeType {
	case "multiple_choice":
		baseTime = 30
	case "timeline":
		baseTime = 45
	case "true_false":
		baseTime = 20
	}

	// Add time for higher difficulties
	extraTime := (difficultyTier - 1) * 10
	
	return baseTime + extraTime
}

// ValidateAPIKey validates the Anthropic API key
func (s *AIChallengeService) ValidateAPIKey(ctx context.Context) error {
	return s.anthropicClient.ValidateAPIKey(ctx)
}

// GenerateCategoryResult represents the result of category generation
type GenerateCategoryResult struct {
	Categories    []models.Category `json:"categories,omitempty"`
	GeneratedJSON string            `json:"generated_json,omitempty"`
	Success       bool              `json:"success"`
	Error         string            `json:"error,omitempty"`
}

// GenerateCategories generates new category ideas using AI
func (s *AIChallengeService) GenerateCategories(
	ctx context.Context,
	count int,
) (*GenerateCategoryResult, error) {
	// Get existing categories to avoid duplicates
	existingCategories, _ := s.categoryRepo.GetAll(ctx, nil)
	existingNames := []string{}
	for _, cat := range existingCategories {
		existingNames = append(existingNames, fmt.Sprintf("- %s", cat.Name))
	}

	// Build prompt
	prompt := s.promptBuilder.BuildCategoryGenerationPrompt(existingNames, count)
	systemPrompt := s.promptBuilder.GetCategorySystemPrompt()

	// Generate with AI
	response, err := s.anthropicClient.GenerateChallenge(ctx, prompt, systemPrompt)
	if err != nil {
		return &GenerateCategoryResult{
			Success: false,
			Error:   fmt.Sprintf("AI generation failed: %v", err),
		}, nil
	}

	// Clean and parse JSON response
	cleanedJSON := ai.CleanJSONResponse(response)

	var generatedResponse ai.GeneratedCategoriesResponse
	if err := json.Unmarshal([]byte(cleanedJSON), &generatedResponse); err != nil {
		return &GenerateCategoryResult{
			Success:       false,
			Error:         fmt.Sprintf("Failed to parse AI response: %v", err),
			GeneratedJSON: response,
		}, nil
	}

	// Convert to category models
	categories := []models.Category{}
	for _, gen := range generatedResponse.Categories {
		desc := gen.Description
		cat := models.Category{
			Name:           gen.Name,
			Slug:           gen.Slug,
			Description:    &desc,
			IconType:       gen.IconType,
			ColorPrimary:   gen.ColorPrimary,
			ColorSecondary: gen.ColorSecondary,
			IsActive:       true,
			SortOrder:      len(existingCategories) + len(categories) + 1,
		}
		categories = append(categories, cat)
	}

	return &GenerateCategoryResult{
		Categories:    categories,
		GeneratedJSON: cleanedJSON,
		Success:       true,
	}, nil
}

// GenerateAndSaveCategories generates and saves new categories to database
func (s *AIChallengeService) GenerateAndSaveCategories(
	ctx context.Context,
	count int,
) (*GenerateCategoryResult, error) {
	result, err := s.GenerateCategories(ctx, count)
	if err != nil {
		return nil, err
	}

	if !result.Success {
		return result, nil
	}

	// Save each category to database
	savedCategories := []models.Category{}
	for _, cat := range result.Categories {
		catCopy := cat
		if err := s.categoryRepo.Create(ctx, &catCopy); err != nil {
			// Log error but continue with others
			continue
		}
		savedCategories = append(savedCategories, catCopy)
	}

	result.Categories = savedCategories
	return result, nil
}
