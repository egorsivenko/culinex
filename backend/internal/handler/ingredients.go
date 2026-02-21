package handler

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"

	"github.com/egorsivenko/culinex/internal/ai"
)

func ExtractIngredients(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		http.Error(w, "Error parsing request body", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "Error retrieving file from request", http.StatusBadRequest)
		return
	}
	defer file.Close()

	mimeType := header.Header.Get("Content-Type")
	if !strings.HasPrefix(mimeType, "image/") {
		http.Error(w, "Invalid Content-Type header", http.StatusUnsupportedMediaType)
		return
	}

	data, err := io.ReadAll(file)
	if err != nil {
		http.Error(w, "Failed to read uploaded file", http.StatusBadRequest)
		return
	}
	if len(data) == 0 {
		http.Error(w, "Uploaded file is empty", http.StatusBadRequest)
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
