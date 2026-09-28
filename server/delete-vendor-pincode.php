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
    $pincodeId = (int)($data['id'] ?? 0);

    if ($pincodeId <= 0) {
        http_response_code(400);
        json_response(['success' => false, 'message' => 'Invalid pincode ID']);
        return;
    }

    // Verify ownership
    $check = db()->prepare('SELECT vendor_id FROM vendor_pincodes WHERE id = :id');
    $check->execute(['id' => $pincodeId]);
    $row = $check->fetch();
    
    if (!$row || $row['vendor_id'] !== $vendorId) {
        http_response_code(403);
        json_response(['success' => false, 'message' => 'Not authorized']);
        return;
    }

    // Delete
    $stmt = db()->prepare('DELETE FROM vendor_pincodes WHERE id = :id');
    $stmt->execute(['id' => $pincodeId]);

    json_response(['success' => true, 'message' => 'Pincode removed']);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'message' => 'Failed to delete pincode']);
}
