<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'POST required'], 405);
}

$input = json_decode((string)file_get_contents('php://input'), true);
$vendorId = trim((string)($input['vendor_id'] ?? ''));

if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

$state = bin2hex(random_bytes(24));
$expiresAt = (new DateTime('+15 minutes'))->format('Y-m-d H:i:s');

try {
    db()->prepare(
        'INSERT INTO digilocker_oauth_sessions (vendor_id, state_token, status, expires_at)
         VALUES (:vendor_id, :state, "INITIATED", :expires_at)'
    )->execute([
        'vendor_id' => $vendorId,
        'state' => $state,
        'expires_at' => $expiresAt,
    ]);

    db()->prepare(
        'INSERT INTO vendor_verifications (vendor_id, verification_status)
         VALUES (:vendor_id, "UNVERIFIED")
         ON DUPLICATE KEY UPDATE vendor_id = vendor_id'
    )->execute(['vendor_id' => $vendorId]);
} catch (PDOException $e) {
    json_response(['error' => 'Database error'], 500);
}

$authorizationUrl = DIGILOCKER_AUTHORIZE_URL . '?' . http_build_query([
    'response_type' => 'code',
    'client_id' => DIGILOCKER_CLIENT_ID,
    'redirect_uri' => DIGILOCKER_REDIRECT_URI,
    'state' => $state,
]);

json_response([
    'authorization_url' => $authorizationUrl,
    'state' => $state,
]);
