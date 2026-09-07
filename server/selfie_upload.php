<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'POST required'], 405);
}

$vendorId = trim((string)($_POST['vendor_id'] ?? ''));
if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

if (!isset($_FILES['selfie']) || $_FILES['selfie']['error'] !== UPLOAD_ERR_OK) {
    json_response(['error' => 'selfie file is required'], 400);
}

$file = $_FILES['selfie'];

if ($file['size'] > SELFIE_MAX_BYTES) {
    json_response(['error' => 'Selfie is too large (max 5 MB)'], 400);
}

$allowedTypes = ['image/jpeg' => 'jpg', 'image/png' => 'png'];

// Prefer the fileinfo extension when available, but don't hard-depend on
// it - some shared hosts don't have it enabled, and finfo_open() returning
// false would otherwise crash finfo_file() with an uncaught TypeError.
$mimeType = null;
if (function_exists('finfo_open')) {
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    if ($finfo !== false) {
        $mimeType = finfo_file($finfo, $file['tmp_name']) ?: null;
        finfo_close($finfo);
    }
}
if ($mimeType === null) {
    // Fall back to sniffing the file's magic bytes directly.
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
    json_response(['error' => 'Selfie must be a JPEG or PNG image'], 400);
}

if (!is_dir(SELFIE_UPLOAD_DIR) && !mkdir(SELFIE_UPLOAD_DIR, 0750, true) && !is_dir(SELFIE_UPLOAD_DIR)) {
    json_response(['error' => 'Could not prepare upload directory'], 500);
}

// One selfie per vendor - overwrite any previous file for this vendor id.
$safeVendorId = preg_replace('/[^a-zA-Z0-9_.-]/', '_', $vendorId);
$fileName = $safeVendorId . '.' . $allowedTypes[$mimeType];
$destination = SELFIE_UPLOAD_DIR . '/' . $fileName;

if (!move_uploaded_file($file['tmp_name'], $destination)) {
    json_response(['error' => 'Could not save selfie'], 500);
}

try {
    db()->prepare(
        'INSERT INTO vendor_selfies (vendor_id, file_name, status, uploaded_at)
         VALUES (:vendor_id, :file_name, "PENDING", NOW())
         ON DUPLICATE KEY UPDATE
            file_name = VALUES(file_name),
            status = "PENDING",
            uploaded_at = NOW(),
            reviewed_at = NULL'
    )->execute([
        'vendor_id' => $vendorId,
        'file_name' => $fileName,
    ]);
} catch (PDOException $e) {
    json_response(['error' => 'Database error'], 500);
}

json_response(['status' => 'PENDING']);
