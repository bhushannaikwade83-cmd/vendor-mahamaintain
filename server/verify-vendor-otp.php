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

// Max wrong guesses allowed against one stored OTP before it's rejected
// outright - a 4-digit OTP has only 10,000 combinations, so this has to be
// capped or it's brute-forceable.
$MAX_ATTEMPTS = 5;

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}
$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['phone_number']) || !isset($data['otp'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number and OTP are required']));
    }

    $phone_number = trim($data['phone_number']);
    $otp_entered = trim($data['otp']);

    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    $stmt = $conn->prepare(
        "SELECT otp, attempts, expires_at FROM vendor_otp_storage WHERE phone_number = ?"
    );
    $stmt->bind_param("s", $phone_number);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'OTP not found. Please request a new OTP.']));
    }

    if (strtotime($row['expires_at']) < time()) {
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'OTP has expired. Please request a new OTP.']));
    }

    if ($row['attempts'] >= $MAX_ATTEMPTS) {
        http_response_code(429);
        die(json_encode(['success' => false, 'message' => 'Too many incorrect attempts. Please request a new OTP.']));
    }

    if (!hash_equals($row['otp'], $otp_entered)) {
        $bump_stmt = $conn->prepare(
            "UPDATE vendor_otp_storage SET attempts = attempts + 1 WHERE phone_number = ?"
        );
        $bump_stmt->bind_param("s", $phone_number);
        $bump_stmt->execute();
        $bump_stmt->close();

        http_response_code(401);
        die(json_encode(['success' => false, 'message' => 'Invalid OTP. Please try again.']));
    }

    // Correct - consume the OTP so it can't be replayed.
    $delete_stmt = $conn->prepare("DELETE FROM vendor_otp_storage WHERE phone_number = ?");
    $delete_stmt->bind_param("s", $phone_number);
    $delete_stmt->execute();
    $delete_stmt->close();

    // Look up (or implicitly note the absence of) a vendor profile so the
    // app can route to "complete registration" vs. the vendor dashboard.
    $vendor_stmt = $conn->prepare(
        "SELECT id, name, email, status, mpin_hash FROM vendors WHERE phone = ? LIMIT 1"
    );
    $vendor_stmt->bind_param("s", $phone_number);
    $vendor_stmt->execute();
    $vendor = $vendor_stmt->get_result()->fetch_assoc();
    $vendor_stmt->close();

    http_response_code(200);
    if ($vendor) {
        echo json_encode([
            'success' => true,
            'message' => 'OTP verified successfully',
            'exists' => true,
            'phone_number' => $phone_number,
            'vendor_id' => $vendor['id'],
            'name' => $vendor['name'],
            'email' => $vendor['email'],
            'status' => $vendor['status'],
            // Having an M-PIN already means this vendor completed
            // onboarding before - lets the app skip straight to the
            // dashboard instead of re-running the onboarding checklist.
            'has_mpin' => $vendor['mpin_hash'] !== null,
        ]);
    } else {
        echo json_encode([
            'success' => true,
            'message' => 'OTP verified successfully',
            'exists' => false,
            'phone_number' => $phone_number,
        ]);
    }

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Vendor OTP Verification API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
