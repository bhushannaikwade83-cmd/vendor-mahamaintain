<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json');

$vendorId = trim((string)($_GET['vendor_id'] ?? ''));
if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

$stmt = db()->prepare('SELECT * FROM vendor_verifications WHERE vendor_id = :vendor_id LIMIT 1');
$stmt->execute(['vendor_id' => $vendorId]);
$row = $stmt->fetch();

if (!$row) {
    json_response([
        'status' => 'UNVERIFIED',
        'digilocker_connected' => false,
        'identity_verified' => false,
        'pan_verified' => false,
        'updated_at' => null,
    ]);
}

json_response([
    'status' => $row['verification_status'],
    'digilocker_connected' => (bool)$row['digilocker_connected'],
    'identity_verified' => (bool)$row['identity_verified'],
    'pan_verified' => (bool)$row['pan_verified'],
    'updated_at' => $row['updated_at'],
]);
