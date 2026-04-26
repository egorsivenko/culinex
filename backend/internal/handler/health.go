package handler

import (
	"context"
	"log"
	"time"

	"github.com/egorsivenko/culinex/internal/db"
	health "github.com/hellofresh/health-go/v5"
)

func Health() *health.Health {
	h, err := health.New(
		health.WithComponent(health.Component{
			Name:    "culinex-api",
			Version: "v1.0",
		}),
		health.WithSystemInfo(),
		health.WithChecks(health.Config{
			Name:      "postgres",
			Timeout:   time.Second * 2,
			SkipOnErr: false,
			Check: func(ctx context.Context) error {
				return db.Pool.Ping(ctx)
			},
		}),
	)
	if err != nil {
		log.Fatalf("Failed to configure health handler: %v", err)
	}
	return h
}
