package auth

import (
	"time"

	"github.com/google/uuid"
)

type IdentityProvider string

const (
	ProviderLocal  IdentityProvider = "local"
	ProviderGoogle IdentityProvider = "google"
	ProviderApple  IdentityProvider = "apple"
)

type TokenType string

const (
	TokenTypeAccess  TokenType = "access"
	TokenTypeRefresh TokenType = "refresh"
)

type User struct {
	ID        uuid.UUID
	FullName  string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type UserIdentity struct {
	ID            uuid.UUID
	UserID        uuid.UUID
	Provider      IdentityProvider
	ProviderUID   *string
	Email         *string
	EmailVerified bool
	PasswordHash  *string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type UserSession struct {
	ID               uuid.UUID
	UserID           uuid.UUID
	RefreshTokenHash string
	CreatedAt        time.Time
	ExpiresAt        time.Time
	LastUsedAt       *time.Time
}

type TokenPair struct {
	AccessToken           string
	AccessTokenExpiresAt  time.Time
	RefreshToken          string
	RefreshTokenExpiresAt time.Time
}

type TokenClaims struct {
	TokenID   uuid.UUID
	UserID    uuid.UUID
	SessionID uuid.UUID
	Type      TokenType
	IssuedAt  time.Time
	ExpiresAt time.Time
}
