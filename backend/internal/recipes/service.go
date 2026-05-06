package recipes

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

const MaxRecipeCollectionNameLength = 50

var (
	ErrNotFound                = errors.New("recipe not found")
	ErrCollectionNotFound      = errors.New("recipe collection not found")
	ErrInvalidCollectionName   = errors.New("recipe collection name is invalid")
	ErrDuplicateCollectionName = errors.New("recipe collection name already exists")
)

type SavedRecipe struct {
	ID                 uuid.UUID
	UserID             uuid.UUID
	CollectionID       *uuid.UUID
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
	CollectionID       *uuid.UUID
	DishName           string
	DishDescription    string
	Difficulty         string
	CookingTimeMinutes int
	IsFavorite         bool
	CreatedAt          time.Time
}

type RecipeCollection struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Name      string
	CreatedAt time.Time
	UpdatedAt time.Time
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
		RETURNING id, user_id, COALESCE(collection_id::text, ''), dish_name, dish_description, difficulty,
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
		SELECT id, COALESCE(collection_id::text, ''), dish_name, dish_description, difficulty, cooking_time_minutes,
			is_favorite, created_at
		FROM recipes
		WHERE user_id = $1
		ORDER BY collection_id NULLS LAST, is_favorite DESC, created_at DESC
	`

	rows, err := db.Pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	summaries := make([]RecipeSummary, 0)
	for rows.Next() {
		var summary RecipeSummary
		var collectionID string
		if err := rows.Scan(
			&summary.ID,
			&collectionID,
			&summary.DishName,
			&summary.DishDescription,
			&summary.Difficulty,
			&summary.CookingTimeMinutes,
			&summary.IsFavorite,
			&summary.CreatedAt,
		); err != nil {
			return nil, err
		}
		if collectionID != "" {
			parsedCollectionID, err := uuid.Parse(collectionID)
			if err != nil {
				return nil, fmt.Errorf("parse recipe collection id: %w", err)
			}
			summary.CollectionID = &parsedCollectionID
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
		SELECT id, user_id, COALESCE(collection_id::text, ''), dish_name, dish_description, difficulty,
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

func ListCollectionsByUser(ctx context.Context, userID uuid.UUID) ([]RecipeCollection, error) {
	const query = `
		SELECT id, user_id, name, created_at, updated_at
		FROM recipe_collections
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := db.Pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	collections := make([]RecipeCollection, 0)
	for rows.Next() {
		var collection RecipeCollection
		if err := rows.Scan(
			&collection.ID,
			&collection.UserID,
			&collection.Name,
			&collection.CreatedAt,
			&collection.UpdatedAt,
		); err != nil {
			return nil, err
		}
		collections = append(collections, collection)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	return collections, nil
}

func CreateCollection(ctx context.Context, userID uuid.UUID, name string) (RecipeCollection, error) {
	normalizedName, err := normalizeCollectionName(name)
	if err != nil {
		return RecipeCollection{}, err
	}

	const query = `
		INSERT INTO recipe_collections (user_id, name)
		VALUES ($1, $2)
		RETURNING id, user_id, name, created_at, updated_at
	`

	collection, err := scanRecipeCollection(db.Pool.QueryRow(ctx, query, userID, normalizedName))
	if isUniqueViolation(err) {
		return RecipeCollection{}, ErrDuplicateCollectionName
	}
	if err != nil {
		return RecipeCollection{}, err
	}

	return collection, nil
}

func RenameCollection(ctx context.Context, userID, collectionID uuid.UUID, name string) (RecipeCollection, error) {
	normalizedName, err := normalizeCollectionName(name)
	if err != nil {
		return RecipeCollection{}, err
	}

	const query = `
		UPDATE recipe_collections
		SET name = $3
		WHERE id = $1 AND user_id = $2
		RETURNING id, user_id, name, created_at, updated_at
	`

	collection, err := scanRecipeCollection(db.Pool.QueryRow(ctx, query, collectionID, userID, normalizedName))
	if errors.Is(err, pgx.ErrNoRows) {
		return RecipeCollection{}, ErrCollectionNotFound
	}
	if isUniqueViolation(err) {
		return RecipeCollection{}, ErrDuplicateCollectionName
	}
	if err != nil {
		return RecipeCollection{}, err
	}

	return collection, nil
}

func DeleteCollection(ctx context.Context, userID, collectionID uuid.UUID) error {
	const query = `
		DELETE FROM recipe_collections
		WHERE id = $1 AND user_id = $2
	`

	result, err := db.Pool.Exec(ctx, query, collectionID, userID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrCollectionNotFound
	}

	return nil
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

func SetCollection(ctx context.Context, userID, recipeID uuid.UUID, collectionID *uuid.UUID) error {
	if collectionID == nil {
		const query = `
			UPDATE recipes
			SET collection_id = NULL
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

	const query = `
		UPDATE recipes
		SET collection_id = $3
		WHERE id = $1 AND user_id = $2
			AND EXISTS (
				SELECT 1
				FROM recipe_collections
				WHERE id = $3 AND user_id = $2
			)
	`

	result, err := db.Pool.Exec(ctx, query, recipeID, userID, *collectionID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		if _, err := GetByID(ctx, userID, recipeID); errors.Is(err, ErrNotFound) {
			return ErrNotFound
		} else if err != nil {
			return err
		}
		return ErrCollectionNotFound
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
	tx, err := db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, `
		DELETE FROM recipes
		WHERE user_id = $1
	`, userID); err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		DELETE FROM recipe_collections
		WHERE user_id = $1
	`, userID); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

type recipeRow interface {
	Scan(dest ...any) error
}

func scanSavedRecipe(row recipeRow) (SavedRecipe, error) {
	var recipe SavedRecipe
	var collectionID string
	var ingredientsJSON []byte
	var stepsJSON []byte
	var macrosJSON []byte
	var imagesJSON []byte

	if err := row.Scan(
		&recipe.ID,
		&recipe.UserID,
		&collectionID,
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

	if collectionID != "" {
		parsedCollectionID, err := uuid.Parse(collectionID)
		if err != nil {
			return SavedRecipe{}, fmt.Errorf("parse recipe collection id: %w", err)
		}
		recipe.CollectionID = &parsedCollectionID
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

func scanRecipeCollection(row recipeRow) (RecipeCollection, error) {
	var collection RecipeCollection
	if err := row.Scan(
		&collection.ID,
		&collection.UserID,
		&collection.Name,
		&collection.CreatedAt,
		&collection.UpdatedAt,
	); err != nil {
		return RecipeCollection{}, err
	}

	return collection, nil
}

func normalizeCollectionName(name string) (string, error) {
	normalizedName := strings.TrimSpace(name)
	if normalizedName == "" ||
		utf8.RuneCountInString(normalizedName) > MaxRecipeCollectionNameLength {
		return "", ErrInvalidCollectionName
	}

	return normalizedName, nil
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
