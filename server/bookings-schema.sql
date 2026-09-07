-- Run once against digitrix_maha_maintain_pro before deploying
-- create-booking.php / get-vendor-jobs.php / respond-to-job.php /
-- update-job-status.php / get-vendor-earnings.php / withdraw-earnings.php.
--
-- This is the real jobs/booking system replacing the vendor app's demo
-- data. The consumer app doesn't have a booking backend yet (surveyed, not
-- modified) - create-booking.php is the "plug point" it will call once
-- it's ready. Until then, call it directly (see server/README.md) to
-- simulate an incoming job request for testing.
--
-- Reuses service_categories(id) - the same table vendor_service_categories
-- already references - so a booking's category directly determines which
-- vendors can see it (whoever has that category in vendor_service_categories).

CREATE TABLE IF NOT EXISTS bookings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    -- Customer details are stored as a snapshot (not a live FK to the
    -- consumer app's `individuals` table) since this app doesn't own that
    -- table and shouldn't assume its exact shape - individual_id is kept
    -- as an optional reference only, not enforced.
    individual_id INT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(10) NOT NULL,

    category_id INT NOT NULL,
    service_type VARCHAR(255) NOT NULL,
    notes TEXT NULL,

    address TEXT NOT NULL,
    latitude DECIMAL(10, 7) NULL,
    longitude DECIMAL(10, 7) NULL,

    amount DECIMAL(10, 2) NOT NULL,
    payment_mode ENUM('UPI', 'CASH', 'ONLINE') NOT NULL DEFAULT 'UPI',
    scheduled_at DATETIME NULL,

    -- vendor_id stays NULL while the job is broadcast to every vendor who
    -- services this category - the first to accept claims it (see
    -- respond-to-job.php's atomic UPDATE ... WHERE vendor_id IS NULL).
    vendor_id VARCHAR(128) NULL,

    status ENUM(
        'REQUESTED',
        'ACCEPTED',
        'IN_PROGRESS',
        'COMPLETED',
        'CANCELLED',
        'REJECTED'
    ) NOT NULL DEFAULT 'REQUESTED',

    before_photo_path VARCHAR(255) NULL,
    after_photo_path VARCHAR(255) NULL,
    completion_otp VARCHAR(6) NULL,

    rating TINYINT NULL,
    rating_comment TEXT NULL,

    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    accepted_at DATETIME NULL,
    started_at DATETIME NULL,
    completed_at DATETIME NULL,
    cancelled_at DATETIME NULL,

    FOREIGN KEY (category_id) REFERENCES service_categories(id),
    INDEX idx_category_status (category_id, status),
    INDEX idx_vendor_status (vendor_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- A vendor who explicitly rejects a broadcast job shouldn't see it again in
-- their "new job requests" list, even though it's still open for other
-- vendors to accept.
CREATE TABLE IF NOT EXISTS booking_rejections (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    booking_id BIGINT NOT NULL,
    vendor_id VARCHAR(128) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_booking_vendor (booking_id, vendor_id),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Single ledger for both earnings (positive amount) and withdrawals
-- (negative amount) - a vendor's wallet balance is just SUM(amount) for
-- their vendor_id.
CREATE TABLE IF NOT EXISTS vendor_ledger (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    vendor_id VARCHAR(128) NOT NULL,
    booking_id BIGINT NULL,
    entry_type ENUM('JOB_EARNING', 'WITHDRAWAL', 'BONUS', 'ADJUSTMENT') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vendor_created (vendor_id, created_at),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
