<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';
$vendorToken = requireVendorRole();
$vendorId = (string) $vendorToken['vendor_id'];

$stmt = db()->prepare('SELECT category_id FROM vendor_service_categories WHERE vendor_id = :vendor_id');
$stmt->execute(['vendor_id' => $vendorId]);
$categoryIds = array_map(fn($row) => (int)$row['category_id'], $stmt->fetchAll());

json_response(['category_ids' => $categoryIds]);
