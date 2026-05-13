package handler

import (
	"io"
	"log"
	"mime"
	"net/http"

	"github.com/dustin/go-humanize"
	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/respond"
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
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Error parsing request body")
		return
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Error retrieving file from request")
		return
	}
	defer file.Close()

	mimeType, _, err := mime.ParseMediaType(header.Header.Get("Content-Type"))
	if err != nil {
		respond.Error(w, http.StatusUnsupportedMediaType, "unsupported_media_type", "Invalid Content-Type header")
		return
	}

	if _, ok := supportedImageFormats[mimeType]; !ok {
		respond.Error(w, http.StatusUnsupportedMediaType, "unsupported_media_type", "Unsupported image format")
		return
	}

	fileSize := header.Size
	if fileSize == 0 {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Uploaded file is empty")
		return
	}
	if fileSize >= maxImageSize {
		respond.Error(w, http.StatusRequestEntityTooLarge, "payload_too_large", "Uploaded file is too large")
		return
	}

	data, err := io.ReadAll(file)
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "server_error", "Failed to read uploaded file")
		return
	}

	requestID := middleware.GetReqID(r.Context())
	log.Printf("[%s] Extracting ingredients from image: file_name=%q mime_type=%q file_size=%s",
		requestID,
		header.Filename,
		mimeType,
		humanize.Bytes(uint64(fileSize)),
	)

	tag, lang := resolveLanguage(r)
	resp, err := ai.ExtractIngredients(r.Context(), data, mimeType, lang)
	if err != nil {
		log.Printf("[%s] Error extracting ingredients: %v", requestID, err)
		respond.Error(w, http.StatusInternalServerError, "server_error", "Failed to extract ingredients")
		return
	}

	w.Header().Set("Content-Language", tag)
	respond.JSON(w, http.StatusOK, resp)
}
