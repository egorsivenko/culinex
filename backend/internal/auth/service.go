package auth

import (
	"context"
	"errors"
	"fmt"
	"net/mail"
	"strings"

	"github.com/egorsivenko/culinex/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
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
	ErrSessionExpired     = errors.New("auth: session expired")
)

type SignUpInput struct {
	FullName string
	Email    string
	Password string
}

type LoginInput struct {
	Email    string
	Password string
}

type CheckEmailInput struct {
	Email string
}

type RefreshInput struct {
	RefreshToken string
}

type LogoutInput struct {
	RefreshToken string
}

type DeleteAccountInput struct {
	UserID uuid.UUID
}

type AuthResult struct {
	User      User
	Email     string
	TokenPair TokenPair
}

func CheckEmailAvailable(ctx context.Context, input CheckEmailInput) error {
	normalizedInput, err := normalizeCheckEmailInput(input)
	if err != nil {
		return err
	}

	const checkEmailQuery = `
		SELECT 1
		FROM user_identities
		WHERE provider = $1 AND email = $2
	`

	var marker int
	if err := db.Pool.QueryRow(ctx, checkEmailQuery, ProviderLocal, normalizedInput.Email).Scan(&marker); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		return fmt.Errorf("check local identity email: %w", err)
	}

	return ErrEmailAlreadyInUse
}

func SignUp(ctx context.Context, input SignUpInput) (AuthResult, error) {
	normalizedInput, err := normalizeSignUpInput(input)
	if err != nil {
		return AuthResult{}, err
	}

	passwordHash, err := HashPassword(normalizedInput.Password)
	if err != nil {
		return AuthResult{}, fmt.Errorf("hash password: %w", err)
	}

	tx, err := db.Pool.BeginTx(ctx, pgx.TxOptions{})
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

func Login(ctx context.Context, input LoginInput) (AuthResult, error) {
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
	if err := db.Pool.QueryRow(ctx, loginQuery, ProviderLocal, normalizedInput.Email).Scan(
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

	tx, err := db.Pool.BeginTx(ctx, pgx.TxOptions{})
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

func Refresh(ctx context.Context, input RefreshInput) (AuthResult, error) {
	refreshToken := strings.TrimSpace(input.RefreshToken)
	if refreshToken == "" {
		return AuthResult{}, fmt.Errorf("%w: refresh_token is required", ErrValidation)
	}

	claims, err := VerifyRefreshToken(refreshToken)
	if err != nil {
		return AuthResult{}, ErrSessionExpired
	}

	tx, err := db.Pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return AuthResult{}, fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	const selectSessionQuery = `
		SELECT user_id
		FROM user_sessions
		WHERE id = $1 AND refresh_token_hash = $2
		FOR UPDATE
	`
	var sessionUserID uuid.UUID
	if err := tx.QueryRow(
		ctx,
		selectSessionQuery,
		claims.SessionID,
		HashToken(refreshToken),
	).Scan(&sessionUserID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return AuthResult{}, ErrSessionExpired
		}
		return AuthResult{}, fmt.Errorf("select user session: %w", err)
	}
	if sessionUserID != claims.UserID {
		return AuthResult{}, ErrSessionExpired
	}

	user, email, err := getUserByID(ctx, tx, claims.UserID)
	if err != nil {
		return AuthResult{}, err
	}

	tokenPair, err := IssueTokenPair(claims.UserID, claims.SessionID)
	if err != nil {
		return AuthResult{}, fmt.Errorf("issue token pair: %w", err)
	}

	const rotateSessionQuery = `
		UPDATE user_sessions
		SET
			refresh_token_hash = $1,
			expires_at = $2,
			last_used_at = NOW()
		WHERE id = $3
	`
	if _, err := tx.Exec(
		ctx,
		rotateSessionQuery,
		HashToken(tokenPair.RefreshToken),
		tokenPair.RefreshTokenExpiresAt,
		claims.SessionID,
	); err != nil {
		return AuthResult{}, fmt.Errorf("rotate user session: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return AuthResult{}, fmt.Errorf("commit transaction: %w", err)
	}

	return AuthResult{
		User:      user,
		Email:     email,
		TokenPair: tokenPair,
	}, nil
}

func Logout(ctx context.Context, input LogoutInput) error {
	refreshToken := strings.TrimSpace(input.RefreshToken)
	if refreshToken == "" {
		return fmt.Errorf("%w: refresh_token is required", ErrValidation)
	}

	claims, err := VerifyRefreshToken(refreshToken)
	if err != nil {
		return ErrSessionExpired
	}

	const deleteSessionQuery = `
		DELETE FROM user_sessions
		WHERE id = $1 AND user_id = $2 AND refresh_token_hash = $3
	`
	commandTag, err := db.Pool.Exec(
		ctx,
		deleteSessionQuery,
		claims.SessionID,
		claims.UserID,
		HashToken(refreshToken),
	)
	if err != nil {
		return fmt.Errorf("delete user session: %w", err)
	}
	if commandTag.RowsAffected() == 0 {
		return ErrSessionExpired
	}

	return nil
}

func DeleteAccount(ctx context.Context, input DeleteAccountInput) error {
	if input.UserID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrValidation)
	}

	const deleteUserQuery = `
		DELETE FROM users
		WHERE id = $1
	`
	commandTag, err := db.Pool.Exec(ctx, deleteUserQuery, input.UserID)
	if err != nil {
		return fmt.Errorf("delete user: %w", err)
	}
	if commandTag.RowsAffected() == 0 {
		return ErrSessionExpired
	}

	return nil
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

func getUserByID(ctx context.Context, tx pgx.Tx, userID uuid.UUID) (User, string, error) {
	const getUserQuery = `
		SELECT
			u.id,
			u.full_name,
			u.created_at,
			u.updated_at,
			ui.email
		FROM users u
		LEFT JOIN user_identities ui
			ON ui.user_id = u.id AND ui.provider = $2
		WHERE u.id = $1
	`

	var user User
	var email *string
	if err := tx.QueryRow(ctx, getUserQuery, userID, ProviderLocal).Scan(
		&user.ID,
		&user.FullName,
		&user.CreatedAt,
		&user.UpdatedAt,
		&email,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return User{}, "", ErrSessionExpired
		}
		return User{}, "", fmt.Errorf("select user: %w", err)
	}

	if email == nil {
		return user, "", nil
	}

	return user, *email, nil
}

func normalizeSignUpInput(input SignUpInput) (SignUpInput, error) {
	input.FullName = normalizeFullName(input.FullName)
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

func normalizeCheckEmailInput(input CheckEmailInput) (CheckEmailInput, error) {
	input.Email = normalizeEmail(input.Email)

	switch {
	case !isValidEmail(input.Email):
		return CheckEmailInput{}, fmt.Errorf("%w: email is invalid", ErrValidation)
	default:
		return input, nil
	}
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func normalizeFullName(fullName string) string {
	return strings.Join(strings.Fields(fullName), " ")
}

func isValidEmail(email string) bool {
	parsed, err := mail.ParseAddress(email)
	return err == nil && parsed.Address == email
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
