# Product Development Roadmap

This document tracks proposed improvements and features for future Culinex development.

## Recipe Browsing

- [ ] **Cache recipes on the Recipes page**
  - Store previously fetched recipes locally to reduce unnecessary API requests, improve loading times, and provide a smoother experience when revisiting the page.
  - Define an appropriate cache invalidation and refresh strategy so displayed recipe data remains current.

- [ ] **Add pagination to the Recipes page**
  - Load recipes in manageable pages instead of retrieving the entire collection at once.
  - Preserve loading, empty, and error states while ensuring users can navigate or continuously scroll through additional results.

## Authentication and Account Security

- [ ] **Add Google and Apple authentication**
  - Allow users to register and sign in with their Google or Apple accounts.
  - Integrate social authentication with the existing account and session flows, including handling linked accounts and authentication failures.

- [ ] **Add email confirmation after registration**
  - Send a verification email to users who create an account with an email address and password.
  - Provide confirmation, resend, expiration, and invalid-link flows, and restrict account functionality as appropriate until the email address is verified.

## Recipe Generation

- [ ] **Allow users to specify the number of servings**
  - Add a servings input to the recipe-generation flow.
  - Include the requested serving count in the generation prompt and ensure ingredient quantities and recipe details are scaled appropriately.

- [ ] **Provide an alternative recipe or shopping list in the AI response**
  - Extend generated results with a useful alternative, such as a substitute recipe or a shopping list based on missing ingredients.
  - Present the additional AI-generated content in a clear, structured format and allow users to act on it independently from the primary recipe.

## Sharing

- [ ] **Add recipe sharing**
  - Allow users to share a recipe through supported device applications or by copying a shareable link.
  - Ensure shared content includes the essential recipe details and that recipients can access it through an appropriate public or deep-linked experience.

## Personalization and Recommendations

- [ ] **Support dietary preferences and food restrictions**
  - Let users maintain a profile containing dietary preferences, allergies, disliked foods, and other relevant constraints.
  - Apply these settings consistently during recipe generation and recommendations, with allergy-related exclusions treated as strict safety constraints.

- [ ] **Provide periodic personalized dish recommendations**
  - Recommend dishes based on the user's recipe history, saved recipes, and personalization settings.
  - Define recommendation frequency and delivery channels, give users control over notification preferences, and avoid repetitive suggestions.
