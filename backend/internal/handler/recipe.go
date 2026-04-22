package handler

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"time"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/auth"
	"github.com/egorsivenko/culinex/internal/recipes"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/google/uuid"
)

type generateRecipeRequest struct {
	Ingredients        []ai.RecipeIngredient `json:"ingredients"`
	AssumeBasicStaples bool                  `json:"assume_basic_staples"`
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
	CreatedAt          string                `json:"created_at"`
}

type recipeSummaryResponse struct {
	ID                 string `json:"id"`
	DishName           string `json:"dish_name"`
	DishDescription    string `json:"dish_description"`
	Difficulty         string `json:"difficulty"`
	CookingTimeMinutes int    `json:"cooking_time_minutes"`
	CreatedAt          string `json:"created_at"`
}

type recipeListResponse struct {
	Recipes []recipeSummaryResponse `json:"recipes"`
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
	if len(req.Ingredients) == 0 {
		http.Error(w, "Ingredients list is empty", http.StatusBadRequest)
		return
	}

	requestID := middleware.GetReqID(r.Context())
	if b, err := json.Marshal(req.Ingredients); err == nil {
		log.Printf("[%s] Generating recipe from %d ingredients (assume_basic_staples=%t): %s",
			requestID,
			len(req.Ingredients),
			req.AssumeBasicStaples,
			string(b),
		)
	}

	tag, lang := resolveLanguage(r)
	resp, err := ai.GenerateRecipe(r.Context(), req.Ingredients, req.AssumeBasicStaples, lang)
	if err != nil {
		log.Printf("[%s] Error generating recipe: %v", requestID, err)
		http.Error(w, "Failed to generate recipe", http.StatusInternalServerError)
		return
	}

	savedRecipe, err := recipes.SaveGenerated(r.Context(), claims.UserID, resp)
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

func buildRecipeResponse(recipe recipes.SavedRecipe) recipeResponse {
	return recipeResponse{
		ID:                 recipe.ID.String(),
		DishName:           recipe.DishName,
		DishDescription:    recipe.DishDescription,
		Difficulty:         recipe.Difficulty,
		CookingTimeMinutes: recipe.CookingTimeMinutes,
		Ingredients:        recipe.Ingredients,
		Steps:              recipe.Steps,
		Macros:             recipe.Macros,
		CreatedAt:          formatRecipeTime(recipe.CreatedAt),
	}
}

func formatRecipeTime(value time.Time) string {
	return value.UTC().Format(time.RFC3339)
}
