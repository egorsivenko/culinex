package recipes

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

var ErrNotFound = errors.New("recipe not found")

type SavedRecipe struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	DishName           string
	DishDescription    string
	Difficulty         string
	CookingTimeMinutes int
	Ingredients        []ai.RecipeIngredient
	Steps              []string
	Macros             ai.Macros
	Images             []RecipeImage
	IsFavorite         bool
	CreatedAt          time.Time
}

type RecipeImage struct {
	ID              string `json:"id"`
	ImageURL        string `json:"image_url"`
	ThumbnailURL    string `json:"thumbnail_url"`
	PexelsURL       string `json:"pexels_url"`
	Photographer    string `json:"photographer"`
	PhotographerURL string `json:"photographer_url"`
	Alt             string `json:"alt"`
	AvgColor        string `json:"avg_color"`
}

type RecipeSummary struct {
	ID                 uuid.UUID
	DishName           string
	DishDescription    string
	Difficulty         string
	CookingTimeMinutes int
	IsFavorite         bool
	CreatedAt          time.Time
}

func SaveGenerated(ctx context.Context, userID uuid.UUID, recipe ai.RecipeResponse, images []RecipeImage) (SavedRecipe, error) {
	if images == nil {
		images = []RecipeImage{}
	}

	ingredientsJSON, err := json.Marshal(recipe.Ingredients)
	if err != nil {
		return SavedRecipe{}, fmt.Errorf("marshal recipe ingredients: %w", err)
	}

	stepsJSON, err := json.Marshal(recipe.Steps)
	if err != nil {
		return SavedRecipe{}, fmt.Errorf("marshal recipe steps: %w", err)
	}

	macrosJSON, err := json.Marshal(recipe.Macros)
	if err != nil {
		return SavedRecipe{}, fmt.Errorf("marshal recipe macros: %w", err)
	}

	imagesJSON, err := json.Marshal(images)
	if err != nil {
		return SavedRecipe{}, fmt.Errorf("marshal recipe images: %w", err)
	}

	const query = `
		INSERT INTO recipes (
			user_id,
			dish_name,
			dish_description,
			difficulty,
			cooking_time_minutes,
			ingredients,
			steps,
			macros,
			images
		)
		VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb, $8::jsonb, $9::jsonb)
		RETURNING id, user_id, dish_name, dish_description, difficulty,
			cooking_time_minutes, ingredients, steps, macros, images, is_favorite, created_at
	`

	return scanSavedRecipe(db.Pool.QueryRow(
		ctx,
		query,
		userID,
		recipe.DishName,
		recipe.DishDescription,
		recipe.Difficulty,
		recipe.CookingTimeMinutes,
		string(ingredientsJSON),
		string(stepsJSON),
		string(macrosJSON),
		string(imagesJSON),
	))
}

func ListByUser(ctx context.Context, userID uuid.UUID) ([]RecipeSummary, error) {
	const query = `
		SELECT id, dish_name, dish_description, difficulty, cooking_time_minutes,
			is_favorite, created_at
		FROM recipes
		WHERE user_id = $1
		ORDER BY is_favorite DESC, created_at DESC
	`

	rows, err := db.Pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	summaries := make([]RecipeSummary, 0)
	for rows.Next() {
		var summary RecipeSummary
		if err := rows.Scan(
			&summary.ID,
			&summary.DishName,
			&summary.DishDescription,
			&summary.Difficulty,
			&summary.CookingTimeMinutes,
			&summary.IsFavorite,
			&summary.CreatedAt,
		); err != nil {
			return nil, err
		}
		summaries = append(summaries, summary)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return summaries, nil
}

func GetByID(ctx context.Context, userID, recipeID uuid.UUID) (SavedRecipe, error) {
	const query = `
		SELECT id, user_id, dish_name, dish_description, difficulty,
			cooking_time_minutes, ingredients, steps, macros, images, is_favorite, created_at
		FROM recipes
		WHERE id = $1 AND user_id = $2
	`

	recipe, err := scanSavedRecipe(db.Pool.QueryRow(ctx, query, recipeID, userID))
	if errors.Is(err, pgx.ErrNoRows) {
		return SavedRecipe{}, ErrNotFound
	}
	if err != nil {
		return SavedRecipe{}, err
	}

	return recipe, nil
}

func SetFavorite(ctx context.Context, userID, recipeID uuid.UUID, isFavorite bool) error {
	const query = `
		UPDATE recipes
		SET is_favorite = $3
		WHERE id = $1 AND user_id = $2
	`

	result, err := db.Pool.Exec(ctx, query, recipeID, userID, isFavorite)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func DeleteByID(ctx context.Context, userID, recipeID uuid.UUID) error {
	const query = `
		DELETE FROM recipes
		WHERE id = $1 AND user_id = $2
	`

	result, err := db.Pool.Exec(ctx, query, recipeID, userID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}

	return nil
}

func DeleteAllByUser(ctx context.Context, userID uuid.UUID) error {
	const query = `
		DELETE FROM recipes
		WHERE user_id = $1
	`

	_, err := db.Pool.Exec(ctx, query, userID)
	return err
}

type recipeRow interface {
	Scan(dest ...any) error
}

func scanSavedRecipe(row recipeRow) (SavedRecipe, error) {
	var recipe SavedRecipe
	var ingredientsJSON []byte
	var stepsJSON []byte
	var macrosJSON []byte
	var imagesJSON []byte

	if err := row.Scan(
		&recipe.ID,
		&recipe.UserID,
		&recipe.DishName,
		&recipe.DishDescription,
		&recipe.Difficulty,
		&recipe.CookingTimeMinutes,
		&ingredientsJSON,
		&stepsJSON,
		&macrosJSON,
		&imagesJSON,
		&recipe.IsFavorite,
		&recipe.CreatedAt,
	); err != nil {
		return SavedRecipe{}, err
	}

	if err := json.Unmarshal(ingredientsJSON, &recipe.Ingredients); err != nil {
		return SavedRecipe{}, fmt.Errorf("decode recipe ingredients: %w", err)
	}
	if err := json.Unmarshal(stepsJSON, &recipe.Steps); err != nil {
		return SavedRecipe{}, fmt.Errorf("decode recipe steps: %w", err)
	}
	if err := json.Unmarshal(macrosJSON, &recipe.Macros); err != nil {
		return SavedRecipe{}, fmt.Errorf("decode recipe macros: %w", err)
	}
	if len(imagesJSON) == 0 {
		recipe.Images = []RecipeImage{}
	} else if err := json.Unmarshal(imagesJSON, &recipe.Images); err != nil {
		return SavedRecipe{}, fmt.Errorf("decode recipe images: %w", err)
	}

	return recipe, nil
}
