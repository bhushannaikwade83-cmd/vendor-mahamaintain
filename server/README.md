# Vendor backend

Plain PHP + MariaDB backend for the vendor app: phone/OTP + M-PIN login,
onboarding/KYC (DigiLocker, bank penny-drop, service categories, selfie),
and the real jobs/booking/earnings system.

**Deployment target:** this app shares its backend and database with the
consumer MahaMaintain Pro app (`MAHAMAINTAINPRO` repo). That app's PHP files
already live at `https://digitrixmedia.com/mahamaintainpro/api/` and are
confirmed working. Every file in this folder (except `config.php.example`,
`README.md`, and `.gitignore`d `config.php`'s absence) gets uploaded into
that **same** `api/` folder via cPanel File Manager - not a separate
`/server/` path. None of the filenames here collide with the consumer app's
existing files, so nothing gets overwritten.

## Setup

1. **Create the tables.** In phpMyAdmin, run against `digitrix_maha_maintain_pro`:
   - [`create-vendor-tables.sql`](create-vendor-tables.sql) - `vendors` and
     `vendor_otp_storage` (this is a copy of the file already in the
     consumer app's repo; if it's already been run there, running it again
     is harmless - it's `CREATE TABLE IF NOT EXISTS`).
   - [`schema.sql`](schema.sql) - the KYC tables (`vendor_verifications`,
     `digilocker_oauth_sessions`, `vendor_bank_accounts`,
     `vendor_service_categories`, `vendor_selfies`). Service categories
     themselves reuse the consumer app's existing `service_categories`
     table (id, name, emoji, ...) rather than a separate list -
     `vendor_service_categories` just records which of those a vendor
     picked.
   - [`add-vendor-mpin.sql`](add-vendor-mpin.sql) - adds `mpin_hash` /
     `mpin_attempts` / `mpin_locked_until` to `vendors`.
   - [`bookings-schema.sql`](bookings-schema.sql) - the real jobs/booking
     system: `bookings`, `booking_rejections`, `vendor_ledger`.
   - [`societies-schema.sql`](societies-schema.sql) - the Society tab's
     `vendor_society_directory` table (empty - add real societies directly
     in phpMyAdmin, no admin dashboard exists for this yet). Not named
     `societies` because that name is already taken by an unrelated
     consumer-app table (one row per customer's self-reported address
     pending approval - not a shared directory).
   - [`add-vendor-online-status.sql`](add-vendor-online-status.sql) - adds
     `is_online` to `vendors` (defaults to online) for the Home header's
     online/offline toggle.
2. **Fill in `config.php`** (copy from `config.php.example` if you don't
   already have one - it's gitignored, never committed):
   - `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASS` - your MariaDB credentials.
     Note: `send-vendor-otp.php`, `verify-vendor-otp.php` and
     `register-vendor.php` currently hardcode these inline (matching the
     consumer app's existing convention) rather than reading `config.php` -
     if you rotate the DB password, update it in all three of those files too.
   - `DIGILOCKER_CLIENT_ID`, `DIGILOCKER_CLIENT_SECRET`,
     `DIGILOCKER_REDIRECT_URI` - you only get these after your organization
     is registered and approved as a Requester at
     https://partners.apisetu.gov.in. Until then the DigiLocker endpoints
     will run but the calls will fail with an auth error.
   - `DIGILOCKER_REDIRECT_URI` must exactly match what you register with
     API Setu, and must point at
     `https://digitrixmedia.com/mahamaintainpro/api/digilocker_callback.php`.
   - `REQUIRED_DOC_TYPES` - the DigiLocker doctype codes that must be
     present for a vendor to move to `UNDER_REVIEW`. Confirm the exact
     codes for your required documents in the API Setu dashboard.
   - `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` - from a **RazorpayX**
     account (Fund Account Validation is a RazorpayX feature, separate from
     the standard Payments checkout already used in
     `payment_repository.dart`). Until you have these, `bank_verify_start.php`
     will run but the Razorpay calls will fail with an auth error.
   - `RAZORPAY_WEBHOOK_SECRET` - set this to match whatever secret you enter
     when you register `bank_verify_webhook.php` as a webhook URL in the
     Razorpay Dashboard (Account & Settings -> Webhooks), subscribed to
     "Fund Account Validation" events.
   - `SELFIE_UPLOAD_DIR` - defaults to `<this folder>/uploads/selfies`. Make
     sure the `uploads` folder (with `uploads/.htaccess`) ends up alongside
     the PHP files in the live `api/` folder, kept out of direct web access.
   - `JOB_PHOTO_UPLOAD_DIR` / `JOB_PHOTO_BASE_URL` - defaults to
     `<this folder>/uploads/jobs`, served publicly (unlike selfies, before/
     after job photos aren't sensitive - the customer needs to see them) -
     no `.htaccess` needed for this one.
3. **Upload** every `.php` file in this folder, plus `uploads/.htaccess`,
   into `https://digitrixmedia.com/mahamaintainpro/api/` via cPanel File
   Manager. See the file list below.
4. **Flutter app config** already points at this shared folder - see
   `lib/config/kyc_backend_config.dart`. Nothing to change there unless the
   URL moves.

## Files to upload

- `config.php` (your real, filled-in one - not `config.php.example`)
- `send-vendor-otp.php`, `verify-vendor-otp.php`, `register-vendor.php`
  (phone/OTP login + account creation)
- `set-vendor-mpin.php`, `verify-vendor-mpin.php` (M-PIN login for
  returning vendors)
- `digilocker_start.php`, `digilocker_callback.php`, `verification_status.php`
- `bank_verify_start.php`, `bank_verify_webhook.php`, `bank_verify_status.php`
- `categories_list.php`, `vendor_categories_get.php`, `vendor_categories_save.php`
- `selfie_upload.php`, `selfie_status.php`
- `create-booking.php`, `get-vendor-jobs.php`, `respond-to-job.php`,
  `update-job-status.php`, `get-vendor-earnings.php`, `withdraw-earnings.php`,
  `set-vendor-online-status.php`
- `societies_list.php`
- `uploads/.htaccess` (create the `uploads` folder first, then upload this
  into it)

## Endpoints

**Login**
- `POST send-vendor-otp.php` - body `{"phone_number"}` (10 digits, no `+91`).
  Enforces a 60s resend cooldown per number.
- `POST verify-vendor-otp.php` - body `{"phone_number", "otp"}`. Returns
  `{"success", "exists", "vendor_id"?, "name"?, "email"?, "status"?}` -
  `exists: false` means the Flutter app needs to call `register-vendor.php`
  next. Max 5 wrong attempts per OTP before it's rejected outright.
- `POST register-vendor.php` - body `{"phone_number", "name", "email"?}`.
  Creates the `vendors` row (status `pending`) and returns `vendor_id`.
- `POST set-vendor-mpin.php` - body `{"vendor_id", "mpin"}` (4 digits).
  Called once, right after onboarding finishes.
- `POST verify-vendor-mpin.php` - body `{"phone_number", "mpin"}`. Every
  login after the first goes through this instead of OTP - see
  `send-vendor-otp.php`'s `requires_mpin` response. Max 5 wrong attempts,
  then a 15-minute lock.

**DigiLocker**
- `POST digilocker_start.php` - body `{"vendor_id"}`, returns
  `{"authorization_url"}`.
- `GET digilocker_callback.php?code=...&state=...` - called by DigiLocker
  itself, never by Flutter.
- `GET verification_status.php?vendor_id=...` - polled by Flutter.

**Bank account (Razorpay penny-drop)**
- `POST bank_verify_start.php` - body
  `{"vendor_id", "account_holder_name", "account_number", "ifsc_code"}`.
  Starts a Fund Account Validation; result arrives later via webhook.
- `POST bank_verify_webhook.php` - called by Razorpay, never by Flutter.
- `GET bank_verify_status.php?vendor_id=...` - polled by Flutter.

**Service categories**
- `GET categories_list.php` - all active categories.
- `GET vendor_categories_get.php?vendor_id=...` - the vendor's selection.
- `POST vendor_categories_save.php` - body `{"vendor_id", "category_ids": [...]}`.

**Selfie**
- `POST selfie_upload.php` - multipart form, `vendor_id` + `selfie` file
  (JPEG/PNG, max 5 MB). One selfie per vendor.
- `GET selfie_status.php?vendor_id=...` - polled by Flutter.

**Jobs / bookings**
- `POST create-booking.php` - the "plug point" the consumer app will call
  once its booking backend exists. Body:
  `{"customer_name", "customer_phone", "category_id", "service_type",
  "address", "amount", "notes"?, "payment_mode"?, "scheduled_at"?,
  "individual_id"?, "latitude"?, "longitude"?}`. Creates a `REQUESTED`
  booking with no vendor assigned yet. Until the consumer app is ready, call
  this directly to simulate an incoming job request for testing.
- `GET get-vendor-jobs.php?vendor_id=...` - returns `{"new_jobs": [...],
  "my_jobs": [...]}`. `new_jobs` are unclaimed bookings in categories this
  vendor services; `my_jobs` are ones they've already claimed, any status.
  Polled by Flutter - see the design note below about push vs. polling.
  Returns `new_jobs: []` while the vendor is offline (see
  `set-vendor-online-status.php`) - `my_jobs` is unaffected so they can still
  finish work already in progress.
- `POST set-vendor-online-status.php` - body `{"vendor_id", "is_online"}`.
  Backs the Home header's online/offline toggle.
- `POST respond-to-job.php` - body `{"vendor_id", "booking_id", "action"}`
  (`action`: `"accept"` or `"reject"`). Accept is an atomic claim - if
  another vendor already took it, returns 409. Accepting generates the
  6-digit `completion_otp` (see `update-job-status.php`).
- `POST update-job-status.php` - multipart form (not JSON):
  `vendor_id`, `booking_id`, `action` (`"start"` / `"complete"` /
  `"cancel"`), plus optional file fields `before_photo` (on start) /
  `after_photo` (on complete), and required `completion_otp` on complete.
  Completing a job credits `vendor_ledger`.
- `GET get-vendor-earnings.php?vendor_id=...` - wallet balance, today/week/
  month totals, jobs-done count, and the last 50 ledger entries.
- `POST withdraw-earnings.php` - body `{"vendor_id", "amount"}`. Requires a
  `VERIFIED` bank account; deducts from the ledger. Does **not** yet move
  real money - see the design note below.

**Society directory**
- `GET societies_list.php` - all active societies. No filtering by vendor -
  this is a shared read-only directory, not tied to job matching.

## Design notes

- **Error handling**: `config.php` installs a global exception/fatal-error
  handler (`set_exception_handler` + `register_shutdown_function`) that
  every endpoint inherits automatically just by `require`-ing it. Any
  uncaught error - a bad query, a missing column, a PHP fatal - gets logged
  server-side (cPanel → Metrics → Errors) with the real technical detail,
  and the client only ever sees a generic `{"success":false,"error":"Something
  went wrong on our end. Please try again in a moment."}`. Individual
  endpoints don't need their own try/catch for this - only add one locally
  if you want to handle a specific failure differently (e.g. a validation
  error the vendor should see verbatim, like "Incorrect completion OTP").
  The Flutter side mirrors this in `lib/utils/error_messages.dart` -
  `friendlyErrorMessage()` is the one place that decides whether a caught
  error is safe to show a vendor as-is (a deliberately-written message, ours
  or the backend's) or should be replaced with a plain apology (a raw
  network/parse/technical failure).
- Every secret (`DIGILOCKER_CLIENT_SECRET`, `RAZORPAY_KEY_SECRET`,
  `RAZORPAY_WEBHOOK_SECRET`, DB credentials) only lives in PHP files on the
  server - none of it is ever sent to the Flutter app.
- OTPs are checked with `hash_equals` (timing-safe) and capped at 5 wrong
  attempts; `send-vendor-otp.php` enforces a 60s resend cooldown per number.
- DigiLocker access tokens and full bank account numbers are used once (to
  make the necessary API call) and then discarded - only the last 4 digits
  of an account number are stored, and no OAuth tokens are persisted.
- A vendor's `status` (`pending` / `active` / `suspended`) in the `vendors`
  table, and completing DigiLocker or the bank penny-drop, are separate
  concerns - none of them alone means a vendor is approved to work. There's
  no admin dashboard here yet; review directly in MariaDB, or ask for one to
  be built once you know how your team wants to review vendors end-to-end.
- **Jobs are delivered by polling**, not push - `get-vendor-jobs.php` is a
  plain GET the app calls on an interval. That's fine for testing and an
  MVP, but a real "New Job Alert" the instant a booking comes in needs
  Firebase Cloud Messaging (already a dependency in `pubspec.yaml`, not yet
  wired to this backend) - worth doing before launch, not required to test
  the flow end-to-end today.
- **No customer-facing SMS yet.** `respond-to-job.php` generates the
  6-digit `completion_otp` a customer is meant to read out to the vendor
  once the job is done, but nothing sends it to the customer's phone -
  that's the consumer app's job once it exists. Until then, look the OTP up
  directly in the `bookings` table to test the "complete" flow.
- **`withdraw-earnings.php` doesn't move money.** It deducts the ledger and
  creates an audit trail so the UI and API contract are ready, but the
  actual bank transfer (Razorpay Payouts or Route) still needs building
  once RazorpayX is approved - see the earlier bank-verification section.
- **`create-booking.php` doesn't verify the caller is really the consumer
  app** - there's no shared secret or auth on it yet. Fine while nothing
  but you is calling it for testing; add an API key check before the
  consumer app (or anyone else) gets the URL in production.
