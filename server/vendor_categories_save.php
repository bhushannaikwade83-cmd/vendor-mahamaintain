<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'POST required'], 405);
}

require_once __DIR__ . '/jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

$input = json_decode((string)file_get_contents('php://input'), true);
$categoryIds = $input['category_ids'] ?? null;

if (!is_array($categoryIds) || count($categoryIds) === 0) {
    json_response(['error' => 'at least one category_id is required'], 400);
}

$categoryIds = array_values(array_unique(array_map('intval', $categoryIds)));

try {
    $pdo = db();
    $pdo->beginTransaction();

    $pdo->prepare('DELETE FROM vendor_service_categories WHERE vendor_id = :vendor_id')
        ->execute(['vendor_id' => $vendorId]);

    $insert = $pdo->prepare(
        'INSERT INTO vendor_service_categories (vendor_id, category_id) VALUES (:vendor_id, :category_id)'
    );
    foreach ($categoryIds as $categoryId) {
        $insert->execute(['vendor_id' => $vendorId, 'category_id' => $categoryId]);
    }

    $pdo->commit();
} catch (PDOException $e) {
    db()->rollBack();
    json_response(['error' => 'Database error'], 500);
}

json_response(['status' => 'ok', 'category_ids' => $categoryIds]);
