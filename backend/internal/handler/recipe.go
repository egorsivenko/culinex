package handler

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"time"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/auth"
	"github.com/egorsivenko/culinex/internal/pexels"
	"github.com/egorsivenko/culinex/internal/recipes"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/google/uuid"
)

type generateRecipeRequest struct {
	Ingredients        []ai.RecipeIngredient `json:"ingredients"`
	AssumeBasicStaples bool                  `json:"assume_basic_staples"`
	RecipeStyle        string                `json:"recipe_style"`
}

type recipeResponse struct {
	ID                 string                `json:"id"`
	DishName           string                `json:"dish_name"`
	DishDescription    string                `json:"dish_description"`
	Difficulty         string                `json:"difficulty"`
	CookingTimeMinutes int                   `json:"cooking_time_minutes"`
	Ingredients        []ai.RecipeIngredient `json:"ingredients"`
	Steps              []string              `json:"steps"`
	Macros             ai.Macros             `json:"macros"`
	Images             []recipes.RecipeImage `json:"images"`
	IsFavorite         bool                  `json:"is_favorite"`
	CreatedAt          string                `json:"created_at"`
}

type recipeSummaryResponse struct {
	ID                 string `json:"id"`
	DishName           string `json:"dish_name"`
	DishDescription    string `json:"dish_description"`
	Difficulty         string `json:"difficulty"`
	CookingTimeMinutes int    `json:"cooking_time_minutes"`
	IsFavorite         bool   `json:"is_favorite"`
	CreatedAt          string `json:"created_at"`
}

type recipeListResponse struct {
	Recipes []recipeSummaryResponse `json:"recipes"`
}

type setRecipeFavoriteRequest struct {
	IsFavorite *bool `json:"is_favorite"`
}

func GenerateRecipe(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	var req generateRecipeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON body", http.StatusBadRequest)
		return
	}
	if len(req.Ingredients) < ai.MinRecipeIngredientCount {
		writeError(w, http.StatusUnprocessableEntity, "invalid_ingredients", "Not enough ingredients were provided")
		return
	}
	if !ai.IsValidRecipeStyle(req.RecipeStyle) {
		writeError(w, http.StatusBadRequest, "validation_failed", "Recipe style is invalid")
		return
	}

	requestID := middleware.GetReqID(r.Context())
	if b, err := json.Marshal(req.Ingredients); err == nil {
		log.Printf("[%s] Generating recipe from %d ingredients (assume_basic_staples=%t, recipe_style=%s): %s",
			requestID,
			len(req.Ingredients),
			req.AssumeBasicStaples,
			req.RecipeStyle,
			string(b),
		)
	}

	tag, lang := resolveLanguage(r)
	resp, err := ai.GenerateRecipe(r.Context(), req.Ingredients, req.AssumeBasicStaples, req.RecipeStyle, lang)
	if err != nil {
		log.Printf("[%s] Error generating recipe: %v", requestID, err)
		http.Error(w, "Failed to generate recipe", http.StatusInternalServerError)
		return
	}
	if ai.IsEmptyRecipeResponse(resp) {
		log.Printf("[%s] Recipe generation refused: no usable ingredients", requestID)
		writeError(w, http.StatusUnprocessableEntity, "invalid_ingredients", "No usable ingredients were provided")
		return
	}

	images, err := pexels.SearchDishImages(r.Context(), resp.DishName, tag)
	if err != nil {
		log.Printf("[%s] Error fetching recipe images from Pexels: %v", requestID, err)
		images = nil
	}

	savedRecipe, err := recipes.SaveGenerated(r.Context(), claims.UserID, resp, images)
	if err != nil {
		log.Printf("[%s] Error saving generated recipe: %v", requestID, err)
		http.Error(w, "Failed to save recipe", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Language", tag)
	writeJSON(w, http.StatusOK, buildRecipeResponse(savedRecipe))
}

func ListRecipes(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	summaries, err := recipes.ListByUser(r.Context(), claims.UserID)
	if err != nil {
		log.Printf("[%s] Error listing recipes: %v", middleware.GetReqID(r.Context()), err)
		writeError(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	items := make([]recipeSummaryResponse, 0, len(summaries))
	for _, summary := range summaries {
		items = append(items, recipeSummaryResponse{
			ID:                 summary.ID.String(),
			DishName:           summary.DishName,
			DishDescription:    summary.DishDescription,
			Difficulty:         summary.Difficulty,
			CookingTimeMinutes: summary.CookingTimeMinutes,
			IsFavorite:         summary.IsFavorite,
			CreatedAt:          formatRecipeTime(summary.CreatedAt),
		})
	}

	writeJSON(w, http.StatusOK, recipeListResponse{Recipes: items})
}

func GetRecipe(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	recipe, err := recipes.GetByID(r.Context(), claims.UserID, recipeID)
	if errors.Is(err, recipes.ErrNotFound) {
		writeError(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	}
	if err != nil {
		log.Printf("[%s] Error retrieving recipe: %v", middleware.GetReqID(r.Context()), err)
		writeError(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	writeJSON(w, http.StatusOK, buildRecipeResponse(recipe))
}

func DeleteRecipe(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	if err := recipes.DeleteByID(r.Context(), claims.UserID, recipeID); errors.Is(err, recipes.ErrNotFound) {
		writeError(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	} else if err != nil {
		log.Printf("[%s] Error deleting recipe: %v", middleware.GetReqID(r.Context()), err)
		writeError(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func DeleteAllRecipes(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	if err := recipes.DeleteAllByUser(r.Context(), claims.UserID); err != nil {
		log.Printf("[%s] Error deleting all recipes: %v", middleware.GetReqID(r.Context()), err)
		writeError(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func SetRecipeFavorite(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	var req setRecipeFavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}
	if req.IsFavorite == nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "is_favorite is required")
		return
	}

	if err := recipes.SetFavorite(r.Context(), claims.UserID, recipeID, *req.IsFavorite); errors.Is(err, recipes.ErrNotFound) {
		writeError(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	} else if err != nil {
		log.Printf("[%s] Error updating recipe favorite: %v", middleware.GetReqID(r.Context()), err)
		writeError(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func buildRecipeResponse(recipe recipes.SavedRecipe) recipeResponse {
	images := recipe.Images
	if images == nil {
		images = []recipes.RecipeImage{}
	}

	return recipeResponse{
		ID:                 recipe.ID.String(),
		DishName:           recipe.DishName,
		DishDescription:    recipe.DishDescription,
		Difficulty:         recipe.Difficulty,
		CookingTimeMinutes: recipe.CookingTimeMinutes,
		Ingredients:        recipe.Ingredients,
		Steps:              recipe.Steps,
		Macros:             recipe.Macros,
		Images:             images,
		IsFavorite:         recipe.IsFavorite,
		CreatedAt:          formatRecipeTime(recipe.CreatedAt),
	}
}

func formatRecipeTime(value time.Time) string {
	return value.UTC().Format(time.RFC3339)
}
