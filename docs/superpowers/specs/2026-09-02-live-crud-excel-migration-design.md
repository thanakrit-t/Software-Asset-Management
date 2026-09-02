# Live CRUD and Excel Migration Design

**Date:** 2026-09-02  
**Status:** Approved design  
**Project:** Software Asset Management  
**Organization:** Thai Kurabo, with Factory and Bangkok Office sites

## 1. Objective

Replace the remaining mock-data application flows with hosted Supabase reads and controlled writes, add the administrative actions needed to operate the system, and migrate the two approved Excel workbooks through a staged, reviewable, one-time import.

The finished system must use hosted Supabase as the single source of truth for Assets, Software Products, Licenses, Allocations, Master Data, Users, Notifications, Reports, and Audit Logs. Business records are never hard-deleted from the application.

## 2. Scope

### 2.1 Included

- Replace `mockSamRepository` reads with a hosted Supabase repository.
- Add real Create, Edit, Archive, Release, Activate/Deactivate, and notification-state actions where appropriate.
- Enforce Admin-only mutations in PostgreSQL RPCs as well as in the UI.
- Add optimistic locking, audit events, confirmation flows, and actionable errors.
- Parse and stage both approved Excel workbooks.
- Detect duplicates by exact match.
- Provide an Admin migration review screen with validation and reconciliation.
- Publish an approved migration batch atomically into production tables.
- Protect Serial Numbers and License Keys in the private secret path defined by the database design.

### 2.2 Excluded

- Hard delete of business or audit records.
- A recurring Excel import feature after initial migration.
- Restore of archived records in this release.
- Editing an existing Allocation; incorrect allocations are released and recreated.
- Editing or deleting Audit Logs.
- Mutations from Reports.
- A generic configuration-driven CRUD framework.

## 3. Roles and Permissions

### Admin

- Reads all application-safe data.
- Creates and edits operational records.
- Archives business records with a required reason.
- Releases Allocations with a required reason.
- Changes user role and account status with a required reason.
- Reviews, acknowledges warnings, and publishes migration batches.
- Reveals protected License secrets only through an audited RPC.

### User

- Reads permitted operational data and reports.
- May update personal notification read/dismissed state.
- Cannot see administrative action menus.
- Cannot call mutation RPCs successfully even if a request is constructed outside the UI.

### Anonymous

- Has no application data access.

## 4. Application Architecture

### 4.1 Reads

- Server Components call `SupabaseSamRepository` using the authenticated server client.
- The repository reads only public tables or security-invoker safe views allowed by RLS.
- Domain mapping stays inside the repository so UI components receive stable application types.
- Archived records are excluded by default. Admin filters can include them for inspection.

### 4.2 Writes

- Client components submit forms to Next.js Server Actions.
- Server Actions validate the form payload and call public PostgreSQL RPCs.
- RPCs re-check `private.is_admin()` for administrative changes.
- Updates and state transitions accept `expected_version` for optimistic locking.
- Successful actions call `revalidatePath` for affected lists, details, dashboards, reports, and notifications.
- The browser never receives the Service Role key and never writes directly to protected tables.

### 4.3 Errors

Database error codes map to Thai, actionable UI messages:

- `ACCESS_DENIED`: ไม่มีสิทธิ์ดำเนินการ
- `VERSION_CONFLICT`: ข้อมูลถูกแก้ไขโดยผู้ใช้อื่น กรุณาโหลดข้อมูลล่าสุด
- `ACTIVE_ALLOCATIONS_EXIST`: ต้อง Release Allocation ที่ใช้งานอยู่ก่อน
- `OWNED_BELOW_ALLOCATED`: จำนวน Owned ต้องไม่น้อยกว่า Active Allocated
- `DUPLICATE_RECORD`: พบข้อมูลซ้ำแบบ exact match
- `REASON_REQUIRED`: กรุณาระบุเหตุผล
- Unexpected errors: show a correlation ID without exposing internal SQL or secrets.

## 5. Action Matrix

| Module | Admin actions | User actions | Rules |
|---|---|---|---|
| Asset | View, Create, Edit, Archive | View | Active Allocation impact must be resolved or explicitly handled by policy; no hard delete |
| Software Product | Create, Edit, Archive | View | Referenced products remain available to history but disappear from new-selection lists |
| License | View, Create, Edit, Archive, Reveal Secret | View safe fields | Owned cannot be reduced below Active Allocated; active Allocations must be released before Archive |
| Allocation | View, Create, Release | View | No Edit/Delete; release and recreate preserves history |
| Master Data | Create where supported, Edit, Archive | View | Referenced values remain in history and are removed from new-entry choices |
| User | Edit Role, Activate, Deactivate | None | Last active Admin is protected |
| Notification | Read/Unread, Dismiss | Read/Unread, Dismiss own | Recipient-scoped state only; source event is unchanged |
| Audit Log | View | None | Append-only |
| Report | View, Export | View, Export | No data mutation |
| Migration Review | Review, acknowledge, publish | None | Admin-only; unavailable as recurring import after completion |

## 6. UI Design

### 6.1 Row Actions

- Use a three-dot action button in the final table column.
- Keep common navigation actions first, mutation actions second, and Archive/Release/Deactivate last.
- Admin-only actions are not rendered for Users.
- Dangerous actions use destructive styling and never run on the first click.

### 6.2 Edit

- Open a Drawer populated from the current record.
- Include the record version as hidden action state.
- Validate fields inline before calling the Server Action.
- On success, close the Drawer, show a success Toast, and refresh affected data.
- On version conflict, keep user input available and offer reload of the latest record.

### 6.3 Archive, Release, and Deactivate

- Open a confirmation Dialog.
- Show the record identity and impact counts.
- Require a reason.
- Require explicit confirmation after impact is loaded.
- Do not optimistically remove a row before the database confirms success.

### 6.4 Filters

- Normal lists show active records only.
- Admins can filter Active/Archived where meaningful.
- Archived values never appear as options for new operational records.

## 7. Database Commands

Add or complete narrowly scoped RPCs rather than granting table writes:

- `create_asset(payload)`
- `update_asset(asset_id, expected_version, payload)`
- `archive_asset(asset_id, expected_version, reason, acknowledge_allocations)`
- `create_software_product(payload)`
- `update_software_product(product_id, expected_version, payload)`
- `archive_software_product(product_id, expected_version, reason)`
- `create_license_entitlement(payload)`
- `update_license_entitlement(entitlement_id, expected_version, payload)`
- `archive_license_entitlement(entitlement_id, expected_version, reason)`
- Existing `allocate_license(payload)`
- Existing `release_license_allocation(allocation_id, expected_version, reason)`
- `update_master_data(entity_type, entity_id, expected_version, payload)`
- `archive_master_data(entity_type, entity_id, expected_version, reason)`
- Existing `set_user_role(profile_id, new_role, reason)`
- Existing `set_user_status(profile_id, new_status, reason)`
- `set_notification_state(notification_id, is_read, is_dismissed)`
- `validate_import_batch(import_batch_id)`
- `publish_import_batch(import_batch_id, expected_version, acknowledge_warnings)`

Every administrative RPC must:

1. Verify active Admin status.
2. Validate input and business rules.
3. Apply optimistic locking for updates.
4. Write an Audit event with actor, entity, before/after values, reason, and correlation ID.
5. Avoid returning secret plaintext except from the dedicated audited reveal flow.

## 8. Excel Sources

### 8.1 Asset and Installed Software Workbook

File: `02 203Total License(TKC) Update 2026-08-28.xlsx`

- `Software(Factory)` maps to the Factory site.
- `Software(Bangkok Offic)` maps to the Bangkok Office site.
- Device rows map to Assets, Network Interfaces, People/Assignments, and Installed Software inventory.
- NB/PC columns contribute to Asset Type mapping.
- Horizontal software columns map to Software Products and per-Asset software presence.
- Multi-row headers, merged cells, and calculated cells require explicit sheet adapters rather than a generic row reader.
- Calculated values are read from the workbook result, while source cell coordinates remain traceable.

Observed scale at design time:

- Factory sheet: up to 309 rows and 62 columns.
- Bangkok Office sheet: up to 36 rows and 155 columns.

### 8.2 License Workbook

File: `03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx`

- Factory and Office detail sheets map to License Entitlements and related master data.
- Maker maps to Publisher.
- Dealer maps to Vendor.
- Product Name plus Version maps to Software Product.
- Product Classification and Purchase Form map to controlled master data.
- Own License maps to Owned Quantity.
- Use License is used for reconciliation and Allocation derivation where a valid target can be resolved.
- Serial No. follows the encrypted private-secret flow.
- Purchase, Start, End, and Install dates map to typed date fields.
- Status and Remark retain source traceability.
- Summary Factory and Summary Office are reconciliation inputs only and are not published as duplicate business records.

Observed scale at design time:

- Factory detail: approximately 128 populated rows.
- Office detail: approximately 130 populated rows.

## 9. Staging and Validation

Reuse and extend the existing migration schema:

- `migration.import_batches`
- `migration.source_files`
- `migration.asset_staging_rows`
- `migration.license_staging_rows`
- `migration.row_results`
- `migration.mapping_rules`
- `migration.reconciliation_runs`
- `migration.reconciliation_totals`

### 9.1 Extraction

- Treat original workbooks as read-only.
- Compute a SHA-256 fingerprint for every source file.
- Record sheet name, source row, source cells, sanitized raw data, and normalized fields.
- Never store Serial/License Key plaintext in raw JSON, logs, row results, or audit data.
- Secret plaintext may exist only in process memory long enough to enter the approved private-secret mechanism.

### 9.2 Duplicate Detection

Use exact match only, as approved:

- Asset: Site plus source Asset Code/Computer Name.
- Software Product: Publisher plus Product Name plus Version.
- License source: source file/sheet/row plus Product and secret fingerprint.
- Check both within the current batch and against already-published hosted records.
- Report duplicate groups without exposing secret plaintext.

### 9.3 Result Severity

- `error`: missing business key, unparseable required date, negative quantity, unresolved required target, invalid relationship.
- `warning`: incomplete optional value, ambiguous label, unmatched target for reconciliation, Own/Use imbalance.
- `duplicate`: exact source or business-key match.
- `valid`: ready to publish.

Publish is disabled until errors equal zero. Warnings require explicit Admin acknowledgement.

## 10. Migration Review UI

Add an Admin-only navigation item named `ตรวจสอบการย้ายข้อมูล`.

The screen shows:

- Batch status and source fingerprints.
- Counts for Valid, Warning, Error, Duplicate, and Skipped.
- Sheet and row filters.
- Full normalized values and source coordinates.
- Masked secret hints only.
- Row-level validation details and mapping decisions.
- Reconciliation totals for Assets, Software Products, Licenses, Owned, Used/Allocated, and skipped rows.
- Warning acknowledgement and Publish controls.

This screen reviews the approved bundled source files; it is not a permanent self-service upload feature.

## 11. Publish Transaction

`publish_import_batch` must:

1. Lock the batch and verify its version/status.
2. Reject already-published fingerprints.
3. Require zero errors and acknowledged warnings.
4. Resolve approved mapping rules.
5. Upsert exact master-data matches without fuzzy merging.
6. Insert Assets, network records, assignments, Software Products, installed-software inventory, Licenses, secret references, and resolvable Allocations.
7. Preserve `migration_batch_id` and source-row traceability.
8. Create reconciliation totals and an Audit event.
9. Mark the batch published only after every write succeeds.
10. Roll back the entire transaction on any failure.

Re-running extraction is safe. Publishing the same approved source fingerprint twice is not allowed.

## 12. Security

- Expose only the public schema through the Data API.
- Keep migration tables and private secrets inaccessible to `anon` and `authenticated` roles.
- Surface migration review through Admin-checked RPCs or server-only database access.
- Keep `service_role` server/CLI-only.
- Mask secret values by default and Audit every reveal.
- RLS remains the final authorization boundary even when UI actions are hidden.
- Sanitize database and parser errors before returning them to the browser.

## 13. Testing

### Database / pgTAP

- Admin-only RPC execution and User denial.
- RLS read boundaries.
- Optimistic locking conflicts.
- Archive restrictions and impact handling.
- Owned Quantity versus Active Allocated rule.
- Allocation Release history.
- Last Active Admin protection.
- Import validation gates, fingerprint idempotency, transactional rollback, and Audit output.

### Parser and Mapping

- Fixture workbooks without real secrets.
- Multi-row headers and merged-cell handling.
- Formula-result extraction.
- Site-specific sheet adapters.
- Date and quantity normalization.
- Exact duplicate detection.
- Secret redaction from staging and errors.
- Reconciliation against hand-calculated fixture totals.

### Application

- Role-based action-menu visibility.
- Edit Drawer prefill and validation.
- Archive/Release/Deactivate confirmation and required reason.
- Version-conflict and business-rule errors.
- Successful Server Action revalidation.
- Migration review counts, filtering, warning acknowledgement, and Publish states.

### Deployment Verification

- Local database reset and pgTAP pass.
- Unit/component/integration tests pass.
- ESLint and production build pass.
- Hosted migration dry-run before push.
- Hosted database lint and migration history match.
- Stage workbooks and review reconciliation before Publish.
- Verify hosted record totals and Audit events after Publish.

## 14. Deployment Sequence

1. Back up/export the hosted database.
2. Add tested database RPCs, RLS/grants, and migration review surfaces locally.
3. Deploy database migrations to hosted Supabase after dry-run.
4. Implement and switch hosted repository reads.
5. Implement Server Actions and CRUD UI.
6. Implement the two workbook adapters and stage the approved files.
7. Review validation and reconciliation in the Admin screen.
8. Obtain explicit Admin Publish confirmation.
9. Publish the batch transactionally.
10. Verify counts, duplicates/skips, License totals, RLS, and Audit events.
11. Keep the workbooks as retained migration evidence; all later edits occur through the web application.

Never run `supabase db reset --linked`.

## 15. Acceptance Criteria

- No operational page reads from `mockSamRepository`.
- Admin can complete the actions in the Action Matrix against hosted Supabase.
- User cannot see or execute administrative mutations.
- All destructive-looking business actions use the approved terms Archive, Release, or Deactivate.
- No application Hard Delete exists for business records.
- Every administrative mutation has optimistic locking and an Audit event.
- Both Excel files can be staged without storing plaintext secrets in staging or logs.
- Exact duplicates are identified and reviewable.
- Migration cannot publish with errors or unacknowledged warnings.
- A published batch reconciles to reviewed totals and cannot be published twice.
- Tests, lint, build, hosted migration checks, and post-publish verification pass.

