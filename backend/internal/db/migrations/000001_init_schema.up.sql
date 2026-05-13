CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name  TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_identities (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider       TEXT NOT NULL CHECK (provider IN ('local', 'google', 'apple')),
    provider_uid   TEXT,
    email          CITEXT UNIQUE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    password_hash  TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_user_provider UNIQUE (user_id, provider),
    CONSTRAINT uq_provider_uid UNIQUE (provider, provider_uid),
    CONSTRAINT chk_local_auth CHECK (provider != 'local' OR (email IS NOT NULL AND password_hash IS NOT NULL)),
    CONSTRAINT chk_oauth_auth CHECK (provider = 'local' OR provider_uid IS NOT NULL)
);

CREATE TABLE user_sessions (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash TEXT NOT NULL UNIQUE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ NOT NULL,
    last_used_at       TIMESTAMPTZ
);

CREATE INDEX idx_user_identities_user_id ON user_identities(user_id);
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_user_identities_updated_at
BEFORE UPDATE ON user_identities
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

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

CREATE TABLE recipes (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    collection_id        UUID REFERENCES recipe_collections(id) ON DELETE SET NULL,
    dish_name            TEXT NOT NULL,
    dish_description     TEXT NOT NULL,
    difficulty           TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    cooking_time_minutes INT NOT NULL CHECK (cooking_time_minutes >= 0),
    ingredients          JSONB NOT NULL CHECK (jsonb_typeof(ingredients) = 'array'),
    steps                JSONB NOT NULL CHECK (jsonb_typeof(steps) = 'array'),
    macros               JSONB NOT NULL CHECK (jsonb_typeof(macros) = 'object'),
    images               JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(images) = 'array'),
    is_favorite          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recipes_user_created_at
    ON recipes(user_id, created_at DESC);

CREATE INDEX idx_recipes_user_favorite_created_at
    ON recipes(user_id, is_favorite DESC, created_at DESC);

CREATE INDEX idx_recipes_user_collection_created_at
    ON recipes(user_id, collection_id, created_at DESC);
