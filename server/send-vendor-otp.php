<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database credentials
$servername = "localhost";
$username = "digitrix_maha_user";
$password = "maha_user@70";
$dbname = "digitrix_maha_maintain_pro";

// SMS Gateway credentials (same gateway as the customer app)
$SMS_USER = "acctsmmp";
$SMS_KEY = "503856edbcXX";
$SMS_SENDER_ID = "MHMNPR";
$SMS_ENTITY_ID = "1701178591434877016";
$SMS_TEMPLATE_ID = "1777178609736013559";
$SMS_GATEWAY_URL = "http://sms3.bpil.in/submitsms.jsp";

// Minimum gap between two OTP sends to the same number, to stop SMS abuse.
$RESEND_COOLDOWN_SECONDS = 60;

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}
$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['phone_number'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number is required']));
    }

    $phone_number = trim($data['phone_number']);
    $force_otp = isset($data['force_otp']) && $data['force_otp'] === true;

    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    // If this vendor already has an M-PIN set, they log in with that
    // instead of OTP every time - skip sending an SMS entirely and tell the
    // app to show the M-PIN screen. force_otp lets the app's "forgot M-PIN"
    // link bypass this and get a real OTP for account recovery.
    if (!$force_otp) {
        $mpin_check_stmt = $conn->prepare("SELECT mpin_hash FROM vendors WHERE phone = ?");
        $mpin_check_stmt->bind_param("s", $phone_number);
        $mpin_check_stmt->execute();
        $mpin_row = $mpin_check_stmt->get_result()->fetch_assoc();
        $mpin_check_stmt->close();

        if ($mpin_row && $mpin_row['mpin_hash'] !== null) {
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'requires_mpin' => true,
                'message' => 'Enter your M-PIN to continue',
            ]);
            $conn->close();
            exit();
        }
    }

    // Enforce the resend cooldown. Computed entirely in SQL via NOW() so it
    // can't be thrown off by PHP's time() and MySQL's clock disagreeing
    // (e.g. one running UTC and the other IST) - mixing the two here
    // previously produced multi-hour "wait" times instead of ~60s.
    $check_stmt = $conn->prepare(
        "SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS elapsed FROM vendor_otp_storage WHERE phone_number = ?"
    );
    $check_stmt->bind_param("s", $phone_number);
    $check_stmt->execute();
    $existing = $check_stmt->get_result()->fetch_assoc();
    $check_stmt->close();

    if ($existing && $existing['elapsed'] !== null && $existing['elapsed'] < $RESEND_COOLDOWN_SECONDS) {
        $wait = $RESEND_COOLDOWN_SECONDS - (int) $existing['elapsed'];
        http_response_code(429);
        die(json_encode(['success' => false, 'message' => "Please wait {$wait}s before requesting another OTP"]));
    }

    // Generate 4-digit OTP.
    $otp = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
    $expires_at = date('Y-m-d H:i:s', strtotime('+10 minutes'));

    $upsert_stmt = $conn->prepare(
        "INSERT INTO vendor_otp_storage (phone_number, otp, attempts, expires_at, created_at)
         VALUES (?, ?, 0, ?, NOW())
         ON DUPLICATE KEY UPDATE otp = VALUES(otp), attempts = 0, expires_at = VALUES(expires_at), created_at = NOW()"
    );
    $upsert_stmt->bind_param("sss", $phone_number, $otp, $expires_at);

    if (!$upsert_stmt->execute()) {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Failed to generate OTP']));
    }
    $upsert_stmt->close();

    // Send SMS via gateway. Must match the DLT-registered template for
    // entityid/tempid below EXACTLY (only the OTP digits may vary) - Indian
    // carriers silently drop any message that deviates from the registered
    // text, even though the gateway itself reports "sent,success".
    $message = "$otp is your OTP for login to Maha Maintain Pro. Valid for 10 minutes. Do not share this OTP with anyone.";
    $sms_params = [
        'user' => $SMS_USER,
        'key' => $SMS_KEY,
        'mobile' => '91' . $phone_number,
        'message' => $message,
        'senderid' => $SMS_SENDER_ID,
        'accusage' => '1',
        'entityid' => $SMS_ENTITY_ID,
        'tempid' => $SMS_TEMPLATE_ID,
    ];
    $sms_url = $SMS_GATEWAY_URL . '?' . http_build_query($sms_params);

    $context = stream_context_create(['http' => ['timeout' => 5]]);
    $response = @file_get_contents($sms_url, false, $context);

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'requires_mpin' => false,
        'message' => $response === false ? 'OTP generated. SMS delivery may be delayed.' : 'OTP sent successfully',
        'otp_sent' => true,
    ]);

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Vendor OTP API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
