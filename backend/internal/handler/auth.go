package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/egorsivenko/culinex/internal/auth"
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

type errorResponse struct {
	Error apiError `json:"error"`
}

type apiError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func SignUp(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
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

	writeJSON(w, http.StatusCreated, buildAuthResponse(result))
}

func Login(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
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

	writeJSON(w, http.StatusOK, buildAuthResponse(result))
}

func CheckEmail(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	if err := auth.CheckEmailAvailable(r.Context(), auth.CheckEmailInput{
		Email: req.Email,
	}); err != nil {
		writeAuthServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func Refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	result, err := auth.Refresh(r.Context(), auth.RefreshInput{
		RefreshToken: req.RefreshToken,
	})
	if err != nil {
		writeAuthServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, buildAuthResponse(result))
}

func Logout(w http.ResponseWriter, r *http.Request) {
	var req refreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "validation_failed", "Invalid JSON body")
		return
	}

	if err := auth.Logout(r.Context(), auth.LogoutInput{
		RefreshToken: req.RefreshToken,
	}); err != nil {
		writeAuthServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func DeleteAccount(w http.ResponseWriter, r *http.Request) {
	claims, ok := auth.TokenClaimsFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "unauthorized", "Unauthorized")
		return
	}

	if err := auth.DeleteAccount(r.Context(), auth.DeleteAccountInput{
		UserID: claims.UserID,
	}); err != nil {
		writeAuthServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
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
		writeError(w, http.StatusBadRequest, "validation_failed", err.Error())
	case errors.Is(err, auth.ErrEmailAlreadyInUse):
		writeError(w, http.StatusConflict, "email_already_in_use", "Email is already in use")
	case errors.Is(err, auth.ErrInvalidCredentials):
		writeError(w, http.StatusUnauthorized, "invalid_credentials", "Invalid email or password")
	case errors.Is(err, auth.ErrSessionExpired):
		writeError(w, http.StatusUnauthorized, "session_expired", "Session expired or invalid")
	default:
		writeError(w, http.StatusInternalServerError, "server_error", "Internal server error")
	}
}

func writeError(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, errorResponse{
		Error: apiError{
			Code:    code,
			Message: message,
		},
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
