DROP INDEX IF EXISTS idx_recipes_user_favorite_created_at;

ALTER TABLE recipes
    DROP COLUMN is_favorite;
