<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

// Kicks off a Razorpay Fund Account Validation (penny-drop) for a vendor's
// bank account. This only starts the check - the result arrives later via
// bank_verify_webhook.php, and the Flutter app polls bank_verify_status.php.

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'POST required'], 405);
}

$input = json_decode((string)file_get_contents('php://input'), true);
$vendorId = trim((string)($input['vendor_id'] ?? ''));
$holderName = trim((string)($input['account_holder_name'] ?? ''));
$accountNumber = trim((string)($input['account_number'] ?? ''));
$ifsc = strtoupper(trim((string)($input['ifsc_code'] ?? '')));

if ($vendorId === '' || $holderName === '' || $accountNumber === '' || $ifsc === '') {
    json_response(['error' => 'vendor_id, account_holder_name, account_number and ifsc_code are required'], 400);
}

if (!preg_match('/^[A-Z]{4}0[A-Z0-9]{6}$/', $ifsc)) {
    json_response(['error' => 'Invalid IFSC code'], 400);
}

function razorpay_request(string $method, string $path, array $body): array
{
    $ch = curl_init(RAZORPAY_API_BASE . $path);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_USERPWD => RAZORPAY_KEY_ID . ':' . RAZORPAY_KEY_SECRET,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => json_encode($body),
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [$httpCode, json_decode((string)$response, true) ?? []];
}

// 1. Create (or reuse) a Razorpay contact for this vendor.
[$contactCode, $contact] = razorpay_request('POST', '/contacts', [
    'name' => $holderName,
    'type' => 'vendor',
    'reference_id' => $vendorId,
]);

if ($contactCode >= 300 || !isset($contact['id'])) {
    json_response(['error' => 'Could not start bank verification (contact)', 'details' => $contact], 502);
}

// 2. Create a fund account (the bank account) for that contact.
[$fundAccountCode, $fundAccount] = razorpay_request('POST', '/fund_accounts', [
    'contact_id' => $contact['id'],
    'account_type' => 'bank_account',
    'bank_account' => [
        'name' => $holderName,
        'ifsc' => $ifsc,
        'account_number' => $accountNumber,
    ],
]);

if ($fundAccountCode >= 300 || !isset($fundAccount['id'])) {
    json_response(['error' => 'Could not start bank verification (fund account)', 'details' => $fundAccount], 502);
}

// 3. Trigger the penny-drop validation. Result arrives via webhook.
[$validationCode, $validation] = razorpay_request('POST', '/fund_accounts/validations', [
    'account_number' => $accountNumber,
    'fund_account' => ['id' => $fundAccount['id']],
    'amount' => 100, // paise - minimum amount Razorpay credits back for validation
    'currency' => 'INR',
]);

if ($validationCode >= 300 || !isset($validation['id'])) {
    json_response(['error' => 'Could not start bank verification (validation)', 'details' => $validation], 502);
}

$last4 = substr($accountNumber, -4);

try {
    db()->prepare(
        'INSERT INTO vendor_bank_accounts
            (vendor_id, account_holder_name, account_number_last4, ifsc_code,
             razorpay_contact_id, razorpay_fund_account_id, razorpay_validation_id,
             verification_status)
         VALUES
            (:vendor_id, :holder_name, :last4, :ifsc,
             :contact_id, :fund_account_id, :validation_id, "PENDING")
         ON DUPLICATE KEY UPDATE
            account_holder_name = VALUES(account_holder_name),
            account_number_last4 = VALUES(account_number_last4),
            ifsc_code = VALUES(ifsc_code),
            razorpay_contact_id = VALUES(razorpay_contact_id),
            razorpay_fund_account_id = VALUES(razorpay_fund_account_id),
            razorpay_validation_id = VALUES(razorpay_validation_id),
            registered_name = NULL,
            name_match = NULL,
            verification_status = "PENDING",
            verified_at = NULL'
    )->execute([
        'vendor_id' => $vendorId,
        'holder_name' => $holderName,
        'last4' => $last4,
        'ifsc' => $ifsc,
        'contact_id' => $contact['id'],
        'fund_account_id' => $fundAccount['id'],
        'validation_id' => $validation['id'],
    ]);
} catch (PDOException $e) {
    json_response(['error' => 'Database error'], 500);
}

json_response(['status' => 'PENDING']);
