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

// Database credentials - same digitrix_maha_maintain_pro database the
// customer app and send-vendor-otp.php / verify-vendor-otp.php use.
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

    if (!isset($data['phone_number']) || !isset($data['name'])) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Phone number and name are required']));
    }

    $phone_number = trim($data['phone_number']);
    $name = trim($data['name']);
    $email = isset($data['email']) ? trim($data['email']) : null;

    if (!preg_match('/^[0-9]{10}$/', $phone_number)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid phone number']));
    }

    if ($name === '') {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Name is required']));
    }

    if ($email !== null && $email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        die(json_encode(['success' => false, 'message' => 'Invalid email address']));
    }

    $check_stmt = $conn->prepare("SELECT id FROM vendors WHERE phone = ?");
    $check_stmt->bind_param("s", $phone_number);
    $check_stmt->execute();
    $existing = $check_stmt->get_result()->fetch_assoc();
    $check_stmt->close();

    if ($existing) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Vendor already registered',
            'vendor_id' => $existing['id'],
        ]);
        $conn->close();
        exit();
    }

    $insert_stmt = $conn->prepare(
        "INSERT INTO vendors (name, phone, email, status) VALUES (?, ?, ?, 'pending')"
    );
    $insert_stmt->bind_param("sss", $name, $phone_number, $email);

    if (!$insert_stmt->execute()) {
        http_response_code(500);
        die(json_encode(['success' => false, 'message' => 'Failed to register vendor']));
    }

    $vendor_id = $conn->insert_id;
    $insert_stmt->close();

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Registration submitted successfully. Awaiting admin approval.',
        'vendor_id' => $vendor_id,
    ]);

} else if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Vendor Registration API is working']);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
