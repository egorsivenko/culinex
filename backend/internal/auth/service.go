package auth

import (
	"context"
	"errors"
	"fmt"
	"net/mail"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

const (
	minPasswordLength = 8
	maxPasswordLength = 72
)

var (
	ErrValidation         = errors.New("auth: validation failed")
	ErrEmailAlreadyInUse  = errors.New("auth: email already in use")
	ErrInvalidCredentials = errors.New("auth: invalid credentials")
)

type Service struct {
	db *pgxpool.Pool
}

type SignUpInput struct {
	FullName string
	Email    string
	Password string
}

type LoginInput struct {
	Email    string
	Password string
}

type AuthResult struct {
	User      User
	Email     string
	TokenPair TokenPair
}

func NewService(db *pgxpool.Pool) *Service {
	return &Service{db: db}
}

func (s *Service) SignUp(ctx context.Context, input SignUpInput) (AuthResult, error) {
	normalizedInput, err := normalizeSignUpInput(input)
	if err != nil {
		return AuthResult{}, err
	}

	passwordHash, err := HashPassword(normalizedInput.Password)
	if err != nil {
		return AuthResult{}, fmt.Errorf("hash password: %w", err)
	}

	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return AuthResult{}, fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	user := User{
		ID:       uuid.New(),
		FullName: normalizedInput.FullName,
	}
	sessionID := uuid.New()
	tokenPair, err := IssueTokenPair(user.ID, sessionID)
	if err != nil {
		return AuthResult{}, fmt.Errorf("issue token pair: %w", err)
	}

	const createUserQuery = `
		INSERT INTO users (id, full_name)
		VALUES ($1, $2)
		RETURNING created_at, updated_at
	`
	if err := tx.QueryRow(ctx, createUserQuery, user.ID, user.FullName).Scan(&user.CreatedAt, &user.UpdatedAt); err != nil {
		return AuthResult{}, fmt.Errorf("insert user: %w", err)
	}

	const createIdentityQuery = `
		INSERT INTO user_identities (
			id,
			user_id,
			provider,
			email,
			email_verified,
			password_hash
		)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	identityID := uuid.New()
	if _, err := tx.Exec(
		ctx,
		createIdentityQuery,
		identityID,
		user.ID,
		ProviderLocal,
		normalizedInput.Email,
		false,
		passwordHash,
	); err != nil {
		if isUniqueViolation(err) {
			return AuthResult{}, ErrEmailAlreadyInUse
		}
		return AuthResult{}, fmt.Errorf("insert user identity: %w", err)
	}

	if err := insertSession(ctx, tx, sessionID, user.ID, tokenPair); err != nil {
		return AuthResult{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AuthResult{}, fmt.Errorf("commit transaction: %w", err)
	}

	return AuthResult{
		User:      user,
		Email:     normalizedInput.Email,
		TokenPair: tokenPair,
	}, nil
}

func (s *Service) Login(ctx context.Context, input LoginInput) (AuthResult, error) {
	normalizedInput, err := normalizeLoginInput(input)
	if err != nil {
		return AuthResult{}, err
	}

	const loginQuery = `
		SELECT
			u.id,
			u.full_name,
			u.created_at,
			u.updated_at,
			ui.password_hash
		FROM user_identities ui
		JOIN users u ON u.id = ui.user_id
		WHERE ui.provider = $1 AND ui.email = $2
	`
	var result AuthResult
	var passwordHash string
	if err := s.db.QueryRow(ctx, loginQuery, ProviderLocal, normalizedInput.Email).Scan(
		&result.User.ID,
		&result.User.FullName,
		&result.User.CreatedAt,
		&result.User.UpdatedAt,
		&passwordHash,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return AuthResult{}, ErrInvalidCredentials
		}
		return AuthResult{}, fmt.Errorf("select local identity: %w", err)
	}

	if err := VerifyPassword(passwordHash, normalizedInput.Password); err != nil {
		if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
			return AuthResult{}, ErrInvalidCredentials
		}
		return AuthResult{}, fmt.Errorf("verify password: %w", err)
	}

	sessionID := uuid.New()
	tokenPair, err := IssueTokenPair(result.User.ID, sessionID)
	if err != nil {
		return AuthResult{}, fmt.Errorf("issue token pair: %w", err)
	}

	tx, err := s.db.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return AuthResult{}, fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	if err := insertSession(ctx, tx, sessionID, result.User.ID, tokenPair); err != nil {
		return AuthResult{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AuthResult{}, fmt.Errorf("commit transaction: %w", err)
	}

	result.Email = normalizedInput.Email
	result.TokenPair = tokenPair
	return result, nil
}

func insertSession(ctx context.Context, tx pgx.Tx, sessionID, userID uuid.UUID, tokenPair TokenPair) error {
	const createSessionQuery = `
		INSERT INTO user_sessions (
			id,
			user_id,
			refresh_token_hash,
			expires_at
		)
		VALUES ($1, $2, $3, $4)
	`
	if _, err := tx.Exec(
		ctx,
		createSessionQuery,
		sessionID,
		userID,
		HashToken(tokenPair.RefreshToken),
		tokenPair.RefreshTokenExpiresAt,
	); err != nil {
		return fmt.Errorf("insert user session: %w", err)
	}
	return nil
}

func normalizeSignUpInput(input SignUpInput) (SignUpInput, error) {
	input.FullName = strings.TrimSpace(input.FullName)
	input.Email = normalizeEmail(input.Email)

	switch {
	case input.FullName == "":
		return SignUpInput{}, fmt.Errorf("%w: full_name is required", ErrValidation)
	case !isValidEmail(input.Email):
		return SignUpInput{}, fmt.Errorf("%w: email is invalid", ErrValidation)
	case len(input.Password) < minPasswordLength:
		return SignUpInput{}, fmt.Errorf("%w: password must be at least %d characters", ErrValidation, minPasswordLength)
	case len(input.Password) > maxPasswordLength:
		return SignUpInput{}, fmt.Errorf("%w: password must be at most %d characters", ErrValidation, maxPasswordLength)
	default:
		return input, nil
	}
}

func normalizeLoginInput(input LoginInput) (LoginInput, error) {
	input.Email = normalizeEmail(input.Email)

	switch {
	case !isValidEmail(input.Email):
		return LoginInput{}, fmt.Errorf("%w: email is invalid", ErrValidation)
	case input.Password == "":
		return LoginInput{}, fmt.Errorf("%w: password is required", ErrValidation)
	default:
		return input, nil
	}
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func isValidEmail(email string) bool {
	parsed, err := mail.ParseAddress(email)
	return err == nil && parsed.Address == email
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
