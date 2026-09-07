-- Run this manually against your MariaDB database before uploading the PHP
-- files (or after - order doesn't matter, but nothing will work until these
-- tables exist).
--
-- Phone/OTP login and the `vendors` account table live in
-- create-vendor-tables.sql (run that first, or in any order - just run it).
-- This file only covers the KYC-related tables below.

CREATE TABLE IF NOT EXISTS vendor_verifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    -- Identifier for the vendor: the numeric `vendors.id` from
    -- create-vendor-tables.sql, passed as a string - it just needs
    -- to be something the Flutter app can consistently pass back.
    vendor_id VARCHAR(128) NOT NULL,
    verification_status ENUM(
        'UNVERIFIED',
        'DIGILOCKER_CONNECTED',
        'UNDER_REVIEW',
        'VERIFIED',
        'REJECTED'
    ) NOT NULL DEFAULT 'UNVERIFIED',
    digilocker_connected TINYINT(1) NOT NULL DEFAULT 0,
    digilocker_verified_at DATETIME NULL,
    identity_verified TINYINT(1) NOT NULL DEFAULT 0,
    pan_verified TINYINT(1) NOT NULL DEFAULT 0,
    gst_verified TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_vendor (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS digilocker_oauth_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    state_token VARCHAR(128) NOT NULL UNIQUE,
    status ENUM('INITIATED', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'INITIATED',
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Bank account verification (Razorpay Fund Account Validation / penny-drop)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendor_bank_accounts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    account_holder_name VARCHAR(255) NOT NULL,
    -- Only the last 4 digits are kept once verification completes; the full
    -- number is used once to call Razorpay and is not stored beyond that.
    account_number_last4 VARCHAR(4) NOT NULL,
    ifsc_code VARCHAR(11) NOT NULL,
    razorpay_contact_id VARCHAR(64) NULL,
    razorpay_fund_account_id VARCHAR(64) NULL,
    razorpay_validation_id VARCHAR(64) NULL,
    registered_name VARCHAR(255) NULL,
    name_match TINYINT(1) NULL,
    verification_status ENUM(
        'PENDING',
        'VERIFIED',
        'FAILED'
    ) NOT NULL DEFAULT 'PENDING',
    verified_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_vendor_bank (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Service categories
--
-- Reuses the consumer app's existing `service_categories` table (id INT,
-- name, emoji, color, description, is_active, created_at, image_path) as
-- the master list, rather than creating a separate/duplicate one - the
-- vendor app just picks which of those categories a vendor can service.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendor_service_categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    -- Matches service_categories.id's type (INT) so the foreign key below
    -- can actually be created.
    category_id INT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_vendor_category (vendor_id, category_id),
    FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- Live selfie verification (captured + stored for manual admin review)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendor_selfies (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    -- Filename on disk under SELFIE_UPLOAD_DIR, not a public URL.
    file_name VARCHAR(255) NOT NULL,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at DATETIME NULL,
    UNIQUE KEY uniq_vendor_selfie (vendor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
