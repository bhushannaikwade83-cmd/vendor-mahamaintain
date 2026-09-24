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
$rawAadhaarData = $input['aadhaar_data'] ?? []; // Raw Aadhaar JSON from DigiLocker

if ($vendorId <= 0 || empty($rawAadhaarData)) {
    json_response(['error' => 'vendor_id and aadhaar_data required'], 400);
}

try {
    // Extract fields from DigiLocker Aadhaar response
    // DigiLocker returns a structured JSON with demographic data
    $aadhaarNumber = extractField($rawAadhaarData, ['uid', 'id', 'aadhaarNumber'], null);
    $name = extractField($rawAadhaarData, ['name', 'full_name', 'fullname'], null);
    $dob = extractField($rawAadhaarData, ['dob', 'dateOfBirth', 'date_of_birth'], null);
    $gender = extractField($rawAadhaarData, ['gender', 'sex'], null);
    $address = extractField($rawAadhaarData, ['address', 'addr'], null);

    if (!$aadhaarNumber || !$name) {
        json_response(['error' => 'Could not extract name and Aadhaar number from data'], 400);
    }

    // Normalize DOB format
    if ($dob) {
        $dob = normalizeDate($dob);
    }

    // Update vendor_digilocker_documents with extracted data
    $pdo = db();
    $stmt = $pdo->prepare(
        'INSERT INTO vendor_digilocker_documents
        (vendor_id, document_type, aadhaar_number, aadhaar_name, aadhaar_dob, aadhaar_gender, aadhaar_address, raw_json_data)
        VALUES (:vendor_id, :doctype, :aadhaar_number, :name, :dob, :gender, :address, :raw_json)
        ON DUPLICATE KEY UPDATE
            aadhaar_number = :aadhaar_number,
            aadhaar_name = :name,
            aadhaar_dob = :dob,
            aadhaar_gender = :gender,
            aadhaar_address = :address,
            raw_json_data = :raw_json,
            updated_at = NOW()'
    );

    $stmt->execute([
        'vendor_id' => $vendorId,
        'doctype' => 'ADHAR',
        'aadhaar_number' => $aadhaarNumber,
        'name' => $name,
        'dob' => $dob,
        'gender' => $gender,
        'address' => $address,
        'raw_json' => json_encode($rawAadhaarData),
    ]);

    // Update vendor name if not already set
    $pdo->prepare(
        'UPDATE vendors SET name = :name WHERE id = :vendor_id AND (name IS NULL OR name = "")'
    )->execute([
        'name' => $name,
        'vendor_id' => $vendorId,
    ]);

    json_response([
        'success' => true,
        'vendor_id' => $vendorId,
        'extracted' => [
            'aadhaar_number' => maskAadhaar($aadhaarNumber),
            'name' => $name,
            'dob' => $dob,
            'gender' => $gender,
        ],
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

    // Try parsing various formats
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
 * Mask Aadhaar number for display (show only last 4 digits)
 */
function maskAadhaar(string $aadhaar): string {
    if (strlen($aadhaar) < 4) return $aadhaar;
    return 'XXXX XXXX ' . substr($aadhaar, -4);
}
?>
