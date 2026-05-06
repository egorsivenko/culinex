DROP INDEX IF EXISTS idx_recipes_user_collection_created_at;

ALTER TABLE recipes
    DROP COLUMN IF EXISTS collection_id;

DROP TRIGGER IF EXISTS trg_recipe_collections_updated_at ON recipe_collections;

DROP INDEX IF EXISTS idx_recipe_collections_user_created_at;
DROP INDEX IF EXISTS idx_recipe_collections_user_name;

DROP TABLE IF EXISTS recipe_collections;
