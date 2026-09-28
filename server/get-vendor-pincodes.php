<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();
header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

try {
    $stmt = db()->prepare('SELECT id, pincode, created_at FROM vendor_pincodes WHERE vendor_id = :vendor_id ORDER BY pincode');
    $stmt->execute(['vendor_id' => $vendorId]);
    $pincodes = $stmt->fetchAll();

    json_response([
        'success' => true,
        'pincodes' => array_map(fn($row) => [
            'id' => (int)$row['id'],
            'pincode' => $row['pincode'],
            'created_at' => $row['created_at'],
        ], $pincodes),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'message' => 'Failed to fetch pincodes']);
}
