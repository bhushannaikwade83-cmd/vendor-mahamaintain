<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

// Razorpay calls this URL when a fund_account.validation.* event happens.
// Register it under Dashboard -> Account & Settings -> Webhooks, subscribed
// to "Fund Account Validation" events, with RAZORPAY_WEBHOOK_SECRET as the
// webhook secret.

header('Content-Type: application/json');

$rawBody = (string)file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_RAZORPAY_SIGNATURE'] ?? '';

$expectedSignature = hash_hmac('sha256', $rawBody, RAZORPAY_WEBHOOK_SECRET);
if (!hash_equals($expectedSignature, $signature)) {
    json_response(['error' => 'Invalid signature'], 400);
}

$payload = json_decode($rawBody, true) ?? [];
$event = $payload['event'] ?? '';

if (strpos($event, 'fund_account.validation.') !== 0) {
    // Not a validation event - acknowledge and ignore.
    json_response(['status' => 'ignored']);
}

$validation = $payload['payload']['fund_account.validation']['entity'] ?? null;
if (!$validation || !isset($validation['id'])) {
    json_response(['error' => 'Malformed payload'], 400);
}

$validationId = $validation['id'];
$status = $validation['status'] ?? 'created'; // created | completed | failed
$results = $validation['results'] ?? [];
$registeredName = $results['registered_name'] ?? null;
$accountStatus = $results['account_status'] ?? null; // active | invalid

$stmt = db()->prepare('SELECT * FROM vendor_bank_accounts WHERE razorpay_validation_id = :id LIMIT 1');
$stmt->execute(['id' => $validationId]);
$row = $stmt->fetch();

if (!$row) {
    // Nothing to update locally - still acknowledge so Razorpay stops retrying.
    json_response(['status' => 'ok']);
}

if ($status === 'completed' && $accountStatus === 'active') {
    $nameMatch = $registeredName !== null
        && similar_text_ratio($registeredName, $row['account_holder_name']) >= 0.8;

    db()->prepare(
        'UPDATE vendor_bank_accounts SET
            verification_status = "VERIFIED",
            registered_name = :registered_name,
            name_match = :name_match,
            verified_at = NOW(),
            updated_at = NOW()
         WHERE razorpay_validation_id = :id'
    )->execute([
        'registered_name' => $registeredName,
        'name_match' => $nameMatch ? 1 : 0,
        'id' => $validationId,
    ]);
} else {
    db()->prepare(
        'UPDATE vendor_bank_accounts SET
            verification_status = "FAILED",
            registered_name = :registered_name,
            updated_at = NOW()
         WHERE razorpay_validation_id = :id'
    )->execute([
        'registered_name' => $registeredName,
        'id' => $validationId,
    ]);
}

function similar_text_ratio(string $a, string $b): float
{
    similar_text(strtoupper(trim($a)), strtoupper(trim($b)), $percent);
    return $percent / 100;
}

json_response(['status' => 'ok']);
