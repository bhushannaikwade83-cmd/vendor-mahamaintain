<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

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

$vendorId = (int)($_GET['vendor_id'] ?? 0);
$docType = trim($_GET['document_type'] ?? ''); // Optional filter by type

if ($vendorId <= 0) {
    json_response(['error' => 'vendor_id required'], 400);
}

try {
    $pdo = db();

    $query = 'SELECT
        id,
        vendor_id,
        document_type,
        document_id,
        aadhaar_number,
        aadhaar_name,
        aadhaar_dob,
        aadhaar_gender,
        pan_number,
        pan_name,
        license_number,
        license_holder_name,
        license_valid_till,
        issue_date,
        expiry_date,
        created_at,
        updated_at
    FROM vendor_digilocker_documents
    WHERE vendor_id = :vendor_id';

    $params = ['vendor_id' => $vendorId];

    if (!empty($docType)) {
        $query .= ' AND document_type = :doctype';
        $params['doctype'] = $docType;
    }

    $query .= ' ORDER BY created_at DESC';

    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    $documents = $stmt->fetchAll();

    json_response([
        'success' => true,
        'vendor_id' => $vendorId,
        'documents' => $documents,
        'document_count' => count($documents),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['error' => $e->getMessage()], 500);
}
?>
