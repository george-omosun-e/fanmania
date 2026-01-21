package postgres

import (
	"context"
	"fmt"

	"github.com/fanmania/backend/internal/domain/errors"
	"github.com/fanmania/backend/internal/domain/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// CategoryRepository handles category database operations
type CategoryRepository struct {
	db *DB
}

// NewCategoryRepository creates a new CategoryRepository
func NewCategoryRepository(db *DB) *CategoryRepository {
	return &CategoryRepository{db: db}
}

// GetAll retrieves all active categories
func (r *CategoryRepository) GetAll(ctx context.Context, userID *uuid.UUID) ([]models.Category, error) {
	query := `
		SELECT c.id, c.name, c.slug, c.description, c.icon_type, 
		       c.color_primary, c.color_secondary, c.is_active, 
		       c.created_at, c.sort_order
		FROM categories c
		WHERE c.is_active = true
		ORDER BY c.sort_order ASC, c.name ASC
	`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query categories: %w", err)
	}
	defer rows.Close()

	var categories []models.Category
	for rows.Next() {
		var cat models.Category
		err := rows.Scan(
			&cat.ID,
			&cat.Name,
			&cat.Slug,
			&cat.Description,
			&cat.IconType,
			&cat.ColorPrimary,
			&cat.ColorSecondary,
			&cat.IsActive,
			&cat.CreatedAt,
			&cat.SortOrder,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan category: %w", err)
		}

		// If user ID provided, fetch user stats for this category
		if userID != nil {
			stats, err := r.GetUserStats(ctx, cat.ID, *userID)
			if err == nil {
				cat.UserStats = stats
			}
		}

		categories = append(categories, cat)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating categories: %w", err)
	}

	return categories, nil
}

// GetByID retrieves a category by ID
func (r *CategoryRepository) GetByID(ctx context.Context, id uuid.UUID, userID *uuid.UUID) (*models.Category, error) {
	query := `
		SELECT id, name, slug, description, icon_type, 
		       color_primary, color_secondary, is_active, 
		       created_at, sort_order
		FROM categories
		WHERE id = $1 AND is_active = true
	`

	var cat models.Category
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&cat.ID,
		&cat.Name,
		&cat.Slug,
		&cat.Description,
		&cat.IconType,
		&cat.ColorPrimary,
		&cat.ColorSecondary,
		&cat.IsActive,
		&cat.CreatedAt,
		&cat.SortOrder,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrCategoryNotFound
		}
		return nil, fmt.Errorf("failed to get category: %w", err)
	}

	// If user ID provided, fetch user stats
	if userID != nil {
		stats, err := r.GetUserStats(ctx, id, *userID)
		if err == nil {
			cat.UserStats = stats
		}
	}

	return &cat, nil
}

// GetBySlug retrieves a category by slug
func (r *CategoryRepository) GetBySlug(ctx context.Context, slug string) (*models.Category, error) {
	query := `
		SELECT id, name, slug, description, icon_type, 
		       color_primary, color_secondary, is_active, 
		       created_at, sort_order
		FROM categories
		WHERE slug = $1 AND is_active = true
	`

	var cat models.Category
	err := r.db.Pool.QueryRow(ctx, query, slug).Scan(
		&cat.ID,
		&cat.Name,
		&cat.Slug,
		&cat.Description,
		&cat.IconType,
		&cat.ColorPrimary,
		&cat.ColorSecondary,
		&cat.IsActive,
		&cat.CreatedAt,
		&cat.SortOrder,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, errors.ErrCategoryNotFound
		}
		return nil, fmt.Errorf("failed to get category: %w", err)
	}

	return &cat, nil
}

// GetUserStats retrieves user statistics for a specific category
func (r *CategoryRepository) GetUserStats(ctx context.Context, categoryID, userID uuid.UUID) (*models.CategoryUserStats, error) {
	query := `
		SELECT 
			COALESCE(points, 0) as points,
			rank,
			COALESCE(mastery_percentage, 0) as mastery_percentage,
			COALESCE(streak_days, 0) as streak_days
		FROM category_rankings
		WHERE category_id = $1 AND user_id = $2
	`

	var stats models.CategoryUserStats
	err := r.db.Pool.QueryRow(ctx, query, categoryID, userID).Scan(
		&stats.Points,
		&stats.Rank,
		&stats.MasteryPercentage,
		&stats.StreakDays,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			// Return zero stats if no ranking exists yet
			return &models.CategoryUserStats{
				Points:            0,
				Rank:              nil,
				MasteryPercentage: 0,
				StreakDays:        0,
			}, nil
		}
		return nil, fmt.Errorf("failed to get user stats: %w", err)
	}

	return &stats, nil
}

// Create creates a new category (admin function)
func (r *CategoryRepository) Create(ctx context.Context, category *models.Category) error {
	query := `
		INSERT INTO categories (name, slug, description, icon_type, color_primary, color_secondary, sort_order)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, is_active
	`

	err := r.db.Pool.QueryRow(
		ctx,
		query,
		category.Name,
		category.Slug,
		category.Description,
		category.IconType,
		category.ColorPrimary,
		category.ColorSecondary,
		category.SortOrder,
	).Scan(
		&category.ID,
		&category.CreatedAt,
		&category.IsActive,
	)

	if err != nil {
		return fmt.Errorf("failed to create category: %w", err)
	}

	return nil
}
