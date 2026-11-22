-- ============================================================================
-- FoodShare Platform - MySQL Database Schema
-- File: schema.sql
-- Target DBMS: MySQL (v8.0+)
-- Description: Schema for surplus food sharing platform connecting food
--              providers (restaurants, grocery stores, caterers) with
--              nonprofit organizations and food banks.
-- ============================================================================

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS foodshare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE foodshare;

-- ----------------------------------------------------------------------------
-- 0. CLEANUP (Drop tables in reverse dependency order)
-- ----------------------------------------------------------------------------

DROP TABLE IF EXISTS ngo_profiles;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS food_safety_checks;
DROP TABLE IF EXISTS food_claims;
DROP TABLE IF EXISTS food_listings;
DROP TABLE IF EXISTS users;

-- ----------------------------------------------------------------------------
-- 1. USERS TABLE
-- Stores credentials, roles, and profiles for providers, organizations, and admins
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    password_hash   VARCHAR(255)    NOT NULL,
    role            ENUM('provider', 'organization', 'recipient', 'admin') NOT NULL,
    phone           VARCHAR(30)     NULL,
    address         TEXT            NULL,
    is_verified     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_users_role (role),
    INDEX idx_users_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2. FOOD LISTINGS TABLE
-- Stores surplus food items posted by providers, with claiming tracking
-- ----------------------------------------------------------------------------
CREATE TABLE food_listings (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    provider_id         INT             NOT NULL,
    claimed_by          INT             NULL,
    title               VARCHAR(200)    NOT NULL,
    description         TEXT            NULL,
    category            VARCHAR(100)    NOT NULL,
    quantity            DECIMAL(10, 2)  NOT NULL,
    unit                VARCHAR(50)     NOT NULL,
    expiry_timestamp    DATETIME        NOT NULL,
    pickup_window_start DATETIME        NOT NULL,
    pickup_window_end   DATETIME        NOT NULL,
    status              ENUM('available', 'reserved', 'claimed', 'completed', 'expired', 'cancelled') NOT NULL DEFAULT 'available',
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    CONSTRAINT fk_food_listings_provider
        FOREIGN KEY (provider_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_food_listings_claimed_by
        FOREIGN KEY (claimed_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    -- Logical Constraints
    CONSTRAINT chk_listing_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_pickup_window CHECK (pickup_window_end >= pickup_window_start),

    -- Indexes
    INDEX idx_food_listings_provider_id (provider_id),
    INDEX idx_food_listings_claimed_by (claimed_by),
    INDEX idx_food_listings_status_expiry (status, expiry_timestamp),
    INDEX idx_food_listings_category (category),
    INDEX idx_food_listings_pickup_window (pickup_window_start, pickup_window_end),
    INDEX idx_food_listings_created_at (created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3. FOOD CLAIMS TABLE
-- Tracks claims placed by verified recipient organizations for listings
-- ----------------------------------------------------------------------------
CREATE TABLE food_claims (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    listing_id      INT             NOT NULL,
    organization_id INT             NOT NULL,
    status          ENUM('pending', 'approved', 'rejected', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    CONSTRAINT fk_food_claims_listing
        FOREIGN KEY (listing_id)
        REFERENCES food_listings (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_food_claims_organization
        FOREIGN KEY (organization_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    -- Indexes
    INDEX idx_food_claims_listing_id (listing_id),
    INDEX idx_food_claims_organization_id (organization_id),
    INDEX idx_food_claims_org_status (organization_id, status),
    INDEX idx_food_claims_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 4. FOOD SAFETY CHECKS TABLE
-- Records quality assurance and temperature checks prior to or at pickup
-- ----------------------------------------------------------------------------
CREATE TABLE food_safety_checks (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    listing_id          INT             NOT NULL,
    checked_by_user_id  INT             NOT NULL,
    temperature_celsius DECIMAL(5, 2)   NULL,
    packaging_intact    BOOLEAN         NOT NULL DEFAULT TRUE,
    notes               TEXT            NULL,
    checked_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Key Constraints
    CONSTRAINT fk_safety_checks_listing
        FOREIGN KEY (listing_id)
        REFERENCES food_listings (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_safety_checks_inspector
        FOREIGN KEY (checked_by_user_id)
        REFERENCES users (id)
        ON DELETE RESTRICT,

    -- Indexes
    INDEX idx_safety_checks_listing_id (listing_id),
    INDEX idx_safety_checks_inspector (checked_by_user_id),
    INDEX idx_safety_checks_checked_at (checked_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 5. NOTIFICATIONS TABLE
-- Real-time and historic notifications delivered to platform users
-- ----------------------------------------------------------------------------
CREATE TABLE notifications (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT             NOT NULL,
    message     TEXT            NOT NULL,
    is_read     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Key Constraint
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    -- Indexes
    INDEX idx_notifications_user_id (user_id),
    INDEX idx_notifications_user_unread (user_id, is_read, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 6. NGO PROFILES TABLE (Linked to users table)
-- Stores organizational credentials, registration ID, location, notification
-- status, and alert radius for community NGOs and food banks.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ngo_profiles (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    user_id             INT             NOT NULL,
    ngo_name            VARCHAR(255)    NOT NULL,
    reg_id              VARCHAR(100)    NOT NULL UNIQUE,
    location            VARCHAR(255)    NOT NULL,
    contact_info        VARCHAR(100)    NOT NULL,
    notification_status BOOLEAN         DEFAULT TRUE,
    radius_km           INT             DEFAULT 10,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Foreign Key Constraint
    CONSTRAINT fk_ngo_profiles_user
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    -- Indexes
    INDEX idx_ngo_profiles_user_id (user_id),
    INDEX idx_ngo_profiles_reg_id (reg_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 7. SAMPLE DEMO SEED DATA
-- Default accounts for quick testing and demonstration.
-- All demo user accounts use password: password123
-- ----------------------------------------------------------------------------

-- Seed Demo Users
INSERT INTO users (id, name, email, password_hash, role, phone, address, is_verified) VALUES
(1, 'Sunrise Artisan Bakery', 'provider@bakery.com', '$2b$10$NSmCB27TZ5pfN6pSavYJOerHN07LhAAmWTsPLZqk1OfuT17uaXCke', 'provider', '+1 555-234-5678', '120 Baker Street, Food District', TRUE),
(2, 'Hope Community Food Bank', 'contact@foodbank.org', '$2b$10$NSmCB27TZ5pfN6pSavYJOerHN07LhAAmWTsPLZqk1OfuT17uaXCke', 'organization', '+1 555-876-5432', '450 Charity Way, Central City', TRUE),
(3, 'Alex Rivera', 'community@foodshare.org', '$2b$10$NSmCB27TZ5pfN6pSavYJOerHN07LhAAmWTsPLZqk1OfuT17uaXCke', 'recipient', '+1 555-345-6789', '78 Pine Lane, Maple District', TRUE),
(4, 'Admin Officer', 'admin@foodshare.org', '$2b$10$NSmCB27TZ5pfN6pSavYJOerHN07LhAAmWTsPLZqk1OfuT17uaXCke', 'admin', '+1 555-999-0000', '100 Civic Center, Suite 400', TRUE)
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Seed NGO Profile for Hope Community Food Bank
INSERT INTO ngo_profiles (id, user_id, ngo_name, reg_id, location, contact_info, notification_status, radius_km) VALUES
(1, 2, 'Hope Community Food Bank', 'NGO-2026-HOPE88', '450 Charity Way, Central City', '+1 555-876-5432', TRUE, 15)
ON DUPLICATE KEY UPDATE ngo_name=VALUES(ngo_name);

-- Seed Available Food Listings
INSERT INTO food_listings (id, provider_id, title, description, category, quantity, unit, expiry_timestamp, pickup_window_start, pickup_window_end, status) VALUES
(1, 1, 'Artisan Sourdough & French Baguettes', 'Freshly baked sourdough and organic French baguettes from today morning prep.', 'Bakery', 25.00, 'loaves', DATE_ADD(NOW(), INTERVAL 18 HOUR), NOW(), DATE_ADD(NOW(), INTERVAL 6 HOUR), 'available'),
(2, 1, 'Organic Spinach & Bell Peppers', 'Surplus farm-fresh crisp greens and bell peppers from lunch service.', 'Produce', 15.50, 'kg', DATE_ADD(NOW(), INTERVAL 24 HOUR), NOW(), DATE_ADD(NOW(), INTERVAL 8 HOUR), 'available'),
(3, 1, 'Mediterranean Roasted Vegetable Bowls', 'Sealed catering trays of quinoa, roasted chickpeas, zucchini and tahini dressing. Kept in cold store at 3.5°C.', 'Prepared Meals', 30.00, 'servings', DATE_ADD(NOW(), INTERVAL 14 HOUR), NOW(), DATE_ADD(NOW(), INTERVAL 5 HOUR), 'available')
ON DUPLICATE KEY UPDATE title=VALUES(title);

-- Seed Food Safety Check for Prepared Meals Listing
INSERT INTO food_safety_checks (id, listing_id, checked_by_user_id, temperature_celsius, packaging_intact, notes) VALUES
(1, 3, 1, 3.50, TRUE, 'Sealed commercial foil containers, temperature verified in walk-in cold room.')
ON DUPLICATE KEY UPDATE notes=VALUES(notes);

-- Seed Notifications
INSERT INTO notifications (user_id, message, is_read) VALUES
(1, 'Welcome to FoodShare! Your food provider account is active and verified.', FALSE),
(2, 'Welcome to FoodShare! New surplus listings are available within your 15km service radius.', FALSE);

