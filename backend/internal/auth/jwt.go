package auth

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

const tokenSigningMethod = "HS256"

var (
	ErrInvalidTokenType = errors.New("auth: invalid token type")
	ErrEmptyUserID      = errors.New("auth: user id is required")
	ErrEmptySessionID   = errors.New("auth: session id is required")
)

type jwtClaims struct {
	SessionID string    `json:"sid"`
	TokenType TokenType `json:"typ"`
	jwt.RegisteredClaims
}

func IssueTokenPair(userID, sessionID uuid.UUID) (TokenPair, error) {
	if userID == uuid.Nil {
		return TokenPair{}, ErrEmptyUserID
	}
	if sessionID == uuid.Nil {
		return TokenPair{}, ErrEmptySessionID
	}

	now := time.Now().UTC()
	accessExpiresAt := now.Add(Cfg.AccessTokenTTL)
	refreshExpiresAt := now.Add(Cfg.RefreshTokenTTL)

	accessToken, err := signToken(TokenTypeAccess, userID, sessionID, now, accessExpiresAt, []byte(Cfg.AccessTokenSecret))
	if err != nil {
		return TokenPair{}, err
	}

	refreshToken, err := signToken(TokenTypeRefresh, userID, sessionID, now, refreshExpiresAt, []byte(Cfg.RefreshTokenSecret))
	if err != nil {
		return TokenPair{}, err
	}

	return TokenPair{
		AccessToken:           accessToken,
		AccessTokenExpiresAt:  accessExpiresAt,
		RefreshToken:          refreshToken,
		RefreshTokenExpiresAt: refreshExpiresAt,
	}, nil
}

func VerifyAccessToken(token string) (TokenClaims, error) {
	return parseToken(token, TokenTypeAccess, []byte(Cfg.AccessTokenSecret))
}

func VerifyRefreshToken(token string) (TokenClaims, error) {
	return parseToken(token, TokenTypeRefresh, []byte(Cfg.RefreshTokenSecret))
}

func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func signToken(tokenType TokenType, userID, sessionID uuid.UUID, issuedAt, expiresAt time.Time, secret []byte) (string, error) {
	claims := jwtClaims{
		SessionID: sessionID.String(),
		TokenType: tokenType,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.NewString(),
			Issuer:    Cfg.Issuer,
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(issuedAt),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	token.Header["typ"] = "JWT"

	signedToken, err := token.SignedString(secret)
	if err != nil {
		return "", fmt.Errorf("sign %s token: %w", tokenType, err)
	}
	return signedToken, nil
}

func parseToken(token string, expectedType TokenType, secret []byte) (TokenClaims, error) {
	parser := jwt.NewParser(
		jwt.WithIssuer(Cfg.Issuer),
		jwt.WithValidMethods([]string{tokenSigningMethod}),
		jwt.WithIssuedAt(),
		jwt.WithExpirationRequired(),
	)

	var claims jwtClaims
	_, err := parser.ParseWithClaims(token, &claims, func(_ *jwt.Token) (any, error) { return secret, nil })
	if err != nil {
		return TokenClaims{}, err
	}
	if claims.TokenType != expectedType {
		return TokenClaims{}, ErrInvalidTokenType
	}

	tokenID, err := uuid.Parse(claims.ID)
	if err != nil {
		return TokenClaims{}, fmt.Errorf("parse token id: %w", err)
	}
	userID, err := uuid.Parse(claims.Subject)
	if err != nil {
		return TokenClaims{}, fmt.Errorf("parse user id: %w", err)
	}
	sessionID, err := uuid.Parse(claims.SessionID)
	if err != nil {
		return TokenClaims{}, fmt.Errorf("parse session id: %w", err)
	}

	return TokenClaims{
		TokenID:   tokenID,
		UserID:    userID,
		SessionID: sessionID,
		Type:      claims.TokenType,
		IssuedAt:  claims.IssuedAt.Time,
		ExpiresAt: claims.ExpiresAt.Time,
	}, nil
}
