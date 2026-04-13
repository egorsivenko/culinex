package db

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

var Pool *pgxpool.Pool

func InitDB(ctx context.Context, databaseURL string) {
	var err error
	Pool, err = pgxpool.New(ctx, databaseURL)
	if err != nil {
		log.Fatalf("Unable to create connection pool: %v", err)
	}

	if err := Pool.Ping(ctx); err != nil {
		Pool.Close()
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("Database connection established")
}
