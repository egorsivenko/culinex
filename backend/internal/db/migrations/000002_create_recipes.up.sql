CREATE TABLE recipes (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dish_name            TEXT NOT NULL,
    dish_description     TEXT NOT NULL,
    difficulty           TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    cooking_time_minutes INT NOT NULL CHECK (cooking_time_minutes >= 0),
    ingredients          JSONB NOT NULL CHECK (jsonb_typeof(ingredients) = 'array'),
    steps                JSONB NOT NULL CHECK (jsonb_typeof(steps) = 'array'),
    macros               JSONB NOT NULL CHECK (jsonb_typeof(macros) = 'object'),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recipes_user_created_at ON recipes(user_id, created_at DESC);
