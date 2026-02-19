package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"

	_ "github.com/joho/godotenv/autoload"
	"google.golang.org/genai"
)

type IngredientsResponse struct {
	Items []IngredientItem `json:"items"`
}

type IngredientItem struct {
	Name       string `json:"name"`
	Confidence string `json:"confidence"`
	Details    string `json:"details"`
}

const (
	thinkingLevel     = "medium"
	modelName         = "gemini-3-flash-preview"
	prompt            = "What food products are displayed in the image?"
	systemInstruction = `You are a helpful culinary assistant.
Your job is to identify food products and cooking ingredients from user-provided photos so recipes can be generated based on what's available.

Rules:
* Only include items that are actually visible in the image. Do NOT invent ingredients that are not clearly present.
* If an item is ambiguous, you may include it, but mark it with lower confidence.
* Ignore non-food objects (plates, utensils, table surface). Mention packaging only if it clearly identifies a food product.
* Prefer generic ingredient names over brands.`
)

func main() {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, nil)
	if err != nil {
		log.Fatal(err)
	}

	imagePath := flag.String("image", "images/products-1.jpeg", "Path to the input image")
	flag.Parse()

	bytes, err := os.ReadFile(*imagePath)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("Image to be processed:", *imagePath)

	parts := []*genai.Part{
		genai.NewPartFromBytes(bytes, "image/jpeg"),
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

	cfg := &genai.GenerateContentConfig{
		SystemInstruction: genai.NewContentFromText(systemInstruction, genai.RoleUser),
		ThinkingConfig: &genai.ThinkingConfig{
			ThinkingLevel: thinkingLevel,
		},
		ResponseMIMEType: "application/json",
		ResponseSchema:   responseSchema,
	}

	result, err := client.Models.GenerateContent(ctx, modelName, contents, cfg)
	if err != nil {
		log.Fatal(err)
	}

	var resp IngredientsResponse
	if err := json.Unmarshal([]byte(result.Text()), &resp); err != nil {
		log.Fatalf("Invalid JSON from model: %v\nRaw: %s", err, result.Text())
	}

	jsonBytes, err := json.MarshalIndent(resp, "", "  ")
	if err != nil {
		log.Fatalf("Failed to marshal JSON: %v", err)
	}
	fmt.Printf("%s\n", string(jsonBytes))
}
