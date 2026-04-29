ALTER TABLE recipes
    ADD COLUMN images JSONB NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(images) = 'array');
