package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"

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
	Ingredients []IngredientItem `json:"ingredients"`
}

type IngredientItem struct {
	Name       string `json:"name"`
	Quantity   string `json:"quantity"`
	Confidence string `json:"confidence"`
}

type RecipeResponse struct {
	DishName           string             `json:"dish_name"`
	DishDescription    string             `json:"dish_description"`
	Difficulty         string             `json:"difficulty"`
	CookingTimeMinutes int                `json:"cooking_time_minutes"`
	Ingredients        []RecipeIngredient `json:"ingredients"`
	Steps              []string           `json:"steps"`
	Macros             Macros             `json:"macros"`
}

type RecipeIngredient struct {
	Name     string `json:"name"`
	Quantity string `json:"quantity"`
}

type Macros struct {
	CaloriesKcal float64 `json:"calories_kcal"`
	ProteinG     float64 `json:"protein_g"`
	CarbsG       float64 `json:"carbs_g"`
	FatG         float64 `json:"fat_g"`
}

const (
	model            = "gemini-3-flash-preview"
	prompt           = "What food products are displayed in the image?"
	responseMIMEType = "application/json"

	ingredientSystemInstruction = `You are a helpful culinary assistant.
Your job is to identify food products and cooking ingredients from user-provided photos so recipes can be generated based on what's available.

Rules:
* Only include items that are actually visible in the image. Do NOT invent ingredients that are not clearly present.
* If an item is ambiguous, you may include it, but mark it with lower confidence.
* Ignore non-food objects (plates, utensils, table surface). Mention packaging only if it clearly identifies a food product.
* The "quantity" field must always include a unit or descriptor. For count-based items where the unit is unknown, default to "pieces".
* Prefer generic ingredient names over brands.`

	recipeSystemInstruction = `You are a helpful culinary assistant.
Your job is to generate a practical recipe based on the provided ingredients.

Rules:
* Use the provided ingredients as the primary ones.
* You may assume basic staples are available: salt, pepper, sugar, water, cooking oil, etc., but list them explicitly in ingredients.
* Macros numbers must be reasonable approximations based on the listed ingredients and their quantities, expressed as decimal values.
* If some ingredient quantities are missing, make conservative assumptions and keep the estimate plausible.
* Output must be suitable for home cooking and written clearly.

* The recipe must be for ONE person (single serving).
* Do NOT assume you must use all available ingredients. Use a reasonable subset to make one meal.
* The recipe should be sized for a normal home cooking portion.
* For each ingredient in the output, specify the amount actually USED (g, ml, pieces, or other precise units).
* If the input "quantity" look like package availability (e.g., "1 bag", "1 box"), do NOT use the whole package by default — use a typical partial amount unless the recipe realistically needs all of it.
* Calculate macros based ONLY on the amounts used in the recipe, not on everything available.
* Sanity check: calories_kcal ≈ protein_g*4 + carbs_g*4 + fat_g*9 (within ~10%).`
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
			"quantity": {
				Type:        genai.TypeString,
				Description: "Ingredient quantity.",
			},
			"confidence": {
				Type:        genai.TypeString,
				Description: "Confidence level of the identified ingredient.",
				Enum:        []string{"high", "medium", "low"},
			},
		},
		Required: []string{"name", "quantity", "confidence"},
	}

	responseSchema := &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"ingredients": {
				Type:  genai.TypeArray,
				Items: ingredientItemSchema,
			},
		},
		Required: []string{"ingredients"},
	}

	config := &genai.GenerateContentConfig{
		SystemInstruction: genai.NewContentFromText(ingredientSystemInstruction, genai.RoleUser),
		ThinkingConfig: &genai.ThinkingConfig{
			ThinkingLevel: genai.ThinkingLevelMedium,
		},
		ResponseMIMEType: responseMIMEType,
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

func GenerateRecipe(ctx context.Context, ingredients []RecipeIngredient) (RecipeResponse, error) {
	var b strings.Builder
	b.WriteString("Generate a dish recipe using the provided ingredients:")
	for _, it := range ingredients {
		name := strings.TrimSpace(it.Name)
		quantity := strings.TrimSpace(it.Quantity)
		fmt.Fprintf(&b, "\n- %s (%s)", name, quantity)
	}

	contents := []*genai.Content{
		genai.NewContentFromText(b.String(), genai.RoleUser),
	}

	recipeIngredientSchema := &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"name": {
				Type:        genai.TypeString,
				Description: "Ingredient name.",
			},
			"quantity": {
				Type:        genai.TypeString,
				Description: "Ingredient quantity.",
			},
		},
		Required: []string{"name", "quantity"},
	}

	macrosSchema := &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"calories_kcal": {
				Type:        genai.TypeNumber,
				Description: "Estimated calories per serving in kilocalories.",
			},
			"protein_g": {
				Type:        genai.TypeNumber,
				Description: "Estimated protein per serving in grams.",
			},
			"carbs_g": {
				Type:        genai.TypeNumber,
				Description: "Estimated carbohydrates per serving in grams.",
			},
			"fat_g": {
				Type:        genai.TypeNumber,
				Description: "Estimated fat per serving in grams.",
			},
		},
		Required: []string{"calories_kcal", "protein_g", "carbs_g", "fat_g"},
	}

	recipeSchema := &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"dish_name": {
				Type:        genai.TypeString,
				Description: "Dish name.",
			},
			"dish_description": {
				Type:        genai.TypeString,
				Description: "Brief description of the dish.",
			},
			"difficulty": {
				Type:        genai.TypeString,
				Description: "Estimated cooking difficulty level for the average person.",
				Enum:        []string{"easy", "medium", "hard"},
			},
			"cooking_time_minutes": {
				Type:        genai.TypeInteger,
				Description: "Approximate cooking time in minutes.",
			},
			"ingredients": {
				Type:  genai.TypeArray,
				Items: recipeIngredientSchema,
			},
			"steps": {
				Type:        genai.TypeArray,
				Description: "Detailed and easy-to-follow step-by-step cooking guide.",
				Items:       &genai.Schema{Type: genai.TypeString},
			},
			"macros": macrosSchema,
		},
		Required: []string{"dish_name", "dish_description", "difficulty", "cooking_time_minutes", "ingredients", "steps", "macros"},
	}

	config := &genai.GenerateContentConfig{
		SystemInstruction: genai.NewContentFromText(recipeSystemInstruction, genai.RoleUser),
		ThinkingConfig: &genai.ThinkingConfig{
			ThinkingLevel: genai.ThinkingLevelMedium,
		},
		ResponseMIMEType: responseMIMEType,
		ResponseSchema:   recipeSchema,
	}

	result, err := client.Models.GenerateContent(ctx, model, contents, config)
	if err != nil {
		return RecipeResponse{}, err
	}

	var resp RecipeResponse
	if err := json.Unmarshal([]byte(result.Text()), &resp); err != nil {
		return RecipeResponse{}, err
	}
	return resp, nil
}
