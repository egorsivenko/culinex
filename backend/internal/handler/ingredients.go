package handler

import (
	"encoding/json"
	"io"
	"mime"
	"net/http"

	"github.com/egorsivenko/culinex/internal/ai"
)

const (
	maxImageSize = 18 << 20 // 18 MiB
	maxMemory    = 8 << 20  // 8 MiB
)

var supportedImageFormats = map[string]struct{}{
	"image/png":  {},
	"image/jpeg": {},
	"image/webp": {},
	"image/heic": {},
	"image/heif": {},
}

type generateRecipeRequest struct {
	Ingredients []ai.RecipeIngredient `json:"ingredients"`
}

func ExtractIngredients(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(maxMemory); err != nil {
		http.Error(w, "Error parsing request body", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Error retrieving file from request", http.StatusBadRequest)
		return
	}
	defer file.Close()

	mimeType, _, err := mime.ParseMediaType(header.Header.Get("Content-Type"))
	if err != nil {
		http.Error(w, "Invalid Content-Type header", http.StatusUnsupportedMediaType)
		return
	}

	if _, ok := supportedImageFormats[mimeType]; !ok {
		http.Error(w, "Unsupported image format", http.StatusUnsupportedMediaType)
		return
	}

	fileSize := header.Size
	if fileSize == 0 {
		http.Error(w, "Uploaded file is empty", http.StatusBadRequest)
		return
	}
	if fileSize >= maxImageSize {
		http.Error(w, "Uploaded file is too large", http.StatusRequestEntityTooLarge)
		return
	}

	data, err := io.ReadAll(file)
	if err != nil {
		http.Error(w, "Failed to read uploaded file", http.StatusInternalServerError)
		return
	}

	resp, err := ai.ExtractIngredients(r.Context(), data, mimeType)
	if err != nil {
		http.Error(w, "Failed to extract ingredients", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
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
