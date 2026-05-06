CREATE TABLE recipe_collections (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name       CITEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_recipe_collections_user_name
    ON recipe_collections(user_id, name);

CREATE INDEX idx_recipe_collections_user_created_at
    ON recipe_collections(user_id, created_at DESC);

CREATE TRIGGER trg_recipe_collections_updated_at
BEFORE UPDATE ON recipe_collections
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE recipes
    ADD COLUMN collection_id UUID REFERENCES recipe_collections(id) ON DELETE SET NULL;

CREATE INDEX idx_recipes_user_collection_created_at
    ON recipes(user_id, collection_id, created_at DESC);
