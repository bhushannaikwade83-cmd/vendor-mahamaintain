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
$isOnline = filter_var($input['is_online'] ?? null, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);

if ($isOnline === null) {
    json_response(['success' => false, 'message' => 'is_online is required'], 400);
}

$stmt = db()->prepare('UPDATE vendors SET is_online = :is_online WHERE id = :vendor_id');
$stmt->execute(['is_online' => $isOnline ? 1 : 0, 'vendor_id' => $vendorId]);

json_response(['success' => true, 'is_online' => $isOnline]);
