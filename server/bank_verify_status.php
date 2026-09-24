<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

$vendorId = trim((string)($_GET['vendor_id'] ?? ''));
if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

$stmt = db()->prepare('SELECT * FROM vendor_bank_accounts WHERE vendor_id = :vendor_id LIMIT 1');
$stmt->execute(['vendor_id' => $vendorId]);
$row = $stmt->fetch();

if (!$row) {
    json_response(['status' => 'NOT_SUBMITTED']);
}

json_response([
    'status' => $row['verification_status'],
    'account_holder_name' => $row['account_holder_name'],
    'account_number_last4' => $row['account_number_last4'],
    'ifsc_code' => $row['ifsc_code'],
    'registered_name' => $row['registered_name'],
    'name_match' => $row['name_match'] !== null ? (bool)$row['name_match'] : null,
    'verified_at' => $row['verified_at'],
]);
