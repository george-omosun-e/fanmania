package ai

import (
	"fmt"
	"strings"
)

// ChallengePromptBuilder builds prompts for challenge generation
type ChallengePromptBuilder struct{}

// NewChallengePromptBuilder creates a new prompt builder
func NewChallengePromptBuilder() *ChallengePromptBuilder {
	return &ChallengePromptBuilder{}
}

// GetSystemPrompt returns the base system prompt for challenge generation
func (b *ChallengePromptBuilder) GetSystemPrompt() string {
	return `You are an expert challenge creator for Fanmania, a skill-based gamification platform focused on African pop culture.

Your role is to generate engaging, culturally relevant, and legally compliant challenges that test users' knowledge.

CRITICAL RULES:
1. NO celebrity endorsements or suggestions they use/recommend products
2. NO claims about gambling, winnings, or prizes
3. NO medical/health claims about products or people
4. NO false statements about public figures
5. FOCUS on cultural knowledge, historical facts, and artistic appreciation
6. Questions must be factual and verifiable
7. Avoid controversial topics (politics, religion, violence)
8. Keep content family-friendly (suitable for ages 13+)

OUTPUT FORMAT:
Respond ONLY with valid JSON in this exact structure:
{
  "title": "Challenge title (max 100 chars)",
  "description": "Brief description (max 200 chars)",
  "question": "The actual question",
  "options": [
    {"id": "a", "text": "Option A"},
    {"id": "b", "text": "Option B"},
    {"id": "c", "text": "Option C"},
    {"id": "d", "text": "Option D"}
  ],
  "correct_answer": "a",
  "explanation": "Why this answer is correct (optional)",
  "difficulty_justification": "Why this is difficulty X"
}`
}

// BuildMultipleChoicePrompt generates a prompt for multiple choice challenges
func (b *ChallengePromptBuilder) BuildMultipleChoicePrompt(
	categoryName string,
	categoryDescription string,
	difficultyTier int,
	existingChallenges []string,
) string {
	difficultyDesc := b.getDifficultyDescription(difficultyTier)
	
	prompt := fmt.Sprintf(`Generate a multiple-choice challenge for the category: "%s"
Category description: %s

Difficulty: Tier %d (%s)

Requirements:
- Create a factual question about %s
- Provide 4 options (A, B, C, D)
- Only ONE option should be correct
- Other options should be plausible but clearly wrong
- Question should test %s

`, categoryName, categoryDescription, difficultyTier, difficultyDesc, categoryName, difficultyDesc)

	if len(existingChallenges) > 0 {
		prompt += fmt.Sprintf(`DO NOT create questions similar to these existing ones:
%s

`, strings.Join(existingChallenges, "\n"))
	}

	prompt += `Remember:
- NO celebrity endorsements
- NO prize/gambling claims
- ONLY factual, verifiable information
- Family-friendly content

Respond ONLY with the JSON structure specified in your system prompt.`

	return prompt
}

// BuildTimelinePrompt generates a prompt for timeline/chronology challenges
func (b *ChallengePromptBuilder) BuildTimelinePrompt(
	categoryName string,
	categoryDescription string,
	difficultyTier int,
) string {
	difficultyDesc := b.getDifficultyDescription(difficultyTier)
	
	return fmt.Sprintf(`Generate a timeline challenge for: "%s"
Category: %s
Difficulty: Tier %d (%s)

Create a question asking users to arrange 4 events in chronological order.

Requirements:
- All events must be related to %s
- Events should span different time periods
- Events must be factual and verifiable
- Difficulty appropriate for %s

Output format:
{
  "title": "Challenge title",
  "description": "Description",
  "question": "Arrange these events in chronological order (earliest to latest)",
  "options": [
    {"id": "a", "text": "Event 1 (Year)"},
    {"id": "b", "text": "Event 2 (Year)"},
    {"id": "c", "text": "Event 3 (Year)"},
    {"id": "d", "text": "Event 4 (Year)"}
  ],
  "correct_answer": "b,a,d,c",
  "explanation": "Chronological order explanation",
  "difficulty_justification": "Why this difficulty"
}

Remember: NO celebrity endorsements, NO prize claims, ONLY factual information.`,
		categoryName, categoryDescription, difficultyTier, difficultyDesc,
		categoryName, difficultyDesc)
}

// BuildTrueFalsePrompt generates a prompt for true/false challenges
func (b *ChallengePromptBuilder) BuildTrueFalsePrompt(
	categoryName string,
	categoryDescription string,
	difficultyTier int,
) string {
	difficultyDesc := b.getDifficultyDescription(difficultyTier)
	
	return fmt.Sprintf(`Generate a true/false challenge for: "%s"
Category: %s
Difficulty: Tier %d (%s)

Create a statement that users must identify as true or false.

Requirements:
- Statement must be factual and verifiable
- Should test knowledge appropriate for %s
- Include a brief explanation

Output format:
{
  "title": "Challenge title",
  "description": "Description",
  "question": "The statement to verify",
  "options": [
    {"id": "a", "text": "True"},
    {"id": "b", "text": "False"}
  ],
  "correct_answer": "a",
  "explanation": "Why this is true/false",
  "difficulty_justification": "Why this difficulty"
}

Remember: NO celebrity endorsements, NO prize claims, ONLY factual information.`,
		categoryName, categoryDescription, difficultyTier, difficultyDesc, difficultyDesc)
}

// getDifficultyDescription returns a description for each difficulty tier
func (b *ChallengePromptBuilder) getDifficultyDescription(tier int) string {
	switch tier {
	case 1:
		return "Beginner - Basic knowledge, widely known facts"
	case 2:
		return "Intermediate - Requires some familiarity with the topic"
	case 3:
		return "Advanced - Deep knowledge, less commonly known facts"
	case 4:
		return "Expert - Requires extensive knowledge, obscure details"
	case 5:
		return "Master - Only true experts would know, very specific details"
	default:
		return "Medium difficulty"
	}
}

// ParseGeneratedChallenge parses the AI response into structured data
type GeneratedChallenge struct {
	Title                   string           `json:"title"`
	Description             string           `json:"description"`
	Question                string           `json:"question"`
	Options                 []ChallengeOption `json:"options"`
	CorrectAnswer           string           `json:"correct_answer"`
	Explanation             string           `json:"explanation"`
	DifficultyJustification string           `json:"difficulty_justification"`
}

type ChallengeOption struct {
	ID   string `json:"id"`
	Text string `json:"text"`
}

// CleanJSONResponse removes markdown code blocks from AI response
func CleanJSONResponse(response string) string {
	// Remove ```json and ``` markers
	cleaned := strings.TrimSpace(response)
	cleaned = strings.TrimPrefix(cleaned, "```json")
	cleaned = strings.TrimPrefix(cleaned, "```")
	cleaned = strings.TrimSuffix(cleaned, "```")
	return strings.TrimSpace(cleaned)
}
