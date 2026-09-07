<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json');

$stmt = db()->query('SELECT * FROM vendor_society_directory WHERE is_active = 1 ORDER BY name ASC');
$rows = $stmt->fetchAll();

json_response([
    'societies' => array_map(function ($row) {
        return [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'phase' => $row['phase'],
            'area' => $row['area'],
            'units' => (int)$row['units'],
            'contact_name' => $row['contact_name'],
            'contact_phone' => $row['contact_phone'],
            'has_amc' => (bool)$row['has_amc'],
            'access_notes' => $row['access_notes'],
            'latitude' => $row['latitude'] !== null ? (float)$row['latitude'] : null,
            'longitude' => $row['longitude'] !== null ? (float)$row['longitude'] : null,
        ];
    }, $rows),
]);
