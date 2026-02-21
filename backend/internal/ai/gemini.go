package ai

import (
	"context"
	"encoding/json"
	"log"

	"google.golang.org/genai"
)

var client *genai.Client

func InitGeminiClient(ctx context.Context) {
	var err error
	client, err = genai.NewClient(ctx, nil)
	if err != nil {
		log.Fatalf("Failed to create Gemini client: %v", err)
	}
}

type IngredientsResponse struct {
	Items []IngredientItem `json:"items"`
}

type IngredientItem struct {
	Name       string `json:"name"`
	Confidence string `json:"confidence"`
	Details    string `json:"details"`
}

const (
	model             = "gemini-3-flash-preview"
	prompt            = "What food products are displayed in the image?"
	systemInstruction = `You are a helpful culinary assistant.
Your job is to identify food products and cooking ingredients from user-provided photos so recipes can be generated based on what's available.

Rules:
* Only include items that are actually visible in the image. Do NOT invent ingredients that are not clearly present.
* If an item is ambiguous, you may include it, but mark it with lower confidence.
* Ignore non-food objects (plates, utensils, table surface). Mention packaging only if it clearly identifies a food product.
* Prefer generic ingredient names over brands.`
)

func ExtractIngredients(ctx context.Context, data []byte, mimeType string) (IngredientsResponse, error) {
	parts := []*genai.Part{
		genai.NewPartFromBytes(data, mimeType),
		genai.NewPartFromText(prompt),
	}

	contents := []*genai.Content{
		genai.NewContentFromParts(parts, genai.RoleUser),
	}

	ingredientItemSchema := &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"name": {
				Type:        genai.TypeString,
				Description: "Ingredient name.",
			},
			"confidence": {
				Type: genai.TypeString,
				Enum: []string{"high", "medium", "low"},
			},
			"details": {
				Type:        genai.TypeString,
				Description: "Quantity or description.",
			},
		},
		Required: []string{"name", "confidence", "details"},
	}

	responseSchema := &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"items": {
				Type:  genai.TypeArray,
				Items: ingredientItemSchema,
			},
		},
		Required: []string{"items"},
	}

	config := &genai.GenerateContentConfig{
		SystemInstruction: genai.NewContentFromText(systemInstruction, genai.RoleUser),
		ThinkingConfig: &genai.ThinkingConfig{
			ThinkingLevel: genai.ThinkingLevelMedium,
		},
		ResponseMIMEType: "application/json",
		ResponseSchema:   responseSchema,
	}

	result, err := client.Models.GenerateContent(ctx, model, contents, config)
	if err != nil {
		return IngredientsResponse{}, err
	}

	var resp IngredientsResponse
	if err := json.Unmarshal([]byte(result.Text()), &resp); err != nil {
		return IngredientsResponse{}, err
	}
	return resp, nil
}
