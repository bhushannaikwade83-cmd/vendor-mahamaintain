<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

$vendorId = trim((string)($_GET['vendor_id'] ?? ''));
if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

// A vendor who's toggled themselves offline shouldn't see (or, once push
// alerts exist, be notified about) new job requests - but they should still
// see jobs they already claimed, so they can finish what's in progress.
$onlineStmt = db()->prepare('SELECT is_online FROM vendors WHERE id = :vendor_id');
$onlineStmt->execute(['vendor_id' => $vendorId]);
$vendorRow = $onlineStmt->fetch();
$isOnline = $vendorRow ? (bool)$vendorRow['is_online'] : true;

// "New" jobs: broadcast (unclaimed) bookings in a category this vendor
// services, that they haven't already rejected.
if ($isOnline) {
    $newJobsStmt = db()->prepare(
        'SELECT b.*, sc.name AS category_name FROM bookings b
         JOIN service_categories sc ON sc.id = b.category_id
         WHERE b.status = "REQUESTED"
           AND b.vendor_id IS NULL
           AND b.category_id IN (
               SELECT category_id FROM vendor_service_categories WHERE vendor_id = :vendor_id
           )
           AND b.id NOT IN (
               SELECT booking_id FROM booking_rejections WHERE vendor_id = :vendor_id2
           )
         ORDER BY b.created_at DESC'
    );
    $newJobsStmt->execute(['vendor_id' => $vendorId, 'vendor_id2' => $vendorId]);
    $newJobs = $newJobsStmt->fetchAll();
} else {
    $newJobs = [];
}

// "My" jobs: anything already claimed by this vendor, any status.
$myJobsStmt = db()->prepare(
    'SELECT b.*, sc.name AS category_name FROM bookings b
     JOIN service_categories sc ON sc.id = b.category_id
     WHERE b.vendor_id = :vendor_id ORDER BY
        CASE b.status
            WHEN "ACCEPTED" THEN 0
            WHEN "IN_PROGRESS" THEN 0
            ELSE 1
        END,
        COALESCE(b.scheduled_at, b.created_at) DESC'
);
$myJobsStmt->execute(['vendor_id' => $vendorId]);
$myJobs = $myJobsStmt->fetchAll();

json_response([
    'new_jobs' => array_map('format_booking', $newJobs),
    'my_jobs' => array_map('format_booking', $myJobs),
]);

function format_booking(array $row): array
{
    return [
        'id' => (int)$row['id'],
        'customer_name' => $row['customer_name'],
        'customer_phone' => $row['customer_phone'],
        'category_id' => (int)$row['category_id'],
        'service_type' => $row['service_type'],
        'notes' => $row['notes'],
        'address' => $row['address'],
        'latitude' => $row['latitude'] !== null ? (float)$row['latitude'] : null,
        'longitude' => $row['longitude'] !== null ? (float)$row['longitude'] : null,
        'amount' => (float)$row['amount'],
        'payment_mode' => $row['payment_mode'],
        'scheduled_at' => $row['scheduled_at'],
        'vendor_id' => $row['vendor_id'],
        'status' => $row['status'],
        'before_photo_url' => $row['before_photo_path'] ? JOB_PHOTO_BASE_URL . $row['before_photo_path'] : null,
        'after_photo_url' => $row['after_photo_path'] ? JOB_PHOTO_BASE_URL . $row['after_photo_path'] : null,
        // completion_otp is intentionally NOT exposed here - it's read aloud
        // by the customer to the vendor as proof of an on-site visit. If the
        // vendor's own app could see it, that proof would be worthless.
        'rating' => $row['rating'] !== null ? (int)$row['rating'] : null,
        'created_at' => $row['created_at'],
        'accepted_at' => $row['accepted_at'],
        'started_at' => $row['started_at'],
        'completed_at' => $row['completed_at'],
    ];
}
