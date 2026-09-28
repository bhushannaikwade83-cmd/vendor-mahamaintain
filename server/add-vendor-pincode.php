<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();
header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

try {
    $data = json_decode(file_get_contents('php://input'), true);
    $pincode = trim($data['pincode'] ?? '');

    if (!preg_match('/^\d{5,6}$/', $pincode)) {
        http_response_code(400);
        json_response(['success' => false, 'message' => 'Invalid pincode format']);
        return;
    }

    // Check if already exists
    $check = db()->prepare('SELECT id FROM vendor_pincodes WHERE vendor_id = :vendor_id AND pincode = :pincode');
    $check->execute(['vendor_id' => $vendorId, 'pincode' => $pincode]);
    if ($check->fetch()) {
        http_response_code(400);
        json_response(['success' => false, 'message' => 'This pincode is already registered']);
        return;
    }

    // Insert
    $stmt = db()->prepare('INSERT INTO vendor_pincodes (vendor_id, pincode) VALUES (:vendor_id, :pincode)');
    $stmt->execute(['vendor_id' => $vendorId, 'pincode' => $pincode]);

    json_response([
        'success' => true,
        'message' => 'Pincode added successfully',
        'pincode' => [
            'id' => db()->lastInsertId(),
            'pincode' => $pincode,
            'created_at' => date('Y-m-d H:i:s'),
        ],
    ]);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'message' => 'Failed to add pincode: ' . $e->getMessage()]);
}
