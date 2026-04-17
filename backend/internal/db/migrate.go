package db

import (
	"context"
	"embed"
	"errors"
	"log"
	"strings"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
)

//go:embed migrations/*.sql
var fs embed.FS

func RunMigrations(ctx context.Context, databaseURL string) {
	dsn := strings.Replace(databaseURL, "postgres://", "pgx5://", 1)

	src, err := iofs.New(fs, "migrations")
	if err != nil {
		log.Fatalf("Unable to create migration source: %v", err)
	}

	m, err := migrate.NewWithSourceInstance("iofs", src, dsn)
	if err != nil {
		log.Fatalf("Unable to create migration instance: %v", err)
	}
	defer m.Close()

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		log.Fatalf("Failed to apply migrations: %v", err)
	}
	log.Println("Migrations applied successfully")
}
