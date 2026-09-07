<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'POST required'], 405);
}

$input = json_decode((string)file_get_contents('php://input'), true);

$vendorId = trim((string)($input['vendor_id'] ?? ''));
$bookingId = (int)($input['booking_id'] ?? 0);
$action = $input['action'] ?? '';

if ($vendorId === '' || $bookingId <= 0 || !in_array($action, ['accept', 'reject'], true)) {
    json_response(['success' => false, 'message' => 'vendor_id, booking_id and a valid action are required'], 400);
}

if ($action === 'reject') {
    // Just hides it from this vendor's feed - the job stays open for
    // every other vendor who services that category.
    db()->prepare(
        'INSERT IGNORE INTO booking_rejections (booking_id, vendor_id) VALUES (:booking_id, :vendor_id)'
    )->execute(['booking_id' => $bookingId, 'vendor_id' => $vendorId]);

    json_response(['success' => true, 'status' => 'REJECTED']);
}

// A 6-digit code the customer will read out to the vendor to confirm job
// completion (see update-job-status.php's "complete" action). No SMS
// delivery to the customer is wired up yet - see server/README.md.
$completionOtp = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);

// Accept: atomic claim. The WHERE clause only succeeds if nobody else
// claimed it first - affected_rows tells us whether we won the race.
$stmt = db()->prepare(
    'UPDATE bookings SET vendor_id = :vendor_id, status = "ACCEPTED", accepted_at = NOW(), completion_otp = :otp
     WHERE id = :booking_id AND vendor_id IS NULL AND status = "REQUESTED"'
);
$stmt->execute(['vendor_id' => $vendorId, 'booking_id' => $bookingId, 'otp' => $completionOtp]);

if ($stmt->rowCount() === 0) {
    json_response(['success' => false, 'message' => 'This job was already taken by another partner'], 409);
}

json_response(['success' => true, 'status' => 'ACCEPTED']);
