-- =====================================
--  EXTENSIONS (if needed)
-- =====================================
-- Make sure either pgcrypto or uuid-ossp is installed:
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================
--  USERS
-- =====================================
CREATE TABLE IF NOT EXISTS users (
    user_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    keycloak_id   UUID UNIQUE NOT NULL,           -- Maps to Keycloak's user ID
    email         VARCHAR(255) UNIQUE NOT NULL,
    name          VARCHAR(255),
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Optional: index on keycloak_id if you frequently join on it
CREATE INDEX IF NOT EXISTS idx_users_keycloak_id ON users(keycloak_id);

-- =====================================
--  ROLES
-- =====================================
CREATE TABLE IF NOT EXISTS roles (
    role_id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name          VARCHAR(100) UNIQUE NOT NULL,
    description   TEXT
);

-- =====================================
--  USER_ROLES (Mapping Users to Roles)
-- =====================================
CREATE TABLE IF NOT EXISTS user_roles (
    user_role_id  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id       UUID NOT NULL,
    role_id       UUID NOT NULL
);

ALTER TABLE user_roles
    ADD CONSTRAINT fk_user_roles_user 
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE;

ALTER TABLE user_roles
    ADD CONSTRAINT fk_user_roles_role 
        FOREIGN KEY (role_id)
        REFERENCES roles (role_id)
        ON DELETE CASCADE;

-- Ensure no duplicates of (user_id, role_id)
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_roles_user_role 
    ON user_roles(user_id, role_id);

-- =====================================
--  PERMISSIONS (Integrates with OpenFGA)
-- =====================================
CREATE TABLE IF NOT EXISTS permissions (
    permission_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    resource      VARCHAR(100) NOT NULL,   -- e.g., "sample", "asset"
    action        VARCHAR(50)  NOT NULL,   -- e.g., "read", "write"
    role_id       UUID NOT NULL
);

ALTER TABLE permissions
    ADD CONSTRAINT fk_permissions_role
        FOREIGN KEY (role_id)
        REFERENCES roles (role_id)
        ON DELETE CASCADE;

-- Ensure uniqueness of (resource, action, role_id)
CREATE UNIQUE INDEX IF NOT EXISTS idx_permissions_resource_action_role 
    ON permissions(resource, action, role_id);

-- =====================================
--  ASSETS
-- =====================================
CREATE TABLE IF NOT EXISTS assets (
    asset_id      UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    asset_type    VARCHAR(50) NOT NULL,        -- e.g., "Tray", "Reagent"
    description   TEXT,
    status        VARCHAR(50) DEFAULT 'available',
    assigned_to   UUID                               -- references users.user_id
);

ALTER TABLE assets
    ADD CONSTRAINT fk_assets_assigned_to 
        FOREIGN KEY (assigned_to)
        REFERENCES users (user_id)
        ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_assets_assigned_to 
    ON assets(assigned_to);

-- =====================================
--  SAMPLES
-- =====================================
CREATE TABLE IF NOT EXISTS samples (
    sample_id     UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sample_type   VARCHAR(50) NOT NULL,        -- e.g., "Stool", "Blood"
    status        VARCHAR(50) DEFAULT 'pending',
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_asset UUID
);

ALTER TABLE samples
    ADD CONSTRAINT fk_samples_assigned_asset
        FOREIGN KEY (assigned_asset)
        REFERENCES assets (asset_id)
        ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_samples_assigned_asset 
    ON samples(assigned_asset);

-- =====================================
--  WORKFLOWS
-- =====================================
CREATE TABLE IF NOT EXISTS workflows (
    workflow_id   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    step_order    INT NOT NULL,
    description   TEXT,
    status        VARCHAR(50) DEFAULT 'pending',
    sample_id     UUID NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE workflows
    ADD CONSTRAINT fk_workflows_sample
        FOREIGN KEY (sample_id)
        REFERENCES samples (sample_id)
        ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_workflows_sample_id
    ON workflows(sample_id);

-- =====================================
--  LOGS
-- =====================================
CREATE TABLE IF NOT EXISTS logs (
    log_id        UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    workflow_id   UUID NOT NULL,
    timestamp     TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    message       TEXT NOT NULL,
    image_url     TEXT
);

ALTER TABLE logs
    ADD CONSTRAINT fk_logs_workflow
        FOREIGN KEY (workflow_id)
        REFERENCES workflows (workflow_id)
        ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_logs_workflow_id
    ON logs(workflow_id);

-- =====================================
--  CAMERAS
-- =====================================
CREATE TABLE IF NOT EXISTS cameras (
    camera_id     UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    location      VARCHAR(255) NOT NULL,
    status        VARCHAR(50) DEFAULT 'active',
    last_action   TIMESTAMP WITH TIME ZONE
);

-- =====================================
--  ANALYTICS
-- =====================================
CREATE TABLE IF NOT EXISTS analytics (
    analytics_id  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_name   VARCHAR(255) NOT NULL,
    metric_value  JSONB NOT NULL,     -- Allows storing complex analytics
    captured_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================
--  EXTERNAL_APIS
-- =====================================
CREATE TABLE IF NOT EXISTS external_apis (
    api_id        UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    api_name      VARCHAR(255) NOT NULL,
    base_url      TEXT NOT NULL,
    last_used     TIMESTAMP WITH TIME ZONE
);
