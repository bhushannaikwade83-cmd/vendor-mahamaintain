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
$rawPanData = $input['pan_data'] ?? []; // Raw PAN JSON from DigiLocker

if ($vendorId <= 0 || empty($rawPanData)) {
    json_response(['error' => 'vendor_id and pan_data required'], 400);
}

try {
    // Extract fields from DigiLocker PAN response
    // DigiLocker returns PAN certificate data
    $panNumber = extractField($rawPanData, ['pan', 'panNumber', 'pan_number'], null);
    $name = extractField($rawPanData, ['name', 'pan_holder_name', 'full_name'], null);
    $fatherName = extractField($rawPanData, ['father_name', 'fathers_name', 'fathersName'], null);
    $dob = extractField($rawPanData, ['dob', 'dateOfBirth', 'date_of_birth'], null);

    if (!$panNumber || !$name) {
        json_response(['error' => 'Could not extract name and PAN number from data'], 400);
    }

    // Validate PAN format (10 alphanumeric)
    if (!preg_match('/^[A-Z0-9]{10}$/', $panNumber)) {
        json_response(['error' => 'Invalid PAN format'], 400);
    }

    // Normalize DOB format
    if ($dob) {
        $dob = normalizeDate($dob);
    }

    // Update vendor_digilocker_documents with extracted data
    $pdo = db();
    $stmt = $pdo->prepare(
        'INSERT INTO vendor_digilocker_documents
        (vendor_id, document_type, pan_number, pan_name, pan_father_name, pan_dob, raw_json_data)
        VALUES (:vendor_id, :doctype, :pan_number, :name, :father_name, :dob, :raw_json)
        ON DUPLICATE KEY UPDATE
            pan_number = :pan_number,
            pan_name = :name,
            pan_father_name = :father_name,
            pan_dob = :dob,
            raw_json_data = :raw_json,
            updated_at = NOW()'
    );

    $stmt->execute([
        'vendor_id' => $vendorId,
        'doctype' => 'PANCR',
        'pan_number' => $panNumber,
        'name' => $name,
        'father_name' => $fatherName,
        'dob' => $dob,
        'raw_json' => json_encode($rawPanData),
    ]);

    // Verify name consistency with Aadhaar if present
    $aadhaarStmt = $pdo->prepare(
        'SELECT aadhaar_name FROM vendor_digilocker_documents
        WHERE vendor_id = :vendor_id AND document_type = "ADHAR" LIMIT 1'
    );
    $aadhaarStmt->execute(['vendor_id' => $vendorId]);
    $aadhaarDoc = $aadhaarStmt->fetch();

    $nameMatchWarning = null;
    if ($aadhaarDoc && !isSimilarName($name, $aadhaarDoc['aadhaar_name'])) {
        $nameMatchWarning = 'PAN name does not match Aadhaar name - manual review recommended';
    }

    json_response([
        'success' => true,
        'vendor_id' => $vendorId,
        'extracted' => [
            'pan_number' => maskPan($panNumber),
            'name' => $name,
            'father_name' => $fatherName,
            'dob' => $dob,
        ],
        'warning' => $nameMatchWarning,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['error' => $e->getMessage()], 500);
}

/**
 * Extract field from nested array, trying multiple possible keys
 */
function extractField(array $data, array $keys, $default = null) {
    foreach ($keys as $key) {
        if (isset($data[$key])) {
            return $data[$key];
        }
    }
    return $default;
}

/**
 * Normalize various date formats to YYYY-MM-DD
 */
function normalizeDate(string $dateStr): ?string {
    $dateStr = trim($dateStr);

    $formats = ['Y-m-d', 'd-m-Y', 'm/d/Y', 'Y/m/d', 'd/m/Y'];
    foreach ($formats as $format) {
        $parsed = DateTime::createFromFormat($format, $dateStr);
        if ($parsed !== false) {
            return $parsed->format('Y-m-d');
        }
    }

    return null;
}

/**
 * Mask PAN for display (show only last 4 characters)
 */
function maskPan(string $pan): string {
    if (strlen($pan) < 4) return $pan;
    return str_repeat('X', strlen($pan) - 4) . substr($pan, -4);
}

/**
 * Compare names with fuzzy matching (handles minor variations)
 */
function isSimilarName(string $name1, string $name2): bool {
    $name1 = strtolower(trim($name1));
    $name2 = strtolower(trim($name2));

    // Exact match
    if ($name1 === $name2) return true;

    // Check if one is substring of other
    if (strpos($name1, $name2) !== false || strpos($name2, $name1) !== false) {
        return true;
    }

    // Levenshtein distance for typos (allow up to 2 characters difference)
    $distance = levenshtein($name1, $name2);
    return $distance <= 2;
}
?>
