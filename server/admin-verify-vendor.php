<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'POST required'], 405);
}

$input = json_decode(file_get_contents('php://input'), true) ?? [];
$vendorId = (int)($input['vendor_id'] ?? 0);
$adminId = (int)($input['admin_id'] ?? 0);
$adminName = trim((string)($input['admin_name'] ?? 'System'));
$notes = trim((string)($input['notes'] ?? ''));

if ($vendorId <= 0) {
    json_response(['error' => 'vendor_id required'], 400);
}

try {
    $pdo = db();

    // Verify vendor exists and is in UNDER_REVIEW status
    $vendorStmt = $pdo->prepare(
        'SELECT v.id, v.name, vv.verification_status, vv.document_count
        FROM vendors v
        LEFT JOIN vendor_verifications vv ON v.id = vv.vendor_id
        WHERE v.id = :vendor_id LIMIT 1'
    );
    $vendorStmt->execute(['vendor_id' => $vendorId]);
    $vendor = $vendorStmt->fetch();

    if (!$vendor) {
        json_response(['error' => 'Vendor not found'], 404);
    }

    if ($vendor['verification_status'] !== 'UNDER_REVIEW') {
        json_response([
            'error' => 'Vendor can only be verified from UNDER_REVIEW status',
            'current_status' => $vendor['verification_status']
        ], 400);
    }

    // Update verification status to VERIFIED
    $updateStmt = $pdo->prepare(
        'UPDATE vendor_verifications SET
            verification_status = "VERIFIED",
            all_documents_verified = 1,
            admin_review_notes = :notes,
            admin_reviewed_at = NOW(),
            admin_reviewed_by = :admin_name,
            updated_at = NOW()
        WHERE vendor_id = :vendor_id'
    );

    $updateStmt->execute([
        'notes' => $notes ?: null,
        'admin_name' => $adminName,
        'vendor_id' => $vendorId,
    ]);

    // Also update vendor status to active
    $pdo->prepare(
        'UPDATE vendors SET status = "active", updated_at = NOW() WHERE id = :vendor_id'
    )->execute(['vendor_id' => $vendorId]);

    // Log the verification action
    $pdo->prepare(
        'INSERT INTO vendor_verification_history
        (vendor_id, action, previous_status, new_status, admin_id, admin_name, notes)
        VALUES (:vendor_id, "verified", :prev_status, "VERIFIED", :admin_id, :admin_name, :notes)'
    )->execute([
        'vendor_id' => $vendorId,
        'prev_status' => $vendor['verification_status'],
        'admin_id' => $adminId ?: null,
        'admin_name' => $adminName,
        'notes' => $notes ?: null,
    ]);

    json_response([
        'success' => true,
        'vendor_id' => $vendorId,
        'vendor_name' => $vendor['name'],
        'new_status' => 'VERIFIED',
        'message' => 'Vendor verified successfully',
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['error' => $e->getMessage()], 500);
}
?>
