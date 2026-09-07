-- Society/AMC directory shown on the vendor app's Society tab. No admin
-- dashboard exists yet - add/edit rows directly in phpMyAdmin for now (same
-- pattern as the rest of this backend - see server/README.md).
--
-- Named vendor_society_directory (not "societies") because the consumer
-- app's database already has a `societies` table - a completely different,
-- unrelated thing: one row per customer's self-reported society/flat
-- address pending admin approval (individual_id, status enum, etc.), not a
-- shared directory of buildings. Don't rename this back to `societies`.
CREATE TABLE IF NOT EXISTS vendor_society_directory (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    phase VARCHAR(100) NULL,
    area VARCHAR(255) NOT NULL,
    units INT NOT NULL DEFAULT 0,
    contact_name VARCHAR(255) NULL,
    contact_phone VARCHAR(20) NULL,
    has_amc TINYINT(1) NOT NULL DEFAULT 0,
    access_notes VARCHAR(255) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- No seed data - add real societies directly in phpMyAdmin (no admin
-- dashboard exists for this yet). The Society tab shows an empty state
-- until rows exist here.
