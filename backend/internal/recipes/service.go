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
	CreatedAt          time.Time
}

type RecipeSummary struct {
	ID                 uuid.UUID
	DishName           string
	DishDescription    string
	Difficulty         string
	CookingTimeMinutes int
	CreatedAt          time.Time
}

func SaveGenerated(ctx context.Context, userID uuid.UUID, recipe ai.RecipeResponse) (SavedRecipe, error) {
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

	const query = `
		INSERT INTO recipes (
			user_id,
			dish_name,
			dish_description,
			difficulty,
			cooking_time_minutes,
			ingredients,
			steps,
			macros
		)
		VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb, $8::jsonb)
		RETURNING id, user_id, dish_name, dish_description, difficulty,
			cooking_time_minutes, ingredients, steps, macros, created_at
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
	))
}

func ListByUser(ctx context.Context, userID uuid.UUID) ([]RecipeSummary, error) {
	const query = `
		SELECT id, dish_name, dish_description, difficulty, cooking_time_minutes, created_at
		FROM recipes
		WHERE user_id = $1
		ORDER BY created_at DESC
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
			cooking_time_minutes, ingredients, steps, macros, created_at
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

type recipeRow interface {
	Scan(dest ...any) error
}

func scanSavedRecipe(row recipeRow) (SavedRecipe, error) {
	var recipe SavedRecipe
	var ingredientsJSON []byte
	var stepsJSON []byte
	var macrosJSON []byte

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

	return recipe, nil
}
