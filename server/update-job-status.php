<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'POST required'], 405);
}

// Multipart form (not JSON) - action determines which fields matter:
//   start    -> requires: vendor_id, booking_id. optional: before_photo file
//   complete -> requires: vendor_id, booking_id, completion_otp. optional: after_photo file
//   cancel   -> requires: vendor_id, booking_id
$vendorId = trim((string)($_POST['vendor_id'] ?? ''));
$bookingId = (int)($_POST['booking_id'] ?? 0);
$action = $_POST['action'] ?? '';

if ($vendorId === '' || $bookingId <= 0 || !in_array($action, ['start', 'complete', 'cancel'], true)) {
    json_response(['success' => false, 'message' => 'vendor_id, booking_id and a valid action are required'], 400);
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

    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'UPDATE bookings SET status = "COMPLETED", completed_at = NOW()' .
            ($afterPhoto ? ', after_photo_path = :photo' : '') .
            ' WHERE id = :id'
        );
        $params = ['id' => $bookingId];
        if ($afterPhoto) {
            $params['photo'] = $afterPhoto;
        }
        $stmt->execute($params);

        $pdo->prepare(
            'INSERT INTO vendor_ledger (vendor_id, booking_id, entry_type, amount, description)
             VALUES (:vendor_id, :booking_id, "JOB_EARNING", :amount, :description)'
        )->execute([
            'vendor_id' => $vendorId,
            'booking_id' => $bookingId,
            'amount' => $booking['amount'],
            'description' => $booking['service_type'],
        ]);

        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        json_response(['success' => false, 'message' => 'Could not complete job'], 500);
    }

    json_response(['success' => true, 'status' => 'COMPLETED']);
}

// cancel
if (!in_array($booking['status'], ['ACCEPTED', 'IN_PROGRESS'], true)) {
    json_response(['success' => false, 'message' => 'Job cannot be cancelled from its current status'], 409);
}

db()->prepare('UPDATE bookings SET status = "CANCELLED", cancelled_at = NOW() WHERE id = :id')
    ->execute(['id' => $bookingId]);

json_response(['success' => true, 'status' => 'CANCELLED']);
