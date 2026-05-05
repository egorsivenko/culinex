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
	log.Println("Gemini client initialized")
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
	Source   string `json:"source,omitempty"`
}

type Macros struct {
	CaloriesKcal float64 `json:"calories_kcal"`
	ProteinG     float64 `json:"protein_g"`
	CarbsG       float64 `json:"carbs_g"`
	FatG         float64 `json:"fat_g"`
}

var recipeStylePrompts = map[string]string{
	"everyday": `Recipe style: everyday.
Make a practical weeknight-style home recipe. Prefer familiar flavor combinations, common techniques, short active prep, and a clear prep-to-plate flow when possible.
Avoid chef-like plating language, complicated sub-recipes, and unusual formats unless the provided ingredients strongly require them.`,
	"professional": `Recipe style: professional.
Create a more refined home-cookable recipe with precise technique and polished presentation.
Include useful doneness cues, timing cues, texture goals, and one elevated detail such as searing, emulsifying, reducing, layering, resting, garnishing, or plating when appropriate.
Keep the equipment and ingredients realistic for a home kitchen.`,
	"creative": `Recipe style: creative.
Create a noticeably more original recipe by changing the dish format, flavor direction, texture contrast, or serving idea.
Use playful but practical combinations, and make the result feel distinct from a default everyday meal.
Do not add unavailable specialty ingredients, unsafe techniques, or complexity that would make the recipe impractical.`,
}

const (
	model            = "gemini-3-flash-preview"
	responseMIMEType = "application/json"

	MinRecipeIngredientCount = 3

	ingredientPrompt         = "Identify only the clear food products and cooking ingredients displayed in the image."
	recipePrompt             = "Validate and filter the provided ingredient list, then generate a dish recipe only if enough usable ingredients remain:"
	assumeBasicStaplesPrompt = `Basic staples are available as optional supporting ingredients only - water, common dried spices and seasonings, butter, and a neutral cooking oil or olive oil.
Do not treat staples as primary ingredients, and do not generate a recipe if the provided ingredient list is otherwise invalid.
If you use any staple, list the amount explicitly in the ingredients and mark its source as "staple".`

	ingredientSystemInstruction = `You are a helpful culinary assistant.
Your job is to identify food products and cooking ingredients from user-provided photos so recipes can be generated based on what's available.
Always respond in %s, regardless of the language the user writes in.

Rules:
* Only include items that are actually visible in the image. Do NOT invent ingredients that are not clearly present.
* Return an empty ingredients list if the image has no clear food products, only non-food objects, only unreadable/ambiguous packaging, or a prepared meal whose ingredients cannot be identified reliably.
* If an item is ambiguous but probably edible, you may include it only with low confidence. Omit items that are too vague to name as a cookable ingredient.
* Ignore non-food objects (plates, utensils, table surface). Mention packaging only if it clearly identifies a food product inside.
* The "quantity" field must always include a unit or descriptor. For count-based items where the unit is unknown, default to "pieces".
* Prefer generic ingredient names over brands.`

	recipeSystemInstruction = `You are a helpful culinary assistant.
Your job is to generate a practical recipe based on the provided ingredients.
Always respond in %s, regardless of the language the user writes in.

Rules:
* Before creating a recipe, validate every provided entry. A usable entry must have a recognizable edible ingredient name and a quantity that is meaningful enough to cook with.
* Ignore entries that are clearly irrelevant, non-food, duplicated, contradictory, unsafe, inedible, joke text, or unusable for a practical recipe.
* If an entry looks nonsensical, random, too vague to cook with, or has a gibberish name or quantity, filter it out silently.
* If the list contains near-duplicates or repeated items, consolidate them internally and use the clearest useful version.
* If fewer than %d usable primary ingredients remain after filtering, decline by returning an empty recipe response. Do not attempt to create a recipe with fewer than %d main ingredients, even if basic staples are available.
* Basic staples may support a valid recipe, but they must not rescue an invalid ingredient list and they do not count toward the required usable primary ingredients.
* Use the remaining provided ingredients as the primary ones.
* Use ONLY ingredients from the filtered provided list plus explicitly allowed basic staples when the user prompt says staples are available.
* Every output ingredient must include a "source" field:
  - "provided" for ingredients from the user's list.
  - "staple" for explicitly allowed basic staples.
* Macros numbers must be reasonable approximations based on the listed ingredients and their quantities, expressed as decimal values.
* If some ingredient quantities are missing, make conservative assumptions and keep the estimate plausible.
* Output must be suitable for home cooking and written clearly.
* Make the dish name and description appealing but honest. Do not exaggerate, invent premium ingredients, or describe flavors and textures that are not supported by the used ingredients.

* The recipe must be for ONE person (single serving).
* Do NOT assume you must use all available ingredients. Use a reasonable subset to make one meal.
* The recipe should be sized for a normal home cooking portion.
* For each ingredient in the output, specify the amount actually USED (g, ml, pieces, or other precise units).
* If the input "quantity" look like package availability (e.g., "1 bag", "1 box"), do NOT use the whole package by default - use a typical partial amount unless the recipe realistically needs all of it.
* Calculate macros based ONLY on the amounts used in the recipe, not on everything available.
* Sanity check: calories_kcal ≈ protein_g*4 + carbs_g*4 + fat_g*9 (within ~10%%).`
)

func ExtractIngredients(ctx context.Context, data []byte, mimeType string, language string) (IngredientsResponse, error) {
	parts := []*genai.Part{
		genai.NewPartFromBytes(data, mimeType),
		genai.NewPartFromText(ingredientPrompt),
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
		SystemInstruction: genai.NewContentFromText(fmt.Sprintf(ingredientSystemInstruction, language), genai.RoleUser),
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

func GenerateRecipe(ctx context.Context, ingredients []RecipeIngredient, assumeBasicStaples bool, recipeStyle string, language string) (RecipeResponse, error) {
	prompt := buildRecipePrompt(ingredients, assumeBasicStaples, recipeStyle)

	contents := []*genai.Content{
		genai.NewContentFromText(prompt, genai.RoleUser),
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
			"source": {
				Type:        genai.TypeString,
				Description: `Ingredient provenance.`,
				Enum:        []string{"provided", "staple"},
			},
		},
		Required: []string{"name", "quantity", "source"},
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
		SystemInstruction: genai.NewContentFromText(
			fmt.Sprintf(
				recipeSystemInstruction,
				language,
				MinRecipeIngredientCount,
				MinRecipeIngredientCount,
			),
			genai.RoleUser,
		),
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

func IsEmptyRecipeResponse(recipe RecipeResponse) bool {
	return strings.TrimSpace(recipe.DishName) == "" &&
		strings.TrimSpace(recipe.DishDescription) == "" &&
		len(recipe.Ingredients) == 0 &&
		len(recipe.Steps) == 0
}

func IsValidRecipeStyle(rawValue string) bool {
	_, ok := recipeStylePrompts[rawValue]
	return ok
}

func buildRecipePrompt(ingredients []RecipeIngredient, assumeBasicStaples bool, recipeStyle string) string {
	var b strings.Builder
	b.WriteString(recipePrompt)
	for _, it := range ingredients {
		name := strings.TrimSpace(it.Name)
		quantity := strings.TrimSpace(it.Quantity)
		fmt.Fprintf(&b, "\n- %s: %s", name, quantity)
	}
	b.WriteString("\n\n")
	b.WriteString(recipeStylePrompts[recipeStyle])
	if assumeBasicStaples {
		b.WriteString("\n\n")
		b.WriteString(assumeBasicStaplesPrompt)
	}
	return b.String()
}
