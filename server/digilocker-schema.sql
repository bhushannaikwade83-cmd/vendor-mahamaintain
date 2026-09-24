-- DigiLocker integration schema additions
-- Run this once to set up document storage and verification tables

-- Tracks OAuth state tokens during DigiLocker authorization flow
CREATE TABLE IF NOT EXISTS digilocker_oauth_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id INT NOT NULL,
    state_token VARCHAR(255) UNIQUE NOT NULL, -- CSRF token
    code_verifier VARCHAR(255), -- PKCE: code verifier for token exchange
    status VARCHAR(50) NOT NULL, -- INITIATED, COMPLETED, FAILED
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    INDEX idx_state_token (state_token),
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_expires_at (expires_at)
);

-- Stores Aadhaar/PAN/other document details extracted from DigiLocker
CREATE TABLE IF NOT EXISTS vendor_digilocker_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id INT NOT NULL,
    document_type VARCHAR(50) NOT NULL, -- ADHAR, PANCR, DRIVINGLICENSE, PASSPORT, etc
    document_id VARCHAR(255) UNIQUE, -- DigiLocker document ID

    -- Extracted document data (varies by type)
    -- ADHAR fields:
    aadhaar_number VARCHAR(12),
    aadhaar_name VARCHAR(255),
    aadhaar_dob DATE,
    aadhaar_gender VARCHAR(10),
    aadhaar_address TEXT,

    -- PAN fields:
    pan_number VARCHAR(10),
    pan_name VARCHAR(255),
    pan_father_name VARCHAR(255),
    pan_dob DATE,

    -- License fields:
    license_number VARCHAR(50),
    license_holder_name VARCHAR(255),
    license_valid_from DATE,
    license_valid_till DATE,
    license_categories VARCHAR(100),

    -- Common fields:
    issue_date DATE,
    expiry_date DATE,
    raw_json_data LONGTEXT, -- Full response from DigiLocker for manual review

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_document_type (document_type),
    INDEX idx_aadhaar (aadhaar_number),
    INDEX idx_pan (pan_number)
);

-- Tracks admin verification actions
CREATE TABLE IF NOT EXISTS vendor_verification_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id INT NOT NULL,
    action VARCHAR(50) NOT NULL, -- verified, rejected, pending_review
    previous_status VARCHAR(50),
    new_status VARCHAR(50),
    admin_id INT, -- Which admin made the decision (optional, can be NULL for system actions)
    admin_name VARCHAR(255),
    rejection_reason TEXT, -- Why was vendor rejected?
    notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    INDEX idx_vendor_id (vendor_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);

-- Enhance vendor_verifications table with missing columns
ALTER TABLE vendor_verifications
ADD COLUMN IF NOT EXISTS document_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS all_documents_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS admin_review_notes TEXT,
ADD COLUMN IF NOT EXISTS admin_reviewed_at DATETIME,
ADD COLUMN IF NOT EXISTS admin_reviewed_by VARCHAR(255);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_vendor_verification_status ON vendor_verifications(verification_status);
CREATE INDEX IF NOT EXISTS idx_vendor_verification_digilocker ON vendor_verifications(digilocker_connected);
