<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

$stmt = db()->prepare('SELECT status, uploaded_at, reviewed_at FROM vendor_selfies WHERE vendor_id = :vendor_id LIMIT 1');
$stmt->execute(['vendor_id' => $vendorId]);
$row = $stmt->fetch();

if (!$row) {
    json_response(['status' => 'NOT_SUBMITTED']);
}

json_response([
    'status' => $row['status'],
    'uploaded_at' => $row['uploaded_at'],
    'reviewed_at' => $row['reviewed_at'],
]);
