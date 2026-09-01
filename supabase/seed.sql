insert into public.sites (id, code, name_th, name_en, timezone, sort_order)
values
  ('01000000-0000-4000-8000-000000000001', 'FACTORY', 'โรงงาน', 'Factory', 'Asia/Bangkok', 10),
  ('01000000-0000-4000-8000-000000000002', 'BANGKOK_OFFICE', 'สำนักงานกรุงเทพฯ', 'Bangkok Office', 'Asia/Bangkok', 20)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  timezone = excluded.timezone,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.asset_types (id, code, name_th, name_en, sort_order)
values
  ('10000000-0000-4000-8000-000000000001', 'PC', 'คอมพิวเตอร์ตั้งโต๊ะ', 'PC', 10),
  ('10000000-0000-4000-8000-000000000002', 'NOTEBOOK', 'โน้ตบุ๊ก', 'Notebook', 20),
  ('10000000-0000-4000-8000-000000000003', 'SERVER', 'เซิร์ฟเวอร์', 'Server', 30),
  ('10000000-0000-4000-8000-000000000004', 'OTHER', 'อื่น ๆ', 'Other', 99)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.asset_statuses (
  id, code, name_th, name_en, is_operational, is_retired,
  requires_allocation_warning, sort_order
)
values
  ('11000000-0000-4000-8000-000000000001', 'ACTIVE', 'ใช้งาน', 'Active', true, false, false, 10),
  ('11000000-0000-4000-8000-000000000002', 'SPARE', 'สำรอง', 'Spare', true, false, false, 20),
  ('11000000-0000-4000-8000-000000000003', 'REPAIR', 'ซ่อม', 'Repair', false, false, true, 30),
  ('11000000-0000-4000-8000-000000000004', 'RETIRED', 'ปลดระวาง', 'Retired', false, true, true, 40)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  is_operational = excluded.is_operational,
  is_retired = excluded.is_retired,
  requires_allocation_warning = excluded.requires_allocation_warning,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.internet_levels (
  id, code, name_th, name_en, risk_level, description, sort_order
)
values
  ('12000000-0000-4000-8000-000000000001', 'NONE', 'ไม่เชื่อมต่ออินเทอร์เน็ต', 'No internet', 0, 'ไม่อนุญาตให้ออกอินเทอร์เน็ต', 10),
  ('12000000-0000-4000-8000-000000000002', 'RESTRICTED', 'จำกัดการเข้าถึง', 'Restricted', 2, 'เข้าถึงเฉพาะปลายทางที่อนุมัติ', 20),
  ('12000000-0000-4000-8000-000000000003', 'STANDARD', 'ใช้งานมาตรฐาน', 'Standard', 3, 'ใช้งานอินเทอร์เน็ตตามนโยบายองค์กร', 30)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  risk_level = excluded.risk_level,
  description = excluded.description,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.software_categories (id, code, name_th, name_en, sort_order)
values
  ('13000000-0000-4000-8000-000000000001', 'OPERATING_SYSTEM', 'ระบบปฏิบัติการ', 'Operating System', 10),
  ('13000000-0000-4000-8000-000000000002', 'OFFICE', 'โปรแกรมสำนักงาน', 'Office', 20),
  ('13000000-0000-4000-8000-000000000003', 'DATABASE', 'ฐานข้อมูล', 'Database', 30),
  ('13000000-0000-4000-8000-000000000004', 'CAD', 'โปรแกรมออกแบบ', 'CAD', 40),
  ('13000000-0000-4000-8000-000000000005', 'UTILITY', 'โปรแกรมอรรถประโยชน์', 'Utility', 50),
  ('13000000-0000-4000-8000-000000000006', 'BUSINESS_APPLICATION', 'โปรแกรมธุรกิจ', 'Business Application', 60)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.license_metrics (
  id, code, name_th, name_en, target_mode, is_perpetual,
  allows_multi_seat_allocation, sort_order
)
values
  ('14000000-0000-4000-8000-000000000001', 'DEVICE', 'ต่ออุปกรณ์', 'Per Device', 'device', false, false, 10),
  ('14000000-0000-4000-8000-000000000002', 'NAMED_USER', 'ต่อผู้ใช้', 'Named User', 'named_user', false, false, 20),
  ('14000000-0000-4000-8000-000000000003', 'CONCURRENT', 'ใช้งานพร้อมกัน', 'Concurrent', 'concurrent', false, true, 30),
  ('14000000-0000-4000-8000-000000000004', 'SITE', 'ต่อสถานที่', 'Site', 'site', false, true, 40),
  ('14000000-0000-4000-8000-000000000005', 'MIXED', 'แบบผสม', 'Mixed', 'mixed', false, true, 50),
  ('14000000-0000-4000-8000-000000000006', 'PERPETUAL_DEVICE', 'ถาวรต่ออุปกรณ์', 'Perpetual Device', 'device', true, false, 60)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  target_mode = excluded.target_mode,
  is_perpetual = excluded.is_perpetual,
  allows_multi_seat_allocation = excluded.allows_multi_seat_allocation,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.product_classifications (id, code, name_th, name_en, sort_order)
values
  ('15000000-0000-4000-8000-000000000001', 'REGULAR', 'ทั่วไป', 'Regular', 10),
  ('15000000-0000-4000-8000-000000000002', 'OEM', 'ติดมากับอุปกรณ์', 'OEM', 20),
  ('15000000-0000-4000-8000-000000000003', 'SUBSCRIPTION', 'สมาชิก', 'Subscription', 30),
  ('15000000-0000-4000-8000-000000000004', 'PERPETUAL', 'ถาวร', 'Perpetual', 40)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.purchase_forms (id, code, name_th, name_en, sort_order)
values
  ('16000000-0000-4000-8000-000000000001', 'PACKAGE', 'แบบกล่อง', 'Package', 10),
  ('16000000-0000-4000-8000-000000000002', 'VOLUME_LICENSE', 'ลิขสิทธิ์แบบกลุ่ม', 'Volume License', 20),
  ('16000000-0000-4000-8000-000000000003', 'CLOUD_SUBSCRIPTION', 'สมาชิกระบบคลาวด์', 'Cloud Subscription', 30)
on conflict (id) do update set
  code = excluded.code,
  name_th = excluded.name_th,
  name_en = excluded.name_en,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;

insert into public.expiration_thresholds (
  id, days_before_expiry, severity, sort_order
)
values
  ('17000000-0000-4000-8000-000000000001', 90, 'info', 10),
  ('17000000-0000-4000-8000-000000000002', 60, 'warning', 20),
  ('17000000-0000-4000-8000-000000000003', 30, 'critical', 30)
on conflict (id) do update set
  days_before_expiry = excluded.days_before_expiry,
  severity = excluded.severity,
  sort_order = excluded.sort_order,
  is_active = true,
  archived_at = null,
  archived_by = null;
