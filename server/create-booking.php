<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

// This is the endpoint the consumer app (MahaMaintain Pro) will call once
// its booking backend exists - see server/README.md for the exact request
// shape. Until then, call it directly to simulate an incoming job request
// for testing the vendor app end-to-end.

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'POST required'], 405);
}

$input = json_decode((string)file_get_contents('php://input'), true);

$required = ['customer_name', 'customer_phone', 'category_id', 'service_type', 'address', 'amount'];
foreach ($required as $field) {
    if (!isset($input[$field]) || $input[$field] === '') {
        json_response(['success' => false, 'message' => "Missing required field: $field"], 400);
    }
}

$customerName = trim((string)$input['customer_name']);
$customerPhone = trim((string)$input['customer_phone']);
$categoryId = (int)$input['category_id'];
$serviceType = trim((string)$input['service_type']);
$address = trim((string)$input['address']);
$amount = (float)$input['amount'];
$notes = isset($input['notes']) ? trim((string)$input['notes']) : null;
$paymentMode = in_array($input['payment_mode'] ?? 'UPI', ['UPI', 'CASH', 'ONLINE'], true)
    ? $input['payment_mode']
    : 'UPI';
$scheduledAt = isset($input['scheduled_at']) ? trim((string)$input['scheduled_at']) : null;
$individualId = isset($input['individual_id']) ? (int)$input['individual_id'] : null;
$latitude = isset($input['latitude']) ? (float)$input['latitude'] : null;
$longitude = isset($input['longitude']) ? (float)$input['longitude'] : null;

if (!preg_match('/^[0-9]{10}$/', $customerPhone)) {
    json_response(['success' => false, 'message' => 'customer_phone must be 10 digits'], 400);
}

if ($amount <= 0) {
    json_response(['success' => false, 'message' => 'amount must be greater than 0'], 400);
}

// Confirm the category actually exists rather than trusting the caller -
// the FK on bookings.category_id would reject it anyway, but this gives a
// clearer error message.
$categoryCheck = db()->prepare('SELECT id FROM service_categories WHERE id = :id AND is_active = 1');
$categoryCheck->execute(['id' => $categoryId]);
if (!$categoryCheck->fetch()) {
    json_response(['success' => false, 'message' => 'Invalid category_id'], 400);
}

$stmt = db()->prepare(
    'INSERT INTO bookings
        (individual_id, customer_name, customer_phone, category_id, service_type,
         notes, address, latitude, longitude, amount, payment_mode, scheduled_at, status)
     VALUES
        (:individual_id, :customer_name, :customer_phone, :category_id, :service_type,
         :notes, :address, :latitude, :longitude, :amount, :payment_mode, :scheduled_at, "REQUESTED")'
);
$stmt->execute([
    'individual_id' => $individualId,
    'customer_name' => $customerName,
    'customer_phone' => $customerPhone,
    'category_id' => $categoryId,
    'service_type' => $serviceType,
    'notes' => $notes,
    'address' => $address,
    'latitude' => $latitude,
    'longitude' => $longitude,
    'amount' => $amount,
    'payment_mode' => $paymentMode,
    'scheduled_at' => $scheduledAt,
]);

$bookingId = (int)db()->lastInsertId();

// TODO once the vendor jobs feed moves to push instead of polling (see
// server/README.md): notify vendors who service this category via FCM here.

json_response(['success' => true, 'booking_id' => $bookingId, 'status' => 'REQUESTED']);
