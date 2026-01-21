package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// AnthropicClient handles communication with Claude API
type AnthropicClient struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
	model      string
}

// NewAnthropicClient creates a new Anthropic API client
func NewAnthropicClient(apiKey string) *AnthropicClient {
	return &AnthropicClient{
		apiKey:  apiKey,
		baseURL: "https://api.anthropic.com/v1",
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
		model: "claude-sonnet-4-20250514", // Latest Claude Sonnet
	}
}

// Message represents a message in the conversation
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// CreateMessageRequest represents the request to Claude API
type CreateMessageRequest struct {
	Model       string    `json:"model"`
	MaxTokens   int       `json:"max_tokens"`
	Messages    []Message `json:"messages"`
	Temperature float64   `json:"temperature,omitempty"`
	System      string    `json:"system,omitempty"`
}

// ContentBlock represents a content block in Claude's response
type ContentBlock struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// CreateMessageResponse represents Claude API response
type CreateMessageResponse struct {
	ID      string         `json:"id"`
	Type    string         `json:"type"`
	Role    string         `json:"role"`
	Content []ContentBlock `json:"content"`
	Model   string         `json:"model"`
	Usage   struct {
		InputTokens  int `json:"input_tokens"`
		OutputTokens int `json:"output_tokens"`
	} `json:"usage"`
}

// GenerateChallenge generates a challenge using Claude
func (c *AnthropicClient) GenerateChallenge(
	ctx context.Context,
	prompt string,
	systemPrompt string,
) (string, error) {
	reqBody := CreateMessageRequest{
		Model:       c.model,
		MaxTokens:   2000,
		Temperature: 0.7,
		System:      systemPrompt,
		Messages: []Message{
			{
				Role:    "user",
				Content: prompt,
			},
		},
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(
		ctx,
		"POST",
		c.baseURL+"/messages",
		bytes.NewBuffer(jsonData),
	)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", c.apiKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(body))
	}

	var response CreateMessageResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if len(response.Content) == 0 {
		return "", fmt.Errorf("no content in response")
	}

	return response.Content[0].Text, nil
}

// ValidateAPIKey checks if the API key is valid
func (c *AnthropicClient) ValidateAPIKey(ctx context.Context) error {
	_, err := c.GenerateChallenge(
		ctx,
		"Say 'API key is valid' if you can read this.",
		"You are a test assistant.",
	)
	return err
}
