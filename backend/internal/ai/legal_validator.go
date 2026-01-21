package ai

import (
	"fmt"
	"strings"
)

// LegalValidator validates generated challenges for legal compliance
type LegalValidator struct {
	// Forbidden patterns that violate legal/ethical rules
	forbiddenPatterns []string
	// Warning patterns that need human review
	warningPatterns []string
}

// NewLegalValidator creates a new legal validator
func NewLegalValidator() *LegalValidator {
	return &LegalValidator{
		forbiddenPatterns: []string{
			// Celebrity endorsements
			"uses", "recommends", "prefers", "loves", "favorite",
			"endorses", "sponsors", "partners with",
			
			// Gambling/prizes
			"win", "prize", "jackpot", "lottery", "sweepstakes",
			"cash prize", "money", "payout", "winnings",
			
			// Health claims
			"cures", "treats", "heals", "prevents disease",
			"medical benefit", "health benefit",
			
			// False claims
			"always", "never fails", "guaranteed", "proven fact",
			"scientifically proven" + " (without source)",
		},
		warningPatterns: []string{
			// Potentially controversial
			"political", "religion", "religious", "violence",
			"drug", "alcohol", "weapon", "crime",
			
			// Sensitive topics
			"death", "tragedy", "scandal", "controversy",
			"lawsuit", "legal issue", "arrested",
		},
	}
}

// ValidationResult represents the result of validation
type ValidationResult struct {
	IsValid   bool     `json:"is_valid"`
	Errors    []string `json:"errors,omitempty"`
	Warnings  []string `json:"warnings,omitempty"`
	Passed    bool     `json:"passed"`
	NeedsReview bool   `json:"needs_review"`
}

// ValidateChallenge validates a generated challenge
func (v *LegalValidator) ValidateChallenge(challenge *GeneratedChallenge) *ValidationResult {
	result := &ValidationResult{
		IsValid:  true,
		Passed:   true,
		Errors:   []string{},
		Warnings: []string{},
	}

	// Combine all text for validation
	fullText := strings.ToLower(fmt.Sprintf("%s %s %s",
		challenge.Title,
		challenge.Description,
		challenge.Question,
	))
	
	for _, opt := range challenge.Options {
		fullText += " " + strings.ToLower(opt.Text)
	}
	
	if challenge.Explanation != "" {
		fullText += " " + strings.ToLower(challenge.Explanation)
	}

	// Check forbidden patterns
	for _, pattern := range v.forbiddenPatterns {
		if strings.Contains(fullText, strings.ToLower(pattern)) {
			result.IsValid = false
			result.Passed = false
			result.Errors = append(result.Errors, 
				fmt.Sprintf("Contains forbidden pattern: '%s'", pattern))
		}
	}

	// Check warning patterns
	for _, pattern := range v.warningPatterns {
		if strings.Contains(fullText, strings.ToLower(pattern)) {
			result.NeedsReview = true
			result.Warnings = append(result.Warnings, 
				fmt.Sprintf("Contains sensitive content: '%s'", pattern))
		}
	}

	// Validate basic structure
	if len(challenge.Title) == 0 {
		result.IsValid = false
		result.Passed = false
		result.Errors = append(result.Errors, "Title is required")
	}

	if len(challenge.Question) == 0 {
		result.IsValid = false
		result.Passed = false
		result.Errors = append(result.Errors, "Question is required")
	}

	if len(challenge.Options) < 2 {
		result.IsValid = false
		result.Passed = false
		result.Errors = append(result.Errors, "At least 2 options required")
	}

	if challenge.CorrectAnswer == "" {
		result.IsValid = false
		result.Passed = false
		result.Errors = append(result.Errors, "Correct answer is required")
	}

	// Validate correct answer exists in options
	correctAnswerExists := false
	for _, opt := range challenge.Options {
		if opt.ID == challenge.CorrectAnswer {
			correctAnswerExists = true
			break
		}
	}
	
	if !correctAnswerExists {
		result.IsValid = false
		result.Passed = false
		result.Errors = append(result.Errors, 
			fmt.Sprintf("Correct answer '%s' not found in options", challenge.CorrectAnswer))
	}

	// Validate title length
	if len(challenge.Title) > 100 {
		result.Warnings = append(result.Warnings, "Title is longer than 100 characters")
	}

	// Validate description length
	if len(challenge.Description) > 200 {
		result.Warnings = append(result.Warnings, "Description is longer than 200 characters")
	}

	// Check for duplicate options
	optionTexts := make(map[string]bool)
	for _, opt := range challenge.Options {
		if optionTexts[strings.ToLower(opt.Text)] {
			result.Warnings = append(result.Warnings, 
				fmt.Sprintf("Duplicate option text: '%s'", opt.Text))
		}
		optionTexts[strings.ToLower(opt.Text)] = true
	}

	return result
}

// ValidateQuestionQuality checks if question meets quality standards
func (v *LegalValidator) ValidateQuestionQuality(challenge *GeneratedChallenge) []string {
	issues := []string{}

	// Check if question is too short
	if len(challenge.Question) < 10 {
		issues = append(issues, "Question is too short (minimum 10 characters)")
	}

	// Check if question is too long
	if len(challenge.Question) > 500 {
		issues = append(issues, "Question is too long (maximum 500 characters)")
	}

	// Check if all options are too similar in length
	if len(challenge.Options) >= 4 {
		lengths := []int{}
		for _, opt := range challenge.Options {
			lengths = append(lengths, len(opt.Text))
		}
		
		// Calculate variance
		allSame := true
		firstLen := lengths[0]
		for _, l := range lengths {
			if l != firstLen {
				allSame = false
				break
			}
		}
		
		if allSame {
			issues = append(issues, "All options have identical length (may indicate low quality)")
		}
	}

	// Check if question ends with question mark
	if !strings.HasSuffix(strings.TrimSpace(challenge.Question), "?") {
		issues = append(issues, "Question should end with a question mark")
	}

	return issues
}

// SanitizeChallenge removes or replaces problematic content
func (v *LegalValidator) SanitizeChallenge(challenge *GeneratedChallenge) *GeneratedChallenge {
	// Create a copy
	sanitized := *challenge

	// Trim whitespace
	sanitized.Title = strings.TrimSpace(sanitized.Title)
	sanitized.Description = strings.TrimSpace(sanitized.Description)
	sanitized.Question = strings.TrimSpace(sanitized.Question)
	sanitized.Explanation = strings.TrimSpace(sanitized.Explanation)

	// Sanitize options
	for i := range sanitized.Options {
		sanitized.Options[i].Text = strings.TrimSpace(sanitized.Options[i].Text)
	}

	// Truncate if too long
	if len(sanitized.Title) > 100 {
		sanitized.Title = sanitized.Title[:97] + "..."
	}

	if len(sanitized.Description) > 200 {
		sanitized.Description = sanitized.Description[:197] + "..."
	}

	return &sanitized
}
