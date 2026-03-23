package handler

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/go-chi/chi/v5/middleware"
)

type generateRecipeRequest struct {
	Ingredients []ai.RecipeIngredient `json:"ingredients"`
}

func GenerateRecipe(w http.ResponseWriter, r *http.Request) {
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
		log.Printf("[%s] Generating recipe from %d ingredients: %s",
			requestID,
			len(req.Ingredients),
			string(b),
		)
	}

	resp, err := ai.GenerateRecipe(r.Context(), req.Ingredients)
	if err != nil {
		http.Error(w, "Failed to generate recipe", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}
