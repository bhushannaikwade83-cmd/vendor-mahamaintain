<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

$vendorId = trim((string)($_GET['vendor_id'] ?? ''));
if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

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
