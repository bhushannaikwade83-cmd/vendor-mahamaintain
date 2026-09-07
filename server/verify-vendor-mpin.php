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

// A 4-digit M-PIN has only 10,000 combinations, so wrong guesses must be
// capped hard, with a cooldown lock once exhausted (the vendor can always
// fall back to "Login with OTP instead" in the app).
$MAX_ATTEMPTS = 5;
$LOCK_MINUTES = 15;

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}
$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['phone_number']) || !isset($data['mpin'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number and M-PIN are required']));
    }

    $phone_number = trim($data['phone_number']);
    $mpin_entered = trim((string) $data['mpin']);

    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    $stmt = $conn->prepare(
        "SELECT id, name, email, status, mpin_hash, mpin_attempts, mpin_locked_until FROM vendors WHERE phone = ? LIMIT 1"
    );
    $stmt->bind_param("s", $phone_number);
    $stmt->execute();
    $vendor = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$vendor || $vendor['mpin_hash'] === null) {
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'No M-PIN set for this number. Please log in with OTP.']));
    }

    if ($vendor['mpin_locked_until'] !== null && strtotime($vendor['mpin_locked_until']) > time()) {
        $wait_minutes = (int) ceil((strtotime($vendor['mpin_locked_until']) - time()) / 60);
        http_response_code(429);
        die(json_encode([
            'success' => false,
            'message' => "Too many incorrect attempts. Try again in {$wait_minutes} min, or log in with OTP.",
        ]));
    }

    if (!password_verify($mpin_entered, $vendor['mpin_hash'])) {
        $new_attempts = (int) $vendor['mpin_attempts'] + 1;

        if ($new_attempts >= $MAX_ATTEMPTS) {
            $lock_stmt = $conn->prepare(
                "UPDATE vendors SET mpin_attempts = ?, mpin_locked_until = DATE_ADD(NOW(), INTERVAL ? MINUTE) WHERE id = ?"
            );
            $lock_stmt->bind_param("iii", $new_attempts, $LOCK_MINUTES, $vendor['id']);
            $lock_stmt->execute();
            $lock_stmt->close();

            http_response_code(429);
            die(json_encode([
                'success' => false,
                'message' => "Too many incorrect attempts. Try again in {$LOCK_MINUTES} min, or log in with OTP.",
            ]));
        }

        $bump_stmt = $conn->prepare("UPDATE vendors SET mpin_attempts = ? WHERE id = ?");
        $bump_stmt->bind_param("ii", $new_attempts, $vendor['id']);
        $bump_stmt->execute();
        $bump_stmt->close();

        $remaining = $MAX_ATTEMPTS - $new_attempts;
        http_response_code(401);
        die(json_encode(['success' => false, 'message' => "Incorrect M-PIN. {$remaining} attempt(s) left."]));
    }

    // Correct - reset the attempt counter.
    $reset_stmt = $conn->prepare("UPDATE vendors SET mpin_attempts = 0, mpin_locked_until = NULL WHERE id = ?");
    $reset_stmt->bind_param("i", $vendor['id']);
    $reset_stmt->execute();
    $reset_stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'M-PIN verified successfully',
        'vendor_id' => $vendor['id'],
        'name' => $vendor['name'],
        'email' => $vendor['email'],
        'status' => $vendor['status'],
    ]);

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Vendor M-PIN Verification API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
