DROP TRIGGER IF EXISTS trg_user_identities_updated_at ON user_identities;
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;

DROP FUNCTION IF EXISTS set_updated_at();

DROP INDEX IF EXISTS idx_user_sessions_user_id;
DROP INDEX IF EXISTS idx_user_identities_user_id;

DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS user_identities;
DROP TABLE IF EXISTS users;

DROP EXTENSION IF EXISTS citext;
DROP EXTENSION IF EXISTS pgcrypto;
