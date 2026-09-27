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

// Multipart form (not JSON) - action determines which fields matter:
//   on_the_way -> requires: booking_id
//   start      -> requires: booking_id. optional: before_photo file
//   complete   -> requires: booking_id, completion_otp. optional: after_photo file,
//                 work_description, parts_used, additional_charges, technician_remarks
//   cancel     -> requires: booking_id
$bookingId = (int)($_POST['booking_id'] ?? 0);
$action = $_POST['action'] ?? '';

if ($bookingId <= 0 || !in_array($action, ['on_the_way', 'start', 'complete', 'cancel'], true)) {
    json_response(['success' => false, 'message' => 'booking_id and a valid action are required'], 400);
}

$stmt = db()->prepare('SELECT * FROM bookings WHERE id = :id AND vendor_id = :vendor_id LIMIT 1');
$stmt->execute(['id' => $bookingId, 'vendor_id' => $vendorId]);
$booking = $stmt->fetch();

if (!$booking) {
    json_response(['success' => false, 'message' => 'Job not found for this vendor'], 404);
}

function save_job_photo(string $fieldName, int $bookingId, string $suffix): ?string
{
    if (!isset($_FILES[$fieldName]) || $_FILES[$fieldName]['error'] !== UPLOAD_ERR_OK) {
        return null;
    }
    $file = $_FILES[$fieldName];

    if ($file['size'] > JOB_PHOTO_MAX_BYTES) {
        json_response(['success' => false, 'message' => 'Photo is too large (max 5 MB)'], 400);
    }

    $allowedTypes = ['image/jpeg' => 'jpg', 'image/png' => 'png'];
    $mimeType = null;

    if (function_exists('finfo_open')) {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo !== false) {
            $mimeType = finfo_file($finfo, $file['tmp_name']) ?: null;
            finfo_close($finfo);
        }
    }
    if ($mimeType === null) {
        $handle = fopen($file['tmp_name'], 'rb');
        $header = $handle ? fread($handle, 8) : '';
        if ($handle) {
            fclose($handle);
        }
        if (substr($header, 0, 3) === "\xFF\xD8\xFF") {
            $mimeType = 'image/jpeg';
        } elseif (substr($header, 0, 8) === "\x89PNG\r\n\x1a\n") {
            $mimeType = 'image/png';
        }
    }

    if ($mimeType === null || !isset($allowedTypes[$mimeType])) {
        json_response(['success' => false, 'message' => 'Photo must be a JPEG or PNG image'], 400);
    }

    if (!is_dir(JOB_PHOTO_UPLOAD_DIR) && !mkdir(JOB_PHOTO_UPLOAD_DIR, 0755, true) && !is_dir(JOB_PHOTO_UPLOAD_DIR)) {
        json_response(['success' => false, 'message' => 'Could not prepare upload directory'], 500);
    }

    $fileName = $bookingId . '_' . $suffix . '_' . time() . '.' . $allowedTypes[$mimeType];
    $destination = JOB_PHOTO_UPLOAD_DIR . '/' . $fileName;

    if (!move_uploaded_file($file['tmp_name'], $destination)) {
        json_response(['success' => false, 'message' => 'Could not save photo'], 500);
    }

    return $fileName;
}

if ($action === 'on_the_way') {
    if ($booking['status'] !== 'ACCEPTED') {
        json_response(['success' => false, 'message' => 'Job must be accepted before marking on the way'], 409);
    }
    sync_order_status($bookingId, 'technician_on_the_way', 'Technician is on the way');
    json_response(['success' => true, 'status' => 'ACCEPTED']);
}

if ($action === 'start') {
    if ($booking['status'] !== 'ACCEPTED') {
        json_response(['success' => false, 'message' => 'Job must be accepted before it can be started'], 409);
    }

    $beforePhoto = save_job_photo('before_photo', $bookingId, 'before');

    $stmt = db()->prepare(
        'UPDATE bookings SET status = "IN_PROGRESS", started_at = NOW()' .
        ($beforePhoto ? ', before_photo_path = :photo' : '') .
        ' WHERE id = :id'
    );
    $params = ['id' => $bookingId];
    if ($beforePhoto) {
        $params['photo'] = $beforePhoto;
    }
    $stmt->execute($params);

    sync_order_status($bookingId, 'service_started', 'Technician started the service');

    json_response(['success' => true, 'status' => 'IN_PROGRESS']);
}

if ($action === 'complete') {
    if ($booking['status'] !== 'IN_PROGRESS') {
        json_response(['success' => false, 'message' => 'Job must be in progress before it can be completed'], 409);
    }

    $otpEntered = trim((string)($_POST['completion_otp'] ?? ''));
    if (!hash_equals((string)$booking['completion_otp'], $otpEntered)) {
        json_response(['success' => false, 'message' => 'Incorrect completion OTP'], 401);
    }

    $afterPhoto = save_job_photo('after_photo', $bookingId, 'after');
    $signaturePhoto = save_job_photo('customer_signature', $bookingId, 'signature');

    // Completion report fields - self-heal columns since bookings-schema.sql
    // predates this (this is the live completion flow the app actually
    // calls; the separate complete-job.php/job_completion_screen.dart never
    // gets reached from any navigation, so those fields live here instead).
    $reportColumns = [
        'work_description' => 'TEXT NULL',
        'parts_used' => 'TEXT NULL',
        'additional_charges' => 'DECIMAL(10,2) NULL',
        'technician_remarks' => 'TEXT NULL',
        'customer_signature_path' => 'VARCHAR(255) NULL',
    ];
    foreach ($reportColumns as $col => $definition) {
        $checkCol = db()->prepare(
            "SELECT COUNT(*) FROM information_schema.columns
             WHERE table_schema = DATABASE() AND table_name = 'bookings' AND column_name = ?"
        );
        $checkCol->execute([$col]);
        if ((int)$checkCol->fetchColumn() === 0) {
            db()->exec("ALTER TABLE bookings ADD COLUMN `$col` $definition");
        }
    }

    $workDescription = trim((string)($_POST['work_description'] ?? ''));
    $partsUsed = trim((string)($_POST['parts_used'] ?? ''));
    $additionalCharges = isset($_POST['additional_charges']) && $_POST['additional_charges'] !== ''
        ? (float)$_POST['additional_charges']
        : null;
    $technicianRemarks = trim((string)($_POST['technician_remarks'] ?? ''));

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'UPDATE bookings SET status = "COMPLETED", completed_at = NOW(),
                work_description = :work_description, parts_used = :parts_used,
                additional_charges = :additional_charges, technician_remarks = :technician_remarks' .
            ($afterPhoto ? ', after_photo_path = :photo' : '') .
            ($signaturePhoto ? ', customer_signature_path = :signature' : '') .
            ' WHERE id = :id'
        );
        $params = [
            'id' => $bookingId,
            'work_description' => $workDescription ?: null,
            'parts_used' => $partsUsed ?: null,
            'additional_charges' => $additionalCharges,
            'technician_remarks' => $technicianRemarks ?: null,
        ];
        if ($afterPhoto) {
            $params['photo'] = $afterPhoto;
        }
        if ($signaturePhoto) {
            $params['signature'] = $signaturePhoto;
        }
        $stmt->execute($params);

        $totalEarning = (float)$booking['amount'] + ($additionalCharges ?? 0);
        $pdo->prepare(
            'INSERT INTO vendor_ledger (vendor_id, booking_id, entry_type, amount, description)
             VALUES (:vendor_id, :booking_id, "JOB_EARNING", :amount, :description)'
        )->execute([
            'vendor_id' => $vendorId,
            'booking_id' => $bookingId,
            'amount' => $totalEarning,
            'description' => $booking['service_type'],
        ]);

        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        json_response(['success' => false, 'message' => 'Could not complete job'], 500);
    }

    sync_order_status($bookingId, 'service_completed', 'Service completed');

    json_response(['success' => true, 'status' => 'COMPLETED']);
}

// cancel
if (!in_array($booking['status'], ['ACCEPTED', 'IN_PROGRESS'], true)) {
    json_response(['success' => false, 'message' => 'Job cannot be cancelled from its current status'], 409);
}

db()->prepare('UPDATE bookings SET status = "CANCELLED", cancelled_at = NOW() WHERE id = :id')
    ->execute(['id' => $bookingId]);

sync_order_status($bookingId, 'cancelled', 'Job cancelled by technician');

json_response(['success' => true, 'status' => 'CANCELLED']);
