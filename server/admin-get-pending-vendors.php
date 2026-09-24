<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_response(['error' => 'GET required'], 405);
}

$limit = (int)($_GET['limit'] ?? 50);
$offset = (int)($_GET['offset'] ?? 0);
$status = trim($_GET['status'] ?? 'UNDER_REVIEW'); // UNDER_REVIEW, DIGILOCKER_CONNECTED, UNVERIFIED, REJECTED

// Validate inputs
if ($limit < 1 || $limit > 500) $limit = 50;
if ($offset < 0) $offset = 0;

$validStatuses = ['UNDER_REVIEW', 'DIGILOCKER_CONNECTED', 'UNVERIFIED', 'REJECTED', 'VERIFIED'];
if (!in_array($status, $validStatuses)) {
    json_response(['error' => 'Invalid status filter'], 400);
}

try {
    $pdo = db();

    // Get total count
    $countStmt = $pdo->prepare(
        'SELECT COUNT(*) as total FROM vendors v
        LEFT JOIN vendor_verifications vv ON v.id = vv.vendor_id
        WHERE COALESCE(vv.verification_status, "UNVERIFIED") = :status'
    );
    $countStmt->execute(['status' => $status]);
    $countResult = $countStmt->fetch();
    $totalCount = (int)$countResult['total'];

    // Get paginated list with documents
    $listStmt = $pdo->prepare(
        'SELECT
            v.id,
            v.name,
            v.phone,
            v.email,
            v.status as vendor_status,
            v.created_at as vendor_created_at,
            vv.verification_status,
            vv.digilocker_connected,
            vv.digilocker_verified_at,
            vv.document_count,
            vv.all_documents_verified,
            vv.identity_verified,
            vv.pan_verified,
            vv.admin_review_notes,
            vv.admin_reviewed_at,
            vv.admin_reviewed_by,
            COUNT(DISTINCT vdd.id) as stored_documents
        FROM vendors v
        LEFT JOIN vendor_verifications vv ON v.id = vv.vendor_id
        LEFT JOIN vendor_digilocker_documents vdd ON v.id = vdd.vendor_id
        WHERE COALESCE(vv.verification_status, "UNVERIFIED") = :status
        GROUP BY v.id
        ORDER BY v.created_at DESC
        LIMIT :limit OFFSET :offset'
    );

    $listStmt->bindValue(':status', $status, PDO::PARAM_STR);
    $listStmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $listStmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $listStmt->execute();
    $vendors = $listStmt->fetchAll();

    // Get documents for each vendor
    $vendorData = [];
    foreach ($vendors as $vendor) {
        $docStmt = $pdo->prepare(
            'SELECT
                document_type,
                aadhaar_number,
                aadhaar_name,
                pan_number,
                pan_name,
                license_number,
                license_holder_name,
                issue_date,
                expiry_date
            FROM vendor_digilocker_documents
            WHERE vendor_id = :vendor_id
            ORDER BY created_at DESC'
        );
        $docStmt->execute(['vendor_id' => (int)$vendor['id']]);
        $vendor['documents'] = $docStmt->fetchAll();

        $vendorData[] = $vendor;
    }

    json_response([
        'success' => true,
        'status_filter' => $status,
        'pagination' => [
            'limit' => $limit,
            'offset' => $offset,
            'total' => $totalCount,
            'has_more' => ($offset + $limit) < $totalCount,
        ],
        'vendors' => $vendorData,
        'vendor_count' => count($vendorData),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['error' => $e->getMessage()], 500);
}
?>
