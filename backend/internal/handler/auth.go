package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/egorsivenko/culinex/internal/auth"
	"github.com/egorsivenko/culinex/internal/respond"
)

type authRequest struct {
	FullName string `json:"full_name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type refreshTokenRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type authUserResponse struct {
	ID       string `json:"id"`
	FullName string `json:"full_name"`
	Email    string `json:"email"`
}

type authResponse struct {
	User                  authUserResponse `json:"user"`
	AccessToken           string           `json:"access_token"`
	AccessTokenExpiresAt  string           `json:"access_token_expires_at"`
	RefreshToken          string           `json:"refresh_token"`
	RefreshTokenExpiresAt string           `json:"refresh_token_expires_at"`
}

func SignUp(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	result, err := auth.SignUp(r.Context(), auth.SignUpInput{
		FullName: req.FullName,
		Email:    req.Email,
		Password: req.Password,
	})
	if err != nil {
		writeAuthServiceError(w, err)
		return
	}

	respond.JSON(w, http.StatusCreated, buildAuthResponse(result))
}

func Login(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	result, err := auth.Login(r.Context(), auth.LoginInput{
		Email:    req.Email,
		Password: req.Password,
	})
	if err != nil {
		writeAuthServiceError(w, err)
		return
	}

	respond.JSON(w, http.StatusOK, buildAuthResponse(result))
}

func CheckEmail(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	if err := auth.CheckEmailAvailable(r.Context(), auth.CheckEmailInput{
		Email: req.Email,
	}); err != nil {
		writeAuthServiceError(w, err)
		return
	}

	respond.NoContent(w)
}

func Refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	result, err := auth.Refresh(r.Context(), auth.RefreshInput{
		RefreshToken: req.RefreshToken,
	})
	if err != nil {
		writeAuthServiceError(w, err)
		return
	}

	respond.JSON(w, http.StatusOK, buildAuthResponse(result))
}

func Logout(w http.ResponseWriter, r *http.Request) {
	var req refreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond.Error(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	if err := auth.Logout(r.Context(), auth.LogoutInput{
		RefreshToken: req.RefreshToken,
	}); err != nil {
		writeAuthServiceError(w, err)
		return
	}

	respond.NoContent(w)
}

func DeleteAccount(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.RequireUserID(w, r)
	if !ok {
		return
	}

	if err := auth.DeleteAccount(r.Context(), auth.DeleteAccountInput{
		UserID: userID,
	}); err != nil {
		writeAuthServiceError(w, err)
		return
	}

	respond.NoContent(w)
}

func buildAuthResponse(result auth.AuthResult) authResponse {
	return authResponse{
		User: authUserResponse{
			ID:       result.User.ID.String(),
			FullName: result.User.FullName,
			Email:    result.Email,
		},
		AccessToken:           result.TokenPair.AccessToken,
		AccessTokenExpiresAt:  result.TokenPair.AccessTokenExpiresAt.UTC().Format(http.TimeFormat),
		RefreshToken:          result.TokenPair.RefreshToken,
		RefreshTokenExpiresAt: result.TokenPair.RefreshTokenExpiresAt.UTC().Format(http.TimeFormat),
	}
}

func writeAuthServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, auth.ErrValidation):
		respond.Error(w, http.StatusBadRequest, "validation_failed", err.Error())
	case errors.Is(err, auth.ErrEmailAlreadyInUse):
		respond.Error(w, http.StatusConflict, "email_already_in_use", "Email is already in use")
	case errors.Is(err, auth.ErrInvalidCredentials):
		respond.Error(w, http.StatusUnauthorized, "invalid_credentials", "Invalid email or password")
	case errors.Is(err, auth.ErrSessionExpired):
		respond.Error(w, http.StatusUnauthorized, "session_expired", "Session expired or invalid")
	default:
		respond.Error(w, http.StatusInternalServerError, "server_error", "Internal server error")
	}
}
