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
	"github.com/egorsivenko/culinex/internal/respond"
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
	CollectionID       *string               `json:"collection_id"`
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
	ID                 string  `json:"id"`
	CollectionID       *string `json:"collection_id"`
	DishName           string  `json:"dish_name"`
	DishDescription    string  `json:"dish_description"`
	Difficulty         string  `json:"difficulty"`
	CookingTimeMinutes int     `json:"cooking_time_minutes"`
	IsFavorite         bool    `json:"is_favorite"`
	CreatedAt          string  `json:"created_at"`
}

type recipeListResponse struct {
	Recipes []recipeSummaryResponse `json:"recipes"`
}

type recipeCollectionResponse struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

type recipeCollectionListResponse struct {
	Collections []recipeCollectionResponse `json:"collections"`
}

type setRecipeFavoriteRequest struct {
	IsFavorite *bool `json:"is_favorite"`
}

type saveRecipeCollectionRequest struct {
	Name string `json:"name"`
}

type setRecipeCollectionRequest struct {
	CollectionID *string `json:"collection_id"`
}

func GenerateRecipe(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	var req generateRecipeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}
	if len(req.Ingredients) < ai.MinRecipeIngredientCount {
		respond.Error(w, http.StatusUnprocessableEntity, "invalid_ingredients", "Not enough ingredients were provided")
		return
	}
	if !ai.IsValidRecipeStyle(req.RecipeStyle) {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe style is invalid")
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
		respond.Error(w, http.StatusInternalServerError, "server_error", "Failed to generate recipe")
		return
	}
	if ai.IsEmptyRecipeResponse(resp) {
		log.Printf("[%s] Recipe generation refused: no usable ingredients", requestID)
		respond.Error(w, http.StatusUnprocessableEntity, "invalid_ingredients", "No usable ingredients were provided")
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
		respond.Error(w, http.StatusInternalServerError, "server_error", "Failed to save recipe")
		return
	}

	w.Header().Set("Content-Language", tag)
	respond.JSON(w, http.StatusOK, buildRecipeResponse(savedRecipe))
}

func ListRecipes(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	summaries, err := recipes.ListByUser(r.Context(), claims.UserID)
	if err != nil {
		log.Printf("[%s] Error listing recipes: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	items := make([]recipeSummaryResponse, 0, len(summaries))
	for _, summary := range summaries {
		items = append(items, recipeSummaryResponse{
			ID:                 summary.ID.String(),
			CollectionID:       formatOptionalUUID(summary.CollectionID),
			DishName:           summary.DishName,
			DishDescription:    summary.DishDescription,
			Difficulty:         summary.Difficulty,
			CookingTimeMinutes: summary.CookingTimeMinutes,
			IsFavorite:         summary.IsFavorite,
			CreatedAt:          formatRecipeTime(summary.CreatedAt),
		})
	}

	respond.JSON(w, http.StatusOK, recipeListResponse{Recipes: items})
}

func ListRecipeCollections(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	collections, err := recipes.ListCollectionsByUser(r.Context(), claims.UserID)
	if err != nil {
		log.Printf("[%s] Error listing recipe collections: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	items := make([]recipeCollectionResponse, 0, len(collections))
	for _, collection := range collections {
		items = append(items, buildRecipeCollectionResponse(collection))
	}

	respond.JSON(w, http.StatusOK, recipeCollectionListResponse{Collections: items})
}

func CreateRecipeCollection(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	var req saveRecipeCollectionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	collection, err := recipes.CreateCollection(r.Context(), claims.UserID, req.Name)
	if err != nil {
		writeRecipeCollectionError(w, err)
		return
	}

	respond.JSON(w, http.StatusCreated, buildRecipeCollectionResponse(collection))
}

func RenameRecipeCollection(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	collectionID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe collection id is invalid")
		return
	}

	var req saveRecipeCollectionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	collection, err := recipes.RenameCollection(r.Context(), claims.UserID, collectionID, req.Name)
	if err != nil {
		writeRecipeCollectionError(w, err)
		return
	}

	respond.JSON(w, http.StatusOK, buildRecipeCollectionResponse(collection))
}

func DeleteRecipeCollection(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	collectionID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe collection id is invalid")
		return
	}

	if err := recipes.DeleteCollection(r.Context(), claims.UserID, collectionID); err != nil {
		writeRecipeCollectionError(w, err)
		return
	}

	respond.NoContent(w)
}

func GetRecipe(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	recipe, err := recipes.GetByID(r.Context(), claims.UserID, recipeID)
	if errors.Is(err, recipes.ErrNotFound) {
		respond.Error(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	}
	if err != nil {
		log.Printf("[%s] Error retrieving recipe: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	respond.JSON(w, http.StatusOK, buildRecipeResponse(recipe))
}

func DeleteRecipe(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	if err := recipes.DeleteByID(r.Context(), claims.UserID, recipeID); errors.Is(err, recipes.ErrNotFound) {
		respond.Error(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	} else if err != nil {
		log.Printf("[%s] Error deleting recipe: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	respond.NoContent(w)
}

func DeleteAllRecipes(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	if err := recipes.DeleteAllByUser(r.Context(), claims.UserID); err != nil {
		log.Printf("[%s] Error deleting all recipes: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	respond.NoContent(w)
}

func SetRecipeFavorite(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	var req setRecipeFavoriteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}
	if req.IsFavorite == nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "is_favorite is required")
		return
	}

	if err := recipes.SetFavorite(r.Context(), claims.UserID, recipeID, *req.IsFavorite); errors.Is(err, recipes.ErrNotFound) {
		respond.Error(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	} else if err != nil {
		log.Printf("[%s] Error updating recipe favorite: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	respond.NoContent(w)
}

func SetRecipeCollection(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		respond.Error(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	recipeID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe id is invalid")
		return
	}

	var req setRecipeCollectionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	var collectionID *uuid.UUID
	if req.CollectionID != nil {
		parsedCollectionID, err := uuid.Parse(*req.CollectionID)
		if err != nil {
			respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe collection id is invalid")
			return
		}
		collectionID = &parsedCollectionID
	}

	if err := recipes.SetCollection(r.Context(), claims.UserID, recipeID, collectionID); errors.Is(err, recipes.ErrNotFound) {
		respond.Error(w, http.StatusNotFound, "not_found", "Recipe not found")
		return
	} else if errors.Is(err, recipes.ErrCollectionNotFound) {
		respond.Error(w, http.StatusNotFound, "not_found", "Recipe collection not found")
		return
	} else if err != nil {
		log.Printf("[%s] Error updating recipe collection: %v", middleware.GetReqID(r.Context()), err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
		return
	}

	respond.NoContent(w)
}

func buildRecipeResponse(recipe recipes.SavedRecipe) recipeResponse {
	images := recipe.Images
	if images == nil {
		images = []recipes.RecipeImage{}
	}

	return recipeResponse{
		ID:                 recipe.ID.String(),
		CollectionID:       formatOptionalUUID(recipe.CollectionID),
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

func buildRecipeCollectionResponse(collection recipes.RecipeCollection) recipeCollectionResponse {
	return recipeCollectionResponse{
		ID:        collection.ID.String(),
		Name:      collection.Name,
		CreatedAt: formatRecipeTime(collection.CreatedAt),
		UpdatedAt: formatRecipeTime(collection.UpdatedAt),
	}
}

func formatOptionalUUID(value *uuid.UUID) *string {
	if value == nil {
		return nil
	}
	formatted := value.String()
	return &formatted
}

func formatRecipeTime(value time.Time) string {
	return value.UTC().Format(time.RFC3339)
}

func writeRecipeCollectionError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, recipes.ErrInvalidCollectionName):
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Recipe collection name is invalid")
	case errors.Is(err, recipes.ErrDuplicateCollectionName):
		respond.Error(w, http.StatusConflict, "collection_name_already_exists", "Recipe collection name already exists")
	case errors.Is(err, recipes.ErrCollectionNotFound):
		respond.Error(w, http.StatusNotFound, "not_found", "Recipe collection not found")
	default:
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
	}
}
