<?php
declare(strict_types=1);

require __DIR__ . '/config.php';

header('Content-Type: application/json');

$vendorId = trim((string)($_GET['vendor_id'] ?? ''));
if ($vendorId === '') {
    json_response(['error' => 'vendor_id is required'], 400);
}

$balanceStmt = db()->prepare('SELECT COALESCE(SUM(amount), 0) AS balance FROM vendor_ledger WHERE vendor_id = :vendor_id');
$balanceStmt->execute(['vendor_id' => $vendorId]);
$balance = (float)$balanceStmt->fetch()['balance'];

function sum_since(string $vendorId, string $interval): float
{
    $stmt = db()->prepare(
        "SELECT COALESCE(SUM(amount), 0) AS total FROM vendor_ledger
         WHERE vendor_id = :vendor_id AND entry_type = 'JOB_EARNING' AND created_at >= $interval"
    );
    $stmt->execute(['vendor_id' => $vendorId]);
    return (float)$stmt->fetch()['total'];
}

$todayEarnings = sum_since($vendorId, 'CURDATE()');
$weekEarnings = sum_since($vendorId, 'DATE_SUB(CURDATE(), INTERVAL 7 DAY)');
$monthEarnings = sum_since($vendorId, 'DATE_SUB(CURDATE(), INTERVAL 30 DAY)');

$jobsDoneStmt = db()->prepare(
    'SELECT COUNT(*) AS n FROM bookings WHERE vendor_id = :vendor_id AND status = "COMPLETED"'
);
$jobsDoneStmt->execute(['vendor_id' => $vendorId]);
$jobsDone = (int)$jobsDoneStmt->fetch()['n'];

$historyStmt = db()->prepare(
    'SELECT id, booking_id, entry_type, amount, description, created_at
     FROM vendor_ledger WHERE vendor_id = :vendor_id
     ORDER BY created_at DESC LIMIT 50'
);
$historyStmt->execute(['vendor_id' => $vendorId]);
$history = array_map(function ($row) {
    return [
        'id' => (int)$row['id'],
        'booking_id' => $row['booking_id'] !== null ? (int)$row['booking_id'] : null,
        'entry_type' => $row['entry_type'],
        'amount' => (float)$row['amount'],
        'description' => $row['description'],
        'created_at' => $row['created_at'],
    ];
}, $historyStmt->fetchAll());

json_response([
    'wallet_balance' => $balance,
    'today_earnings' => $todayEarnings,
    'week_earnings' => $weekEarnings,
    'month_earnings' => $monthEarnings,
    'jobs_done' => $jobsDone,
    'transactions' => $history,
]);
