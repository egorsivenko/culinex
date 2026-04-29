package pexels

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/egorsivenko/culinex/internal/recipes"
)

const (
	baseURL         = "https://api.pexels.com"
	searchPath      = "/v1/search"
	defaultPerPage  = 3
	requestTimeout  = 3 * time.Second
	maxResponseSize = 1 << 20
)

var client *Client

type Client struct {
	apiKey     string
	baseURL    *url.URL
	httpClient *http.Client
}

func InitClient() {
	apiKey := strings.TrimSpace(os.Getenv("PEXELS_API_KEY"))
	if apiKey == "" {
		log.Fatalf("PEXELS_API_KEY is not configured")
	}

	parsedBaseURL, _ := url.Parse(baseURL)
	client = &Client{
		apiKey:     apiKey,
		baseURL:    parsedBaseURL,
		httpClient: &http.Client{Timeout: requestTimeout},
	}
	log.Println("Pexels client initialized")
}

func SearchDishImages(ctx context.Context, dishName, languageTag string) ([]recipes.RecipeImage, error) {
	endpoint := client.baseURL.ResolveReference(&url.URL{Path: searchPath})
	params := endpoint.Query()
	params.Set("query", strings.TrimSpace(dishName))
	params.Set("orientation", "landscape")
	params.Set("size", "medium")
	params.Set("locale", pexelsLocale(languageTag))
	params.Set("per_page", strconv.Itoa(defaultPerPage))
	endpoint.RawQuery = params.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("build pexels request: %w", err)
	}
	req.Header.Set("Authorization", client.apiKey)

	resp, err := client.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("search pexels photos: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < http.StatusOK || resp.StatusCode >= http.StatusMultipleChoices {
		return nil, fmt.Errorf("pexels search failed with status %d", resp.StatusCode)
	}

	var payload searchResponse
	body := io.LimitReader(resp.Body, maxResponseSize)
	if err := json.NewDecoder(body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode pexels search response: %w", err)
	}

	images := make([]recipes.RecipeImage, 0, len(payload.Photos))
	for _, photo := range payload.Photos {
		image := recipes.RecipeImage{
			ID:              strconv.Itoa(photo.ID),
			ImageURL:        photo.Src.Large,
			ThumbnailURL:    photo.Src.Tiny,
			PexelsURL:       photo.URL,
			Photographer:    photo.Photographer,
			PhotographerURL: photo.PhotographerURL,
			Alt:             photo.Alt,
			AvgColor:        photo.AvgColor,
		}
		if image.ImageURL == "" {
			image.ImageURL = photo.Src.Landscape
		}
		if image.ThumbnailURL == "" {
			image.ThumbnailURL = photo.Src.Small
		}
		if image.ImageURL == "" || image.PexelsURL == "" {
			continue
		}
		images = append(images, image)
	}

	return images, nil
}

func pexelsLocale(languageTag string) string {
	switch strings.ToLower(strings.TrimSpace(languageTag)) {
	case "uk":
		return "uk-UA"
	default:
		return "en-US"
	}
}

type searchResponse struct {
	Photos []photoResource `json:"photos"`
}

type photoResource struct {
	ID              int         `json:"id"`
	URL             string      `json:"url"`
	Photographer    string      `json:"photographer"`
	PhotographerURL string      `json:"photographer_url"`
	AvgColor        string      `json:"avg_color"`
	Src             photoSource `json:"src"`
	Alt             string      `json:"alt"`
}

type photoSource struct {
	Large     string `json:"large"`
	Landscape string `json:"landscape"`
	Small     string `json:"small"`
	Tiny      string `json:"tiny"`
}
