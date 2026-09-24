<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

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
$documents = $input['documents'] ?? []; // Array of document objects from DigiLocker

if ($vendorId <= 0 || empty($documents)) {
    json_response(['error' => 'vendor_id and documents array required'], 400);
}

try {
    $pdo = db();
    $stored = 0;
    $errors = [];

    foreach ($documents as $doc) {
        $docType = trim((string)($doc['doctype'] ?? ''));
        $docId = trim((string)($doc['id'] ?? ''));
        $rawData = json_encode($doc);

        if (!$docType || !$docId) {
            $errors[] = 'Document missing doctype or id';
            continue;
        }

        try {
            // Store document with extracted data based on type
            $stmt = $pdo->prepare(
                'INSERT INTO vendor_digilocker_documents
                (vendor_id, document_type, document_id, raw_json_data)
                VALUES (:vendor_id, :doctype, :docid, :raw_json)
                ON DUPLICATE KEY UPDATE
                    raw_json_data = :raw_json,
                    updated_at = NOW()'
            );

            $stmt->execute([
                'vendor_id' => $vendorId,
                'doctype' => $docType,
                'docid' => $docId,
                'raw_json' => $rawData,
            ]);

            $stored++;

            // Update document count in vendor_verifications
            $pdo->prepare(
                'UPDATE vendor_verifications
                SET document_count = (
                    SELECT COUNT(*) FROM vendor_digilocker_documents WHERE vendor_id = :vendor_id
                )
                WHERE vendor_id = :vendor_id'
            )->execute(['vendor_id' => $vendorId]);

        } catch (PDOException $e) {
            $errors[] = "Failed to store $docType: " . $e->getMessage();
        }
    }

    json_response([
        'success' => true,
        'stored_count' => $stored,
        'total_submitted' => count($documents),
        'errors' => $errors,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['error' => $e->getMessage()], 500);
}
?>
