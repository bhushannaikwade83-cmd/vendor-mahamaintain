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

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}
$conn->set_charset("utf8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['vendor_id']) || !isset($data['mpin'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'vendor_id and mpin are required']));
    }

    $vendor_id = (int) $data['vendor_id'];
    $mpin = trim((string) $data['mpin']);

    if (!preg_match('/^[0-9]{4}$/', $mpin)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'M-PIN must be exactly 4 digits']));
    }

    // Reject the laziest PINs (1234, 0000, 1111, ...) - not a strong
    // defense on its own, but costs nothing to add.
    $weak_pins = ['0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', '1234', '4321'];
    if (in_array($mpin, $weak_pins, true)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Please choose a less predictable M-PIN']));
    }

    $mpin_hash = password_hash($mpin, PASSWORD_BCRYPT);

    $stmt = $conn->prepare(
        "UPDATE vendors SET mpin_hash = ?, mpin_attempts = 0, mpin_locked_until = NULL WHERE id = ?"
    );
    $stmt->bind_param("si", $mpin_hash, $vendor_id);

    if (!$stmt->execute() || $stmt->affected_rows === 0) {
        $stmt->close();
        http_response_code(404);
        die(json_encode(['success' => false, 'message' => 'Vendor not found']));
    }
    $stmt->close();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'M-PIN set successfully']);

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Set Vendor M-PIN API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
