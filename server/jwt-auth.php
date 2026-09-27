<?php
/**
 * JWT Authentication Middleware
 * Include this in all protected API endpoints.
 *
 * Shared verbatim between the customer app (api/) and the vendor app
 * (maha-vendor-app/server/) - both deploy into the same physical directory
 * on the server and use the same JWT_SECRET, so a token issued by either
 * app's login endpoint can be verified here identically.
 */

/**
 * Resolve JWT_SECRET: prefer the JWT_SECRET env var (set this properly on
 * the server for production). If it's not set, self-heal by generating a
 * random secret once and persisting it outside version control, rather
 * than falling back to a hardcoded string that's sitting in source control
 * and readable by anyone with this file - a hardcoded fallback would let
 * anyone forge a valid token for any user (resident/vendor/admin).
 */
function resolveJwtSecret(): string {
    $envSecret = getenv('JWT_SECRET');
    if ($envSecret) {
        return $envSecret;
    }

    error_log('[SECURITY] JWT_SECRET env var is not set - using an auto-generated local secret instead. Set JWT_SECRET on the server for production.');

    $secretFile = __DIR__ . '/.jwt-secret.local';
    if (file_exists($secretFile)) {
        $stored = trim((string) file_get_contents($secretFile));
        if ($stored !== '') {
            return $stored;
        }
    }

    $generated = bin2hex(random_bytes(32));
    file_put_contents($secretFile, $generated, LOCK_EX);
    @chmod($secretFile, 0600);
    return $generated;
}

define('JWT_SECRET', resolveJwtSecret());

/**
 * Build a JWT from arbitrary claims (role, vendor_id, phone_number, etc).
 * Every login endpoint (customer OTP/M-PIN, vendor OTP/M-PIN, admin login)
 * should issue tokens through this so claims stay consistent.
 */
function generateJWT(array $claims, int $expirySeconds = 86400): string {
    $header = json_encode(['alg' => 'HS256', 'typ' => 'JWT']);
    $payload = json_encode(array_merge($claims, [
        'iat' => time(),
        'exp' => time() + $expirySeconds,
    ]));

    $base64Header = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $base64Payload = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');

    $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
    $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    return "$base64Header.$base64Payload.$base64Signature";
}

function verifyJWTToken() {
    // Get token from Authorization header. getallheaders() is undefined
    // under some SAPIs (CLI, some FastCGI/Nginx setups) - fall back to the
    // $_SERVER entries PHP always populates instead of fataling outright.
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;
    } else {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? null;
    }

    if (!$authHeader) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Missing authorization token']);
        exit();
    }

    // Extract token from "Bearer <token>"
    if (!preg_match('/Bearer\s+(.+)/', $authHeader, $matches)) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid authorization format']);
        exit();
    }

    $token = $matches[1];

    // Verify JWT
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token format']);
        exit();
    }

    list($header, $payload, $signature) = $parts;

    // Verify signature
    $expectedSignature = rtrim(strtr(base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true)), '+/', '-_'), '=');

    if (!hash_equals($expectedSignature, $signature)) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token signature']);
        exit();
    }

    // Decode and verify expiry
    $decoded = json_decode(base64_decode(strtr($payload, '-_', '+/')), true);

    if (!$decoded) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token data']);
        exit();
    }

    if ($decoded['exp'] < time()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token has expired']);
        exit();
    }

    return $decoded; // Return decoded token with phone_number, role, etc.
}

/** Require the token to carry one of the given roles (string or array). */
function requireRole($allowedRoles) {
    $token = verifyJWTToken();
    $role = $token['role'] ?? null;

    if (!in_array($role, (array)$allowedRoles, true)) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Insufficient permissions']);
        exit();
    }

    return $token;
}

/** Super Admin only (society/platform owner level). */
function requireSuperAdminRole() {
    return requireRole('super_admin');
}

/** Admin or Super Admin (Super Admin inherits Admin permissions). */
function requireAdminRole() {
    return requireRole(['admin', 'super_admin']);
}

/**
 * Vendor/Technician/Service Provider role, with an existing vendor profile
 * linked. Use requireVendorRoleAllowUnregistered() for the one endpoint
 * (register-vendor.php) that runs before vendor_id exists.
 */
function requireVendorRole() {
    $token = requireRole('vendor');

    if (empty($token['vendor_id'])) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Vendor registration not completed']);
        exit();
    }

    return $token;
}

/** Vendor role without requiring vendor_id yet - only for registration. */
function requireVendorRoleAllowUnregistered() {
    return requireRole('vendor');
}

/**
 * Society Secretary permissions. Secretaries log in as regular residents
 * (same OTP/M-PIN flow, role=resident token) - this checks the
 * society_secretaries table for an approved registration tied to the
 * token's phone number, rather than requiring a separate role claim.
 */
function requireSecretaryRole() {
    $token = verifyJWTToken();

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }

    $stmt = $conn->prepare("SELECT id FROM society_secretaries WHERE phone = ? AND approval_status = 'approved' LIMIT 1");
    $stmt->bind_param('s', $token['phone_number']);
    $stmt->execute();
    $result = $stmt->get_result();
    $isSecretary = $result->num_rows > 0;
    $stmt->close();
    $conn->close();

    if (!$isSecretary) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Approved society secretary status required']);
        exit();
    }

    return $token;
}

/**
 * Society-scoped READ access: any resident who actually belongs to this
 * society (member, secretary, or admin) can read its data - stops one
 * society's resident from reading another society's flats/complaints/
 * notices/financials just by changing society_id in the request.
 */
function requireSocietyMembership($society_id) {
    $token = verifyJWTToken();
    $role = $token['role'] ?? null;

    if (in_array($role, ['admin', 'super_admin'], true)) {
        return $token;
    }

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }

    $stmt = $conn->prepare("
        SELECT 1 FROM society_customers_individual WHERE phone = ? AND society_id = ? AND is_enabled = 1
        UNION SELECT 1 FROM society_secretaries WHERE phone = ? AND society_id = ? AND approval_status = 'approved'
    ");
    $stmt->bind_param('sisi', $token['phone_number'], $society_id, $token['phone_number'], $society_id);
    $stmt->execute();
    $isMember = $stmt->get_result()->num_rows > 0;
    $stmt->close();
    $conn->close();

    if (!$isMember) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'You are not a member of this society']);
        exit();
    }

    return $token;
}

/**
 * Society-scoped management access: Admin/Super Admin can manage any
 * society; an approved secretary can only manage the society they are
 * registered against. Used by the Society Module endpoints (buildings,
 * flats, notices, complaint status, maintenance bills) that both roles
 * can touch, unlike requireSecretaryRole()'s member-only endpoints.
 */
function requireSocietyManagerRole($society_id) {
    $token = verifyJWTToken();
    $role = $token['role'] ?? null;

    if (in_array($role, ['admin', 'super_admin'], true)) {
        return $token;
    }

    $conn = new mysqli('localhost', 'digitrix_maha_user', 'maha_user@70', 'digitrix_maha_maintain_pro');
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }

    $stmt = $conn->prepare("SELECT id FROM society_secretaries WHERE phone = ? AND society_id = ? AND approval_status = 'approved' LIMIT 1");
    $stmt->bind_param('si', $token['phone_number'], $society_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $isSecretaryOfSociety = $result->num_rows > 0;
    $stmt->close();
    $conn->close();

    if (!$isSecretaryOfSociety) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Admin or approved secretary of this society required']);
        exit();
    }

    return $token;
}
?>
