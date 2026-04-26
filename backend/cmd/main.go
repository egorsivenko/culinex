package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/egorsivenko/culinex/internal/ai"
	"github.com/egorsivenko/culinex/internal/auth"
	"github.com/egorsivenko/culinex/internal/db"
	"github.com/egorsivenko/culinex/internal/handler"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	_ "github.com/joho/godotenv/autoload"
)

func main() {
	ctx := context.Background()
	databaseURL := os.Getenv("DATABASE_URL")

	db.InitDB(ctx, databaseURL)
	defer db.Pool.Close()
	db.RunMigrations(ctx, databaseURL)

	auth.LoadConfig()

	ai.InitGeminiClient(ctx)

	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Use(middleware.Timeout(60 * time.Second))
	r.Use(middleware.Compress(5))
	r.Use(middleware.Heartbeat("/ping"))

	r.Get("/health", handler.Health().HandlerFunc)

	r.Route("/api", func(r chi.Router) {
		r.Route("/auth", func(r chi.Router) {
			r.Post("/check-email", handler.CheckEmail)
			r.Post("/signup", handler.SignUp)
			r.Post("/login", handler.Login)
			r.Post("/refresh", handler.Refresh)
			r.Post("/logout", handler.Logout)
		})

		r.Group(func(r chi.Router) {
			r.Use(auth.Middleware())
			r.Post("/extract-ingredients", handler.ExtractIngredients)
			r.Post("/generate-recipe", handler.GenerateRecipe)
			r.Delete("/account", handler.DeleteAccount)

			r.Route("/recipes", func(r chi.Router) {
				r.Get("/", handler.ListRecipes)
				r.Get("/{id}", handler.GetRecipe)
				r.Patch("/{id}/favorite", handler.SetRecipeFavorite)
				r.Delete("/", handler.DeleteAllRecipes)
				r.Delete("/{id}", handler.DeleteRecipe)
			})
		})
	})

	srv := &http.Server{
		Addr:    ":8080",
		Handler: r,
	}

	go func() {
		log.Println("HTTP server listening on", srv.Addr)
		if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("HTTP server failed: %v", err)
		}
	}()

	shutdownSignal, stop := signal.NotifyContext(
		ctx,
		os.Interrupt,
		syscall.SIGTERM,
	)
	defer stop()

	<-shutdownSignal.Done()
	log.Println("Shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(ctx, time.Second*10)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("HTTP server forced to shutdown: %v", err)
	}
	log.Println("HTTP server stopped")
}
