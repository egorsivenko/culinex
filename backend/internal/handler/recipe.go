package handler

import (
	"encoding/json"
	"net/http"

	"github.com/egorsivenko/culinex/internal/ai"
)

type generateRecipeRequest struct {
	Ingredients []ai.RecipeIngredient `json:"ingredients"`
}

func GenerateRecipe(w http.ResponseWriter, r *http.Request) {
	var req generateRecipeRequest
	dec := json.NewDecoder(r.Body)

	if err := dec.Decode(&req); err != nil {
		http.Error(w, "Invalid JSON body", http.StatusBadRequest)
		return
	}
	if len(req.Ingredients) == 0 {
		http.Error(w, "Ingredients list is empty", http.StatusBadRequest)
		return
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
