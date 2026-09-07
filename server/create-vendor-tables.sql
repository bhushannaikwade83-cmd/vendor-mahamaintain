-- Run this once against digitrix_maha_maintain_pro before deploying
-- send-vendor-otp.php / verify-vendor-otp.php.
-- Mirrors the `individuals` / `otp_storage` pattern already used for the
-- customer app, kept in separate tables so a vendor and a customer account
-- can share the same phone number without colliding.

CREATE TABLE IF NOT EXISTS vendors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) DEFAULT NULL,
    phone VARCHAR(10) NOT NULL,
    email VARCHAR(255) DEFAULT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending | active | suspended
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_vendor_phone (phone)
);

CREATE TABLE IF NOT EXISTS vendor_otp_storage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(10) NOT NULL,
    otp VARCHAR(4) NOT NULL,
    attempts INT NOT NULL DEFAULT 0,
    expires_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    UNIQUE KEY uq_vendor_otp_phone (phone_number)
);
