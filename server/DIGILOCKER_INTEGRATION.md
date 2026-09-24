# DigiLocker Integration - Complete Implementation

## Overview
Complete server-side implementation for DigiLocker integration with vendor verification, document extraction, and admin approval workflow.

---

## 📊 Database Schema

### New Tables

#### `vendor_digilocker_documents`
Stores documents retrieved from DigiLocker with extracted fields.

```
id (INT PRIMARY KEY)
vendor_id (INT FK)
document_type (VARCHAR) -- ADHAR, PANCR, DRIVINGLICENSE, PASSPORT
document_id (VARCHAR UNIQUE) -- DigiLocker document ID
aadhaar_number (VARCHAR 12)
aadhaar_name (VARCHAR 255)
aadhaar_dob (DATE)
aadhaar_gender (VARCHAR 10)
aadhaar_address (TEXT)
pan_number (VARCHAR 10)
pan_name (VARCHAR 255)
pan_father_name (VARCHAR 255)
pan_dob (DATE)
license_number (VARCHAR 50)
license_holder_name (VARCHAR 255)
license_valid_from (DATE)
license_valid_till (DATE)
license_categories (VARCHAR 100)
issue_date (DATE)
expiry_date (DATE)
raw_json_data (LONGTEXT) -- Full DigiLocker response
created_at (TIMESTAMP)
updated_at (TIMESTAMP)
```

#### `vendor_verification_history`
Audit trail of all verification actions.

```
id (INT PRIMARY KEY)
vendor_id (INT FK)
action (VARCHAR) -- verified, rejected, pending_review
previous_status (VARCHAR 50)
new_status (VARCHAR 50)
admin_id (INT) -- Which admin made decision
admin_name (VARCHAR 255)
rejection_reason (TEXT)
notes (TEXT)
created_at (TIMESTAMP)
```

### Modified Tables

#### `vendor_verifications` (Enhanced)
```
Added columns:
- document_count (INT) -- Number of documents stored
- all_documents_verified (BOOLEAN) -- All required docs verified?
- admin_review_notes (TEXT) -- Why approved/rejected
- admin_reviewed_at (DATETIME) -- When admin made decision
- admin_reviewed_by (VARCHAR 255) -- Which admin reviewed
```

---

## 🔌 API Endpoints

### 1. Store Documents
**Endpoint:** `POST /server/store-digilocker-documents.php`

**Purpose:** Store documents retrieved from DigiLocker after OAuth callback.

**Request:**
```json
{
  "vendor_id": 123,
  "documents": [
    {
      "id": "doc-aadhaar-abc123",
      "doctype": "ADHAR",
      "additional_fields": {}
    },
    {
      "id": "doc-pan-xyz789",
      "doctype": "PANCR",
      "additional_fields": {}
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "stored_count": 2,
  "total_submitted": 2,
  "errors": []
}
```

---

### 2. Get Documents
**Endpoint:** `GET /server/get-digilocker-documents.php?vendor_id=123&document_type=ADHAR`

**Purpose:** Retrieve stored documents for a vendor.

**Query Parameters:**
- `vendor_id` (required, INT)
- `document_type` (optional, VARCHAR) -- Filter by type

**Response:**
```json
{
  "success": true,
  "vendor_id": 123,
  "documents": [
    {
      "id": 1,
      "document_type": "ADHAR",
      "aadhaar_number": "XXXX XXXX 1234",
      "aadhaar_name": "John Doe",
      "aadhaar_dob": "1990-01-15",
      "aadhaar_gender": "M",
      "created_at": "2026-09-24 10:30:00"
    }
  ],
  "document_count": 1
}
```

---

### 3. Extract Aadhaar Details
**Endpoint:** `POST /server/extract-aadhaar-details.php`

**Purpose:** Extract and store Aadhaar information from raw DigiLocker data.

**Request:**
```json
{
  "vendor_id": 123,
  "aadhaar_data": {
    "uid": "224455664466",
    "name": "John Doe",
    "dob": "1990-01-15",
    "gender": "M",
    "address": "123 Main St, City"
  }
}
```

**Response:**
```json
{
  "success": true,
  "vendor_id": 123,
  "extracted": {
    "aadhaar_number": "XXXX XXXX 4466",
    "name": "John Doe",
    "dob": "1990-01-15",
    "gender": "M"
  }
}
```

**Features:**
- Multiple field name variants handled
- Multiple date format support (Y-m-d, d-m-Y, m/d/Y, etc)
- Aadhaar masking for security (shows only last 4 digits)
- Auto-updates vendor name if not set

---

### 4. Extract PAN Details
**Endpoint:** `POST /server/extract-pan-details.php`

**Purpose:** Extract and store PAN information from raw DigiLocker data.

**Request:**
```json
{
  "vendor_id": 123,
  "pan_data": {
    "pan": "ABCDE1234F",
    "name": "John Doe",
    "father_name": "Father Name",
    "dob": "1990-01-15"
  }
}
```

**Response:**
```json
{
  "success": true,
  "vendor_id": 123,
  "extracted": {
    "pan_number": "XXXXX1234F",
    "name": "John Doe",
    "father_name": "Father Name",
    "dob": "1990-01-15"
  },
  "warning": null
}
```

**Features:**
- PAN format validation (10 alphanumeric)
- Name consistency check with Aadhaar
- PAN masking for security
- Date parsing with multiple formats
- Returns warning if names don't match Aadhaar

---

### 5. Admin Verify Vendor
**Endpoint:** `POST /server/admin-verify-vendor.php`

**Purpose:** Admin approves vendor verification.

**Request:**
```json
{
  "vendor_id": 123,
  "admin_id": 1,
  "admin_name": "Admin User",
  "notes": "All documents verified and approved"
}
```

**Response:**
```json
{
  "success": true,
  "vendor_id": 123,
  "vendor_name": "John Doe",
  "new_status": "VERIFIED",
  "message": "Vendor verified successfully"
}
```

**Changes:**
- Sets `vendor_verifications.verification_status = "VERIFIED"`
- Sets `vendor_verifications.all_documents_verified = 1`
- Sets `vendors.status = "active"`
- Logs action to `vendor_verification_history`
- Only works from `UNDER_REVIEW` status

---

### 6. Admin Reject Vendor
**Endpoint:** `POST /server/admin-reject-vendor.php`

**Purpose:** Admin rejects vendor verification.

**Request:**
```json
{
  "vendor_id": 123,
  "admin_id": 1,
  "admin_name": "Admin User",
  "rejection_reason": "Name mismatch between Aadhaar and PAN",
  "notes": "Additional context about rejection"
}
```

**Response:**
```json
{
  "success": true,
  "vendor_id": 123,
  "vendor_name": "John Doe",
  "new_status": "REJECTED",
  "rejection_reason": "Name mismatch between Aadhaar and PAN",
  "message": "Vendor rejected successfully"
}
```

**Changes:**
- Sets `vendor_verifications.verification_status = "REJECTED"`
- Sets `vendors.status = "suspended"`
- Logs action with reason to `vendor_verification_history`
- Can reject from `UNDER_REVIEW`, `DIGILOCKER_CONNECTED`, or `UNVERIFIED`

---

### 7. Admin Get Pending Vendors
**Endpoint:** `GET /server/admin-get-pending-vendors.php?status=UNDER_REVIEW&limit=50&offset=0`

**Purpose:** List all vendors pending review.

**Query Parameters:**
- `status` (optional, VARCHAR) -- UNDER_REVIEW, DIGILOCKER_CONNECTED, UNVERIFIED, REJECTED, VERIFIED (default: UNDER_REVIEW)
- `limit` (optional, INT, max 500, default 50)
- `offset` (optional, INT, default 0)

**Response:**
```json
{
  "success": true,
  "status_filter": "UNDER_REVIEW",
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 25,
    "has_more": false
  },
  "vendors": [
    {
      "id": 123,
      "name": "John Doe",
      "phone": "9876543210",
      "email": "john@example.com",
      "vendor_status": "pending",
      "verification_status": "UNDER_REVIEW",
      "digilocker_connected": true,
      "digilocker_verified_at": "2026-09-24 10:30:00",
      "document_count": 2,
      "all_documents_verified": false,
      "identity_verified": true,
      "pan_verified": true,
      "admin_review_notes": null,
      "admin_reviewed_at": null,
      "admin_reviewed_by": null,
      "stored_documents": 2,
      "documents": [
        {
          "document_type": "ADHAR",
          "aadhaar_number": "XXXX XXXX 1234",
          "aadhaar_name": "John Doe",
          "pan_number": null,
          "pan_name": null,
          "issue_date": "2020-01-01",
          "expiry_date": "2030-01-01"
        },
        {
          "document_type": "PANCR",
          "aadhaar_number": null,
          "aadhaar_name": null,
          "pan_number": "XXXXX1234F",
          "pan_name": "John Doe",
          "issue_date": "2015-06-01",
          "expiry_date": null
        }
      ]
    }
  ],
  "vendor_count": 1
}
```

**Features:**
- Pagination with has_more flag
- Includes full document details for each vendor
- Counts stored documents per vendor
- Shows verification status and progress
- Filterable by status

---

## 🔄 Complete Verification Flow

### Step 1: OAuth Initiation
```
Flutter App → digilocker_start.php → Returns authorization_url
App → Opens URL in browser
User → Logs into DigiLocker & grants consent
```

### Step 2: OAuth Callback
```
DigiLocker → digilocker_callback.php (receives auth code)
Backend → Exchanges code for access token
Backend → Fetches issued documents list
Backend → Updates vendor_verifications.verification_status
Backend → Renders HTML with return link
HTML → Redirects to mahavendor://digilocker-callback
```

### Step 3: App Returns
```
App → Intercepts deep link
App → Calls verification_status.php
App → Updates UI with verification progress
User → Sees "DigiLocker Connected" status
```

### Step 4: Store Documents (Optional)
```
Backend → Calls store-digilocker-documents.php
Backend → Stores document metadata
Backend → Updates vendor_verifications.document_count
```

### Step 5: Extract Details
```
Backend → Calls extract-aadhaar-details.php
Backend → Extracts name, DOB, gender, etc
Backend → Calls extract-pan-details.php
Backend → Compares names for consistency
Backend → Stores extracted data in database
```

### Step 6: Admin Review
```
Admin → Views admin-get-pending-vendors.php list
Admin → Reviews documents and extracted data
Admin → Calls admin-verify-vendor.php (approve)
   OR  → Calls admin-reject-vendor.php (reject)
Vendor → Status changes to VERIFIED or REJECTED
Vendor → Can now proceed or reapply
```

---

## 🔐 Security Features

✅ **State Token Protection (CSRF)**
- Random 48-byte tokens
- Single-use (15-minute expiry)
- Validated on callback

✅ **Client Secret Security**
- Server-side only (never sent to app)
- Used in token exchange only
- Kept in config.php

✅ **Access Token Handling**
- Single-use for document fetch
- Immediately discarded
- Never persisted

✅ **Data Masking**
- Aadhaar: Shows only last 4 digits
- PAN: Shows only last 4 characters
- Sensitive data masked in responses

✅ **Validation**
- PAN format validation (10 alphanumeric)
- Name consistency checks
- Date format normalization
- Vendor existence verification

---

## 🚀 Setup Instructions

### 1. Run Database Schema
```bash
mysql -u your_user -p your_database < digilocker-schema.sql
```

### 2. Create config.php
```bash
cp config.php.example config.php
# Edit config.php with:
# - DIGILOCKER_CLIENT_ID
# - DIGILOCKER_CLIENT_SECRET
# - DIGILOCKER_REDIRECT_URI
# - Database credentials
```

### 3. Verify All APIs Created
```bash
ls -la *.php | grep -E "digilocker|store|extract|admin"
```

### 4. Test Endpoints
```bash
# Test store documents
curl -X POST http://localhost/server/store-digilocker-documents.php \
  -H "Content-Type: application/json" \
  -d '{"vendor_id": 1, "documents": [{"id": "1", "doctype": "ADHAR"}]}'

# Test get pending vendors
curl "http://localhost/server/admin-get-pending-vendors.php?status=UNDER_REVIEW"
```

---

## 📝 Implementation Checklist

✅ Schema Created
✅ 7 APIs Built:
  - store-digilocker-documents.php
  - get-digilocker-documents.php
  - extract-aadhaar-details.php
  - extract-pan-details.php
  - admin-verify-vendor.php
  - admin-reject-vendor.php
  - admin-get-pending-vendors.php

⏳ Next: Flutter Integration
  - Update digilocker_repository.dart with new endpoints
  - Build admin verification dashboard screens
  - Add real-time status updates

---

## 🐛 Error Handling

All endpoints return consistent error responses:

```json
{
  "error": "Error message here",
  "status": 400
}
```

HTTP Status Codes:
- `200` - Success
- `400` - Invalid input
- `404` - Not found
- `405` - Wrong HTTP method
- `500` - Server error

---

## 📊 Database Indexes

Performance optimizations included:

```sql
-- Vendors
INDEX idx_vendor_phone (phone)

-- DigiLocker Documents
INDEX idx_vendor_id (vendor_id)
INDEX idx_document_type (document_type)
INDEX idx_aadhaar (aadhaar_number)
INDEX idx_pan (pan_number)

-- Verification History
INDEX idx_vendor_id (vendor_id)
INDEX idx_action (action)
INDEX idx_created_at (created_at)

-- Verifications
INDEX idx_vendor_verification_status (verification_status)
INDEX idx_vendor_verification_digilocker (digilocker_connected)
```

---

## 📞 Support

For issues:
1. Check error logs
2. Verify config.php credentials
3. Test database connection
4. Validate DigiLocker credentials with API Setu dashboard
