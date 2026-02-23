package main

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/handler"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	_ "github.com/joho/godotenv/autoload"
)

func main() {
	ai.InitGeminiClient(context.Background())

	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Use(middleware.Timeout(60 * time.Second))
	r.Use(middleware.Compress(5))
	r.Use(middleware.Heartbeat("/ping"))

	r.Route("/api", func(r chi.Router) {
		r.Post("/ingredients", handler.ExtractIngredients)
		r.Post("/generate-recipe", handler.GenerateRecipe)
	})

	fmt.Println("HTTP server listening on :8080")
	http.ListenAndServe(":8080", r)
}
