<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';

// Records a withdrawal against the vendor's ledger balance. This does NOT
// yet execute a real bank transfer - that needs a Razorpay Payouts/Route
// integration once RazorpayX is approved (see server/README.md). For now
// this deducts the balance and creates an audit trail so the real payout
// wiring can be dropped in later without changing this contract.

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'POST required'], 405);
}

$input = json_decode((string)file_get_contents('php://input'), true);
$vendorId = trim((string)($input['vendor_id'] ?? ''));
$amount = isset($input['amount']) ? (float)$input['amount'] : 0;

if ($vendorId === '' || $amount <= 0) {
    json_response(['success' => false, 'message' => 'vendor_id and a positive amount are required'], 400);
}

$bankStmt = db()->prepare('SELECT verification_status FROM vendor_bank_accounts WHERE vendor_id = :vendor_id');
$bankStmt->execute(['vendor_id' => $vendorId]);
$bank = $bankStmt->fetch();

if (!$bank || $bank['verification_status'] !== 'VERIFIED') {
    json_response(['success' => false, 'message' => 'Add and verify a bank account before withdrawing'], 403);
}

$pdo = db();
$pdo->beginTransaction();
try {
    // Lock this vendor's ledger rows so a double-tap can't withdraw twice
    // against the same balance.
    $balanceStmt = $pdo->prepare(
        'SELECT COALESCE(SUM(amount), 0) AS balance FROM vendor_ledger WHERE vendor_id = :vendor_id FOR UPDATE'
    );
    $balanceStmt->execute(['vendor_id' => $vendorId]);
    $balance = (float)$balanceStmt->fetch()['balance'];

    if ($amount > $balance) {
        $pdo->rollBack();
        json_response(['success' => false, 'message' => 'Withdrawal amount exceeds available balance'], 400);
    }

    $pdo->prepare(
        'INSERT INTO vendor_ledger (vendor_id, entry_type, amount, description)
         VALUES (:vendor_id, "WITHDRAWAL", :amount, "Withdrawal to bank account")'
    )->execute(['vendor_id' => $vendorId, 'amount' => -$amount]);

    $pdo->commit();
} catch (Throwable $e) {
    $pdo->rollBack();
    json_response(['success' => false, 'message' => 'Could not process withdrawal'], 500);
}

json_response(['success' => true, 'message' => 'Withdrawal recorded']);
