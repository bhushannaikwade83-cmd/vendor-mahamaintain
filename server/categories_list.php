<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

header('Content-Type: application/json');

// Reuses the consumer app's service_categories table. The `emoji` column's
// stored text is corrupted (encoding mismatch from whenever it was
// originally inserted), so real category photos are used instead.
$stmt = db()->query('SELECT id, name, image_path FROM service_categories WHERE is_active = 1 ORDER BY name ASC');
$rows = $stmt->fetchAll();

$categories = array_map(function ($row) {
    return [
        'id' => $row['id'],
        'name' => $row['name'],
        'image_url' => $row['image_path'] ? SERVICE_CATEGORY_IMAGE_BASE_URL . $row['image_path'] : null,
    ];
}, $rows);

json_response(['categories' => $categories]);
