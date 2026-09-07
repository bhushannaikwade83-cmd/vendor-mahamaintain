-- Run once against digitrix_maha_maintain_pro before deploying
-- set-vendor-mpin.php / verify-vendor-mpin.php / the updated
-- send-vendor-otp.php and verify-vendor-otp.php.

ALTER TABLE vendors
    ADD COLUMN mpin_hash VARCHAR(255) NULL,
    ADD COLUMN mpin_attempts INT NOT NULL DEFAULT 0,
    ADD COLUMN mpin_locked_until DATETIME NULL;
