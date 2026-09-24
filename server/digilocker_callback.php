<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

// DigiLocker redirects the vendor's browser here after they sign in and
// grant (or deny) consent. This runs on the server only - the Flutter app
// never sees the authorization code or the client secret.

// The Flutter app registers this custom scheme (see AndroidManifest.xml /
// Info.plist + lib/config/deep_link_service.dart) so DigiLocker's callback
// page can jump straight back into it instead of leaving the vendor
// stranded in the browser.
define('APP_RETURN_URL', 'mahavendor://digilocker-callback');

function render_result_page(string $title, string $message, bool $success): void
{
    http_response_code(200);
    header('Content-Type: text/html; charset=utf-8');
    $color = $success ? '#059669' : '#DC2626';
    $icon = $success ? '&#10003;' : '&#10007;';
    $safeTitle = htmlspecialchars($title, ENT_QUOTES);
    $safeMessage = htmlspecialchars($message, ENT_QUOTES);
    $returnUrl = APP_RETURN_URL;
    echo <<<HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Verification</title>
  <style>
    body { font-family: -apple-system, "Segoe UI", Roboto, sans-serif; background:#F4F5F9; display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; padding:16px; box-sizing:border-box; }
    .card { background:#fff; border-radius:20px; padding:32px 24px; text-align:center; box-shadow:0 8px 24px rgba(0,0,0,0.08); max-width:340px; }
    .badge { width:56px; height:56px; border-radius:50%; background:$color; color:#fff; font-size:28px; display:flex; align-items:center; justify-content:center; margin:0 auto 16px; }
    h2 { margin:0 0 8px; color:#1A1A2E; font-size:18px; }
    p { color:#545470; font-size:14px; line-height:1.5; }
    a.button { display:inline-block; margin-top:20px; padding:12px 24px; background:#F25C05; color:#fff; text-decoration:none; border-radius:14px; font-weight:600; font-size:14px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">$icon</div>
    <h2>$safeTitle</h2>
    <p>$safeMessage</p>
    <a class="button" href="$returnUrl">Return to App</a>
  </div>
  <script>
    // Best-effort automatic return - some mobile browsers block a
    // programmatic scheme redirect, which is why the button above still
    // exists as a guaranteed fallback (a real tap always works).
    setTimeout(function () { window.location.href = "$returnUrl"; }, 400);
  </script>
</body>
</html>
HTML;
    exit;
}

// DEBUG: Log the exact callback request
error_log('=== DIGILOCKER CALLBACK ===');
error_log('REQUEST_URI: ' . ($_SERVER['REQUEST_URI'] ?? 'N/A'));
error_log('QUERY_STRING: ' . ($_SERVER['QUERY_STRING'] ?? 'N/A'));
error_log('GET Parameters: ' . print_r($_GET, true));
error_log('==========================');

$code = $_GET['code'] ?? null;
$state = $_GET['state'] ?? null;
$authError = $_GET['error'] ?? null;
$errorDescription = $_GET['error_description'] ?? null;

if ($authError) {
    error_log('DigiLocker Error: ' . $authError);
    if ($errorDescription) {
        error_log('Error Description: ' . $errorDescription);
    }
    render_result_page(
        'DigiLocker Error',
        'Error: ' . $authError . ($errorDescription ? ' - ' . $errorDescription : ''),
        false
    );
}

if (!$code || !$state) {
    render_result_page('Invalid Request', 'This verification link is invalid. Please try again from the app.', false);
}

$stmt = db()->prepare('SELECT * FROM digilocker_oauth_sessions WHERE state_token = :state LIMIT 1');
$stmt->execute(['state' => $state]);
$session = $stmt->fetch();

if (!$session || $session['status'] !== 'INITIATED' || strtotime($session['expires_at']) < time()) {
    render_result_page('Link Expired', 'This verification link has expired. Please start again from the app.', false);
}

$vendorId = $session['vendor_id'];

// --- Exchange the authorization code for an access token -----------------
// Server-to-server call; the client secret never leaves this backend.
$ch = curl_init(DIGILOCKER_TOKEN_URL);

$tokenPostFields = [
    'grant_type' => 'authorization_code',
    'code' => $code,
    'client_id' => DIGILOCKER_CLIENT_ID,
    'client_secret' => DIGILOCKER_CLIENT_SECRET,
    'redirect_uri' => DIGILOCKER_REDIRECT_URI,
    'code_verifier' => $session['code_verifier'],  // PKCE: Include code_verifier
];

curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 20,
    CURLOPT_POSTFIELDS => http_build_query($tokenPostFields),
]);
$tokenResponse = curl_exec($ch);
$tokenHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

// Log for debugging
error_log("DigiLocker Token Response: HTTP $tokenHttpCode");
error_log("DigiLocker Token Body: $tokenResponse");
if ($curlError) error_log("DigiLocker cURL Error: $curlError");

$tokenData = json_decode((string)$tokenResponse, true) ?? [];
$accessToken = $tokenData['access_token'] ?? null;

if ($tokenHttpCode !== 200 || !$accessToken) {
    db()->prepare('UPDATE digilocker_oauth_sessions SET status = "FAILED" WHERE id = :id')
        ->execute(['id' => $session['id']]);

    $errorMsg = $tokenData['error_description'] ?? ($tokenData['error'] ?? 'Unknown error');
    error_log("DigiLocker Auth Failed: $errorMsg (HTTP $tokenHttpCode)");

    render_result_page('Verification Failed', "DigiLocker error: $errorMsg. Please try again from the app.", false);
}

// --- Fetch the vendor's issued documents ----------------------------------
$ch = curl_init(DIGILOCKER_ISSUED_DOCS_URL);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 20,
    CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . $accessToken],
]);
$docsResponse = curl_exec($ch);
curl_close($ch);

$docsData = json_decode((string)$docsResponse, true) ?? [];
error_log('=== DIGILOCKER DOCUMENTS RESPONSE ===');
error_log(print_r($docsData, true));
error_log('=====================================');

$issuedDocTypes = array_map(
    fn($doc) => (string)($doc['doctype'] ?? ''),
    $docsData['items'] ?? []
);
error_log('Extracted Document Types: ' . implode(', ', $issuedDocTypes));

// access token is intentionally not persisted anywhere - we only use it to
// pull the document list above, then discard it.

// PAN + Driving License are checked (REQUIRED_DOC_TYPES in config.php)
$panVerified = in_array('PANCR', $issuedDocTypes, true);
$dlVerified = in_array('DRIVINGLICENSE', $issuedDocTypes, true);

$requiredMet = true;
foreach (REQUIRED_DOC_TYPES as $required) {
    if (!in_array($required, $issuedDocTypes, true)) {
        $requiredMet = false;
        break;
    }
}

// DigiLocker connecting successfully does NOT automatically mean the vendor
// is approved - that's still your team's call. We mark it UNDER_REVIEW so
// an admin can review before flipping it to VERIFIED.
$status = $requiredMet ? 'UNDER_REVIEW' : 'DIGILOCKER_CONNECTED';

db()->prepare(
    'UPDATE vendor_verifications SET
        verification_status = :status,
        digilocker_connected = 1,
        digilocker_verified_at = NOW(),
        pan_verified = :pan,
        updated_at = NOW()
     WHERE vendor_id = :vendor_id'
)->execute([
    'status' => $status,
    'pan' => $panVerified ? 1 : 0,
    'vendor_id' => $vendorId,
]);

db()->prepare('UPDATE digilocker_oauth_sessions SET status = "COMPLETED" WHERE id = :id')
    ->execute(['id' => $session['id']]);

render_result_page(
    $requiredMet ? 'DigiLocker Verified' : 'DigiLocker Connected',
    $requiredMet
        ? 'Your PAN and Driving License have been verified. You can close this window and return to the app.'
        : 'PAN or Driving License not found in your DigiLocker. You can close this window and return to the app.',
    true
);
