ALTER TABLE recipes
    ADD COLUMN is_favorite BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_recipes_user_favorite_created_at
    ON recipes(user_id, is_favorite DESC, created_at DESC);
