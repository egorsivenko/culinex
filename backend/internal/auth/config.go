package auth

import (
	"fmt"
	"log"
	"os"
	"time"
)

const minTokenSecretLength = 32

var Cfg Config

type Config struct {
	AccessTokenSecret  string
	RefreshTokenSecret string
	AccessTokenTTL     time.Duration
	RefreshTokenTTL    time.Duration
	Issuer             string
}

func LoadConfig() {
	Cfg = Config{
		AccessTokenSecret:  os.Getenv("JWT_ACCESS_SECRET"),
		RefreshTokenSecret: os.Getenv("JWT_REFRESH_SECRET"),
		AccessTokenTTL:     parseDuration(os.Getenv("JWT_ACCESS_TTL")),
		RefreshTokenTTL:    parseDuration(os.Getenv("JWT_REFRESH_TTL")),
		Issuer:             os.Getenv("JWT_ISSUER"),
	}
	if err := Cfg.validate(); err != nil {
		log.Fatalf("Invalid JWT config: %v", err)
	}
}

func parseDuration(value string) time.Duration {
	duration, err := time.ParseDuration(value)
	if err != nil {
		log.Fatalf("Failed to parse duration: %v", err)
	}
	return duration
}

func (c Config) validate() error {
	switch {
	case len(c.AccessTokenSecret) < minTokenSecretLength:
		return fmt.Errorf("access token secret must be at least %d bytes", minTokenSecretLength)
	case len(c.RefreshTokenSecret) < minTokenSecretLength:
		return fmt.Errorf("refresh token secret must be at least %d bytes", minTokenSecretLength)
	case c.AccessTokenTTL <= 0:
		return fmt.Errorf("access token TTL must be greater than zero")
	case c.RefreshTokenTTL <= 0:
		return fmt.Errorf("refresh token TTL must be greater than zero")
	case c.Issuer == "":
		return fmt.Errorf("issuer must not be empty")
	default:
		return nil
	}
}
