package auth

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/egorsivenko/culinex/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type contextKey string

const authClaimsKey contextKey = "auth_claims"

func Middleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token, err := extractBearerToken(r.Header.Get("Authorization"))
			if err != nil {
				writeUnauthorized(w)
				return
			}

			claims, err := VerifyAccessToken(token)
			if err != nil {
				writeUnauthorized(w)
				return
			}

			ok, err := sessionExists(r.Context(), claims.SessionID, claims.UserID)
			if err != nil {
				http.Error(w, "Internal server error", http.StatusInternalServerError)
				return
			}
			if !ok {
				writeUnauthorized(w)
				return
			}

			next.ServeHTTP(w, r.WithContext(WithTokenClaims(r.Context(), claims)))
		})
	}
}

func WithTokenClaims(ctx context.Context, claims TokenClaims) context.Context {
	return context.WithValue(ctx, authClaimsKey, claims)
}

func TokenClaimsFromContext(ctx context.Context) (TokenClaims, bool) {
	claims, ok := ctx.Value(authClaimsKey).(TokenClaims)
	return claims, ok
}

func extractBearerToken(header string) (string, error) {
	if header == "" {
		return "", errors.New("authorization header is required")
	}

	scheme, token, found := strings.Cut(header, " ")
	if !found || !strings.EqualFold(scheme, "Bearer") || strings.TrimSpace(token) == "" {
		return "", errors.New("authorization header must be in bearer format")
	}

	return strings.TrimSpace(token), nil
}

func sessionExists(ctx context.Context, sessionID, userID uuid.UUID) (bool, error) {
	const query = `
		SELECT 1
		FROM user_sessions
		WHERE id = $1 AND user_id = $2
	`

	var exists int
	err := db.Pool.QueryRow(ctx, query, sessionID, userID).Scan(&exists)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}

	return true, nil
}

func writeUnauthorized(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	_, _ = w.Write([]byte(`{"error":{"code":"unauthorized","message":"Unauthorized"}}`))
}
