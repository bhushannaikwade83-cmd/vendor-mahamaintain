<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'POST required'], 405);
}

require_once __DIR__ . '/jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

$input = json_decode((string)file_get_contents('php://input'), true);

$bookingId = (int)($input['booking_id'] ?? 0);
$action = $input['action'] ?? '';

if ($bookingId <= 0 || !in_array($action, ['accept', 'reject'], true)) {
    json_response(['success' => false, 'message' => 'booking_id and a valid action are required'], 400);
}

if ($action === 'reject') {
    $reason = trim((string)($input['reason'] ?? ''));

    // Self-heal: booking_rejections predates capturing a reason.
    $checkCol = db()->prepare(
        "SELECT COUNT(*) FROM information_schema.columns
         WHERE table_schema = DATABASE() AND table_name = 'booking_rejections' AND column_name = 'reason'"
    );
    $checkCol->execute();
    if ((int)$checkCol->fetchColumn() === 0) {
        db()->exec('ALTER TABLE booking_rejections ADD COLUMN reason VARCHAR(255) NULL');
    }

    // Just hides it from this vendor's feed - the job stays open for
    // every other vendor who services that category.
    db()->prepare(
        'INSERT IGNORE INTO booking_rejections (booking_id, vendor_id, reason) VALUES (:booking_id, :vendor_id, :reason)'
    )->execute(['booking_id' => $bookingId, 'vendor_id' => $vendorId, 'reason' => $reason ?: null]);

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

// Reflect both real transitions on the customer's order tracking screen -
// a technician being accepted implies they're now assigned.
sync_order_status($bookingId, 'accepted', 'Technician accepted the job');
sync_order_status($bookingId, 'technician_assigned', 'Technician assigned');

json_response(['success' => true, 'status' => 'ACCEPTED']);
