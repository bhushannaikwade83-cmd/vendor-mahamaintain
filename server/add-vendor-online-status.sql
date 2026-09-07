-- Adds the vendor's online/offline toggle. When offline, get-vendor-jobs.php
-- won't surface new job requests to them - see set-vendor-online-status.php.
ALTER TABLE vendors ADD COLUMN is_online TINYINT(1) NOT NULL DEFAULT 1;
