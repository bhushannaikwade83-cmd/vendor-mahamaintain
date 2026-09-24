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
$rejectionReason = trim((string)($input['rejection_reason'] ?? ''));
$notes = trim((string)($input['notes'] ?? ''));

if ($vendorId <= 0 || empty($rejectionReason)) {
    json_response(['error' => 'vendor_id and rejection_reason required'], 400);
}

try {
    $pdo = db();

    // Verify vendor exists and is in rejectable status
    $vendorStmt = $pdo->prepare(
        'SELECT v.id, v.name, vv.verification_status
        FROM vendors v
        LEFT JOIN vendor_verifications vv ON v.id = vv.vendor_id
        WHERE v.id = :vendor_id LIMIT 1'
    );
    $vendorStmt->execute(['vendor_id' => $vendorId]);
    $vendor = $vendorStmt->fetch();

    if (!$vendor) {
        json_response(['error' => 'Vendor not found'], 404);
    }

    $previousStatus = $vendor['verification_status'] ?? 'UNVERIFIED';

    // Can reject from UNDER_REVIEW, DIGILOCKER_CONNECTED, or UNVERIFIED
    $rejectableStatuses = ['UNDER_REVIEW', 'DIGILOCKER_CONNECTED', 'UNVERIFIED'];
    if (!in_array($previousStatus, $rejectableStatuses)) {
        json_response([
            'error' => 'Vendor can only be rejected from UNDER_REVIEW, DIGILOCKER_CONNECTED, or UNVERIFIED status',
            'current_status' => $previousStatus
        ], 400);
    }

    // Update verification status to REJECTED
    $updateStmt = $pdo->prepare(
        'UPDATE vendor_verifications SET
            verification_status = "REJECTED",
            all_documents_verified = 0,
            admin_review_notes = :notes,
            admin_reviewed_at = NOW(),
            admin_reviewed_by = :admin_name,
            updated_at = NOW()
        WHERE vendor_id = :vendor_id'
    );

    $updateStmt->execute([
        'notes' => ($rejectionReason . (empty($notes) ? '' : "\n\nAdditional notes: " . $notes)),
        'admin_name' => $adminName,
        'vendor_id' => $vendorId,
    ]);

    // Also update vendor status to suspended
    $pdo->prepare(
        'UPDATE vendors SET status = "suspended", updated_at = NOW() WHERE id = :vendor_id'
    )->execute(['vendor_id' => $vendorId]);

    // Log the rejection action
    $pdo->prepare(
        'INSERT INTO vendor_verification_history
        (vendor_id, action, previous_status, new_status, admin_id, admin_name, rejection_reason, notes)
        VALUES (:vendor_id, "rejected", :prev_status, "REJECTED", :admin_id, :admin_name, :reason, :notes)'
    )->execute([
        'vendor_id' => $vendorId,
        'prev_status' => $previousStatus,
        'admin_id' => $adminId ?: null,
        'admin_name' => $adminName,
        'reason' => $rejectionReason,
        'notes' => $notes ?: null,
    ]);

    json_response([
        'success' => true,
        'vendor_id' => $vendorId,
        'vendor_name' => $vendor['name'],
        'new_status' => 'REJECTED',
        'rejection_reason' => $rejectionReason,
        'message' => 'Vendor rejected successfully',
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['error' => $e->getMessage()], 500);
}
?>
