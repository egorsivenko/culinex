package handler

import (
	"encoding/json"
	"io"
	"log"
	"mime"
	"net/http"

	"github.com/dustin/go-humanize"
	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/go-chi/chi/v5/middleware"
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

	requestID := middleware.GetReqID(r.Context())
	log.Printf("[%s] Extracting ingredients from image: file_name=%q mime_type=%q file_size=%s",
		requestID,
		header.Filename,
		mimeType,
		humanize.Bytes(uint64(fileSize)),
	)

	resp, err := ai.ExtractIngredients(r.Context(), data, mimeType)
	if err != nil {
		log.Printf("[%s] Error extracting ingredients: %v", requestID, err)
		http.Error(w, "Failed to extract ingredients", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}
