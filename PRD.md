# Product Requirements Document (PRD)

## Software Asset Management

| รายการ | รายละเอียด |
|---|---|
| ชื่อผลิตภัณฑ์ | Software Asset Management |
| ประเภทระบบ | Web Application สำหรับบริหารอุปกรณ์คอมพิวเตอร์และสิทธิ์การใช้งานซอฟต์แวร์ |
| เวอร์ชันเอกสาร | 1.0 |
| สถานะ | Draft สำหรับทบทวน Requirement |
| วันที่จัดทำ | 1 กันยายน 2026 |
| กลุ่มผู้ใช้งาน | ผู้ดูแลระบบและผู้ใช้งานภายในองค์กร |
| แหล่งข้อมูลตั้งต้น | Excel รายการเครื่องและ License ของ Factory และ Bangkok Office |

---

## 1. บทสรุปผลิตภัณฑ์

Software Asset Management เป็นเว็บแอปพลิเคชันสำหรับรวบรวมและบริหารข้อมูลอุปกรณ์คอมพิวเตอร์ ซอฟต์แวร์ License การติดตั้ง/จัดสรร License ผู้ครอบครองอุปกรณ์ สถานที่ และข้อมูล Network ให้อยู่ในฐานข้อมูลกลางเดียวกัน เพื่อทดแทนการจัดเก็บข้อมูลแบบกระจายใน Excel

ระบบใช้ไฟล์ Excel เดิมสองไฟล์เป็นต้นแบบและแหล่งข้อมูลสำหรับย้ายข้อมูลเข้าระบบครั้งแรกเท่านั้น หลังจากเปิดใช้งานแล้ว ข้อมูลหลักจะถูกเพิ่ม แก้ไข และดูแลผ่านเว็บ โดยไม่มีความต้องการให้ผู้ใช้ Import Excel เป็นงานประจำใน MVP

โครงสร้างข้อมูลหลักต้องแยกอย่างชัดเจนระหว่าง:

1. **Asset** — เครื่องคอมพิวเตอร์หรืออุปกรณ์ที่องค์กรดูแล
2. **Software Product** — ผลิตภัณฑ์ซอฟต์แวร์และเวอร์ชัน
3. **License Entitlement** — สิทธิ์การใช้งานซอฟต์แวร์ที่องค์กรซื้อหรือครอบครอง
4. **License Allocation** — การจัดสรร License ให้กับ Asset หรือผู้ใช้งาน

การแยกข้อมูลดังกล่าวทำให้ระบบคำนวณจำนวน License ที่ซื้อ จำนวนที่ใช้ จำนวนคงเหลือ และสถานะ Compliance ได้ถูกต้องกว่าการบันทึกชื่อซอฟต์แวร์เป็นหลายคอลัมน์ใน Excel

---

## 2. ที่มาและปัญหาที่ต้องแก้ไข

### 2.1 สภาพปัจจุบัน

ข้อมูลปัจจุบันถูกจัดเก็บใน Excel แยกตามพื้นที่ Factory และ Bangkok Office โดยมีทั้งข้อมูลเครื่องคอมพิวเตอร์ ข้อมูล Network ระบบปฏิบัติการ รายการซอฟต์แวร์ จำนวน License ที่มี จำนวนที่ใช้ Serial Number วันที่ซื้อ วันเริ่มต้น วันสิ้นสุด และสถานะ License

จากการตรวจสอบไฟล์ต้นแบบ พบโครงสร้างสำคัญดังนี้:

- ไฟล์ `02 203Total License(TKC) Update 2026-08-28.xlsx`
  - ชีต `Software(Factory)` สำหรับข้อมูลเครื่องใน Factory
  - ชีต `Software(Bangkok Offic)` สำหรับข้อมูลเครื่องใน Bangkok Office
  - มีข้อมูล Location, ผู้รับผิดชอบ, ประเภท NB/PC, Code No., Computer Name, User, MAC Address, IP Address, VLAN, Internet Level, Workgroup, OS และคอลัมน์ซอฟต์แวร์จำนวนมาก
- ไฟล์ `03 Lisense list software thaikurabo factory office Update 2026-08-28.xlsx`
  - ชีต `Software License FACTORY`
  - ชีต `Software License OFFICE `
  - ชีตสรุป `Summary Factory` และ `Summary Office`
  - มีข้อมูล Maker, Dealer, Product Name, Version, Product Classification, Purchase Form, Own License, Use License, Serial No., Purchase/Start/End Date, Status, Name, Install Date และ Remark

### 2.2 ปัญหาหลัก

- ข้อมูล Asset และ License ปะปนกันและมีโครงสร้างต่างกันในแต่ละชีต
- ซอฟต์แวร์แต่ละชนิดถูกสร้างเป็นคอลัมน์ ทำให้เพิ่มผลิตภัณฑ์หรือเวอร์ชันใหม่ได้ยาก
- การคำนวณจำนวน License ที่ซื้อ ใช้ และคงเหลือขึ้นกับสูตรหรือ Pivot ใน Excel
- ข้อมูลชื่อสถานที่ ผู้ใช้งาน ผลิตภัณฑ์ และสถานะมีโอกาสสะกดหรือกำหนดรูปแบบไม่เหมือนกัน
- การตรวจสอบว่า License ใดถูกใช้กับเครื่องใดทำได้ยาก
- License Key และ Serial Number เป็นข้อมูลสำคัญ แต่ Excel ไม่มีการควบคุมสิทธิ์ในระดับข้อมูลอย่างเหมาะสม
- ไม่มี Audit Trail ที่ระบุว่าใครแก้ข้อมูลใด เมื่อใด และเปลี่ยนจากค่าใดเป็นค่าใด
- การจัดทำรายงานภาพรวมข้าม Factory และ Bangkok Office ต้องรวมข้อมูลด้วยตนเอง

---

## 3. วิสัยทัศน์ผลิตภัณฑ์

สร้างแหล่งข้อมูลกลางที่เชื่อถือได้สำหรับ Software Asset Management ซึ่งช่วยให้องค์กรตอบคำถามสำคัญได้ทันทีว่า:

- องค์กรมี Asset อะไร อยู่ที่ใด และใครเป็นผู้ใช้งานหรือรับผิดชอบ
- แต่ละ Asset ใช้ OS และซอฟต์แวร์อะไร
- องค์กรซื้อ License อะไร จำนวนเท่าใด และกำลังใช้อยู่จำนวนเท่าใด
- License ใดใกล้หมดอายุ หมดอายุ ใช้เกินสิทธิ์ หรือมีจำนวนเหลือ
- License แต่ละรายการถูกจัดสรรให้เครื่องหรือผู้ใช้งานใด
- ข้อมูล Factory, Bangkok Office และภาพรวมองค์กรมีสถานะอย่างไร

---

## 4. เป้าหมายและตัวชี้วัดความสำเร็จ

### 4.1 เป้าหมายทางธุรกิจ

1. รวมข้อมูล Asset และ License จาก Excel ให้เป็นฐานข้อมูลกลางเดียว
2. ลดเวลาในการค้นหา ตรวจสอบ และจัดทำรายงาน Asset/License
3. ลดความเสี่ยงจากการใช้ License เกินจำนวนหรือปล่อยให้ License หมดอายุโดยไม่ทราบล่วงหน้า
4. เพิ่มความถูกต้อง ตรวจสอบย้อนกลับได้ และกำหนดผู้รับผิดชอบข้อมูลได้
5. รองรับการบริหารข้อมูลแยกตาม Site แต่ดูภาพรวมข้าม Site ได้

### 4.2 ตัวชี้วัดความสำเร็จของ MVP

- ย้ายข้อมูลที่ผ่านการอนุมัติจาก Excel เข้าระบบได้ครบตามฟิลด์ที่กำหนด
- จำนวน Asset และ License หลัง Migration ตรงกับรายงาน Reconciliation ที่ผู้ดูแลรับรอง
- ผู้ใช้สามารถค้นหา Asset หรือ License ที่ต้องการได้ภายในไม่เกิน 3 ขั้นตอนจากหน้า Dashboard
- ระบบคำนวณ Owned, Allocated และ Available License อัตโนมัติ
- ระบบแสดงรายการ License ที่หมดอายุหรือใกล้หมดอายุได้ถูกต้องตามวันที่
- ผู้ใช้ทั่วไปไม่สามารถเพิ่ม แก้ไข ลบ หรือตั้งค่าระบบได้
- ทุกการเปลี่ยนแปลงข้อมูลสำคัญโดย Admin มี Audit Log
- รายงานหลักสามารถกรอง Factory, Bangkok Office และ All Sites ได้

---

## 5. ขอบเขตผลิตภัณฑ์

### 5.1 In Scope — MVP

- Authentication และ Role-based Access Control
- Role `Admin` และ `User`
- Dashboard ภาพรวม Asset และ License
- Asset Management
- Software Product Catalog
- License Management
- License Allocation ระหว่าง License กับ Asset หรือผู้ใช้งาน
- Master Data Management สำหรับ Site, Location, Department, Asset Type, License Type และ Status
- ค้นหา กรอง เรียงลำดับ และแบ่งหน้า
- รายงาน Asset และ License
- Export รายงานเป็น Excel/CSV และ PDF ตามรูปแบบที่ระบบรองรับ
- การแจ้งเตือนในระบบสำหรับ License ใกล้หมดอายุ/หมดอายุ
- Audit Log
- Initial Data Migration จาก Excel สองไฟล์เพียงครั้งเดียว
- Responsive Web สำหรับ Desktop และ Tablet
- UI ภาษาไทยเป็นหลัก โดยเก็บชื่อข้อมูลเดิมภาษาอังกฤษได้

### 5.2 Out of Scope — MVP

- Import Excel แบบ Self-service หรือแบบงานประจำหลัง Go-live
- Agent สำหรับ Scan เครื่องและตรวจจับซอฟต์แวร์อัตโนมัติ
- Integration กับ Microsoft Intune, Active Directory, Entra ID, SCCM หรือระบบจัดซื้อ
- Mobile Application แบบ Native
- Workflow ขอซื้อ/อนุมัติจัดซื้อ License แบบเต็มรูปแบบ
- ระบบบัญชี ค่าเสื่อมราคา หรือ Fixed Asset Accounting
- Software Metering หรือวัดเวลาการใช้งานจริง
- Barcode/QR Code และการตรวจนับผ่านมือถือ
- Email/LINE/Teams Notification; MVP ใช้ In-app Notification ก่อน
- การบริหาร Hardware Asset ประเภทอื่นนอกเหนือจากที่กำหนดในการย้ายข้อมูล เว้นแต่ Admin เพิ่มประเภทผ่าน Master Data

### 5.3 แนวทางสำหรับระยะถัดไป

- Email Notification ตามรอบเวลา
- Discovery Agent หรือเชื่อมต่อ Endpoint Management
- Procurement และ Approval Workflow
- QR Code/Barcode สำหรับตรวจนับ
- Contract และ Vendor Management ขั้นสูง
- API สำหรับเชื่อมต่อระบบภายนอก

---

## 6. ผู้ใช้งานและสิทธิ์

### 6.1 Persona: Admin

ผู้ดูแลระบบหรือเจ้าหน้าที่ IT ที่รับผิดชอบความถูกต้องของข้อมูล Asset และ License

ความต้องการหลัก:

- เข้าถึงทุกเมนู
- เพิ่ม ดู แก้ไข Archive และจัดการข้อมูล
- จัดสรร/ถอนการจัดสรร License
- ดู License Key/Serial Number ฉบับเต็ม
- ตั้งค่า Master Data และค่าระบบ
- จัดการบัญชีผู้ใช้และ Role
- ดู Audit Log
- Export รายงาน
- ตรวจสอบและแก้ไขข้อผิดพลาดจากการย้ายข้อมูล

### 6.2 Persona: User

พนักงานหรือผู้บริหารที่ต้องการดูข้อมูลและรายงาน แต่ไม่มีหน้าที่แก้ไขข้อมูล

ความต้องการหลัก:

- ดู Dashboard
- ดูและค้นหาข้อมูล Asset
- ดูและค้นหาข้อมูล License
- ดูการจัดสรร License
- ดูและ Export รายงานที่ได้รับอนุญาต
- เห็น License Key/Serial Number ในรูปแบบปกปิด เช่น `XXXXX-XXXXX-XXXXX-AB123`
- ไม่สามารถเพิ่ม แก้ไข Archive ลบ จัดสรร License หรือเปลี่ยนค่าระบบ

### 6.3 Permission Matrix

| ความสามารถ | Admin | User |
|---|:---:|:---:|
| Login/Logout | ✓ | ✓ |
| ดู Dashboard | ✓ | ✓ |
| ดู Asset/License/Allocation | ✓ | ✓ |
| ค้นหา กรอง และเรียงข้อมูล | ✓ | ✓ |
| Export รายงาน | ✓ | ✓ |
| เพิ่ม/แก้ไข/Archive Asset | ✓ | — |
| เพิ่ม/แก้ไข/Archive License | ✓ | — |
| จัดสรร/ถอน License | ✓ | — |
| ดู License Key เต็ม | ✓ | — |
| ดู License Key แบบปกปิด | ✓ | ✓ |
| จัดการ Master Data | ✓ | — |
| จัดการผู้ใช้และ Role | ✓ | — |
| ดู Audit Log | ✓ | — |
| ตั้งค่าระบบ | ✓ | — |

> หลักการสำคัญ: การซ่อนปุ่มใน UI ไม่เพียงพอ Backend ต้องตรวจสิทธิ์ทุก Request ด้วย

---

## 7. Information Architecture และเมนูระบบ

### 7.1 เมนูสำหรับ Admin

1. Dashboard
2. Assets
3. Software Products
4. Licenses
5. License Allocations
6. Reports
7. Notifications
8. Master Data
9. User Management
10. Audit Logs
11. System Settings

### 7.2 เมนูสำหรับ User

1. Dashboard
2. Assets
3. Software Products
4. Licenses
5. License Allocations
6. Reports
7. Notifications

เมนูจัดการและตั้งค่าต้องไม่ปรากฏต่อ User และหากเข้าผ่าน URL โดยตรงต้องได้รับ HTTP 403 หรือหน้า Access Denied

---

## 8. Functional Requirements

### FR-01 Authentication และ Session

- ผู้ใช้ Login ด้วย Username/Email และ Password
- ระบบตรวจสอบสถานะบัญชี Active ก่อนอนุญาตให้เข้าใช้งาน
- เมื่อ Login สำเร็จ ระบบนำไปหน้า Dashboard
- เมื่อข้อมูลไม่ถูกต้อง ระบบแสดงข้อความทั่วไปโดยไม่เปิดเผยว่าบัญชีมีอยู่หรือไม่
- รองรับ Logout และยกเลิก Session ฝั่ง Server
- Session หมดอายุเมื่อไม่มีการใช้งานตามค่าที่ Admin กำหนด
- บัญชีถูกล็อกชั่วคราวเมื่อ Login ผิดเกินจำนวนครั้งที่กำหนด
- Password ต้องถูกจัดเก็บด้วย Strong Password Hash ห้ามเก็บ Plain Text

### FR-02 Dashboard

Dashboard ต้องรองรับ Filter `All Sites`, `Factory` และ `Bangkok Office` และแสดงข้อมูลอย่างน้อย:

- จำนวน Asset ทั้งหมด
- จำนวน Notebook, PC, Server และประเภทอื่น
- จำนวน Asset แยกตามสถานะ เช่น Active, Spare, Repair, Retired
- จำนวน License Entitlement ทั้งหมด
- จำนวน License ที่ซื้อ/ครอบครอง
- จำนวน License ที่จัดสรรแล้ว
- จำนวน License คงเหลือ
- จำนวน License ที่ใช้เกินสิทธิ์
- จำนวน License ที่จะหมดอายุภายใน 30, 60 และ 90 วัน
- จำนวน License ที่หมดอายุ
- Top Software Products ตามจำนวนที่ใช้งาน
- สัดส่วน Asset ตาม Site, Department หรือ OS
- รายการแจ้งเตือนเร่งด่วนล่าสุด

การคลิก KPI หรือกราฟต้องเปิดหน้ารายการพร้อม Filter ที่สัมพันธ์กัน เมื่อทำได้ในขอบเขต MVP

### FR-03 Asset Management

Admin ต้องสามารถเพิ่ม ดู แก้ไข และ Archive Asset ได้ ส่วน User ดูได้อย่างเดียว

#### ข้อมูล Asset ขั้นต่ำ

| กลุ่ม | ฟิลด์ |
|---|---|
| ตัวตน | Asset ID, Asset Code/Code No., Computer Name |
| การจัดประเภท | Asset Type เช่น PC, Notebook, Server, Other |
| องค์กร | Site, Location, Department/Workgroup |
| ผู้รับผิดชอบ | Primary User, Responsible Person, Additional Users |
| Hardware | Maker, Model/Type, Purchase Date |
| Network | LAN MAC, Secondary LAN MAC, Wi-Fi MAC, LAN IP, Secondary IP, Wi-Fi IP, VLAN |
| การเข้าถึง | Internet Level, Risk/Access Level ถ้ามี |
| ระบบปฏิบัติการ | OS Product, OS Version/Edition, OS License/Key อ้างอิง |
| สถานะ | Active, Spare, Repair, Retired, Lost หรือค่าใน Master Data |
| อื่น ๆ | Remark, Created By/At, Updated By/At |

#### กฎการทำงาน

- Asset Code ต้องไม่ซ้ำเมื่อมีค่า
- Computer Name ต้องไม่ซ้ำภายใน Site เว้นแต่ Admin ยืนยันกรณีพิเศษ
- MAC Address ต้องผ่านรูปแบบที่กำหนดและ Normalize เป็นรูปแบบเดียว
- IP Address ต้องตรวจรูปแบบ IPv4/IPv6 หรือเก็บค่าพิเศษที่อนุญาต เช่น DHCP, Not Connected
- Asset ที่ถูก Archive ยังคงปรากฏในประวัติและรายงานย้อนหลัง
- Asset ที่มี Active Allocation ต้องไม่ถูกลบถาวร
- หน้า Asset Detail ต้องแสดงซอฟต์แวร์/License ที่จัดสรรให้ Asset นั้น
- รองรับการค้นหาด้วย Asset Code, Computer Name, User, MAC, IP และ OS

### FR-04 Software Product Catalog

Software Product เป็น Master ของชื่อซอฟต์แวร์ แยกจากสิทธิ์ License

ฟิลด์ขั้นต่ำ:

- Product ID
- Publisher/Maker
- Product Name
- Version/Edition
- Product Category เช่น Operating System, Office, Database, CAD, Utility, Business Application
- Supported/End-of-Life Status ถ้ามีข้อมูล
- Active/Archived
- Remark

กฎการทำงาน:

- Product ต้องไม่ซ้ำตามชุด Publisher + Product Name + Version/Edition
- การแก้ชื่อ Product ต้องสะท้อนใน License และ Allocation ที่อ้างอิงโดยไม่สร้างข้อมูลซ้ำ
- Admin สามารถ Merge Product ที่ซ้ำกันได้ในระยะหลัง; สำหรับ MVP ให้แก้ไขข้อมูล Migration ก่อน Go-live

### FR-05 License Management

License Entitlement แทนสิทธิ์ที่องค์กรซื้อหรือครอบครอง โดย License หนึ่งรายการอาจมีสิทธิ์มากกว่าหนึ่ง Seat

#### ข้อมูล License ขั้นต่ำ

| กลุ่ม | ฟิลด์ |
|---|---|
| ตัวตน | License ID, License Reference/Document No. |
| ผลิตภัณฑ์ | Software Product |
| ผู้ขาย | Dealer/Vendor |
| ประเภท | Product Classification, Purchase Form, License Metric/Type |
| จำนวน | Owned Quantity, Allocated Quantity (คำนวณ), Available Quantity (คำนวณ) |
| ข้อมูลลับ | Serial Number, Product Key/License Key |
| วันที่ | Purchase Date, Start Date, End Date |
| สถานะ | Draft, Active, Expiring Soon, Expired, Deactivated, Archived |
| ขอบเขต | Owning Organization, Site หรือ All Sites |
| เอกสาร | Invoice/PO/Contract Reference; Attachment เป็น Phase ถัดไปหากยังไม่มีระบบไฟล์ |
| อื่น ๆ | Name/Owner, Install Date เดิม, Remark, Created/Updated Metadata |

#### กฎการคำนวณ

- `Allocated Quantity` = จำนวน Allocation ที่ Active ของ License นั้น หรือผลรวม Quantity หาก Allocation รองรับหลาย Seat
- `Available Quantity` = `Owned Quantity - Allocated Quantity`
- `Compliance Status`:
  - Compliant เมื่อ Available Quantity ≥ 0
  - Over-allocated เมื่อ Available Quantity < 0
  - Untracked เมื่อ Owned Quantity ไม่ระบุหรือข้อมูลไม่สมบูรณ์
- `Lifecycle Status`:
  - Expired เมื่อ End Date น้อยกว่าวันปัจจุบัน
  - Expiring Soon เมื่อ End Date อยู่ภายใน Threshold ที่กำหนด เช่น 90 วัน
  - Active เมื่ออยู่ในช่วงใช้งานและไม่ถูก Deactivate/Archive
  - Perpetual เมื่อไม่มี End Date และประเภท License ระบุว่าไม่หมดอายุ
- สถานะที่คำนวณต้องไม่ทับสถานะทางธุรกิจที่ Admin กำหนดโดยไม่มีประวัติ

#### การปกป้อง License Key

- Admin ที่ได้รับสิทธิ์เท่านั้นจึงดูค่าฉบับเต็มได้
- User เห็นเฉพาะอักขระท้ายจำนวนที่กำหนด
- License Key ต้องเข้ารหัสขณะจัดเก็บและส่งผ่าน HTTPS
- Audit Log ต้องบันทึกเหตุการณ์การเปิดดูค่าฉบับเต็ม โดยไม่บันทึกค่าจริงลง Log
- Export สำหรับ User ต้องส่งออกค่าแบบปกปิด

### FR-06 License Allocation

Admin ต้องสามารถจัดสรร License ให้แก่:

- Asset หนึ่งเครื่อง
- ผู้ใช้งานหนึ่งคน สำหรับ Named-user License
- หน่วยงานหรือ Site สำหรับ License แบบ Shared/Site หากประเภท License รองรับ

ฟิลด์ขั้นต่ำ:

- Allocation ID
- License ID
- Allocation Target Type
- Asset/User/Site ที่ได้รับสิทธิ์
- Quantity
- Allocation Date
- Install Date
- Removal/Deallocation Date
- Status: Active, Removed
- Remark
- Created/Updated Metadata

กฎการทำงาน:

- ค่าเริ่มต้น Quantity = 1
- ระบบเตือนก่อนจัดสรรเกินจำนวนที่ซื้อ
- การจัดสรรเกินสิทธิ์ต้องถูก Block เป็นค่าเริ่มต้น; หากองค์กรต้องการ Allow Override ให้ Admin ระบุเหตุผลและบันทึก Audit Log
- Target เดียวกันต้องไม่รับ License เดียวกันซ้ำโดยไม่ตั้งใจ
- เมื่อ Asset ถูก Retired ระบบต้องเตือนให้ถอน Allocation ที่ยัง Active
- การถอน Allocation ต้องเก็บประวัติ ไม่ลบรายการเดิม

### FR-07 Master Data

Admin สามารถจัดการ Master Data ได้แก่:

- Site
- Location
- Department/Workgroup
- Asset Type
- Asset Status
- Publisher/Maker
- Vendor/Dealer
- Software Category
- License Type/Metric
- Product Classification
- Purchase Form
- Internet Level
- Expiration Threshold

Master Data ที่ถูกใช้งานแล้วต้อง Archive แทนการลบ เพื่อรักษาความถูกต้องของข้อมูลย้อนหลัง

### FR-08 Search, Filter และ List Behavior

- ทุกหน้ารายการต้องมี Search และ Filter ที่สัมพันธ์กับข้อมูล
- รองรับ Multi-filter เช่น Site + Status + Product + Expiration Range
- ผู้ใช้สามารถ Clear Filter และเห็น Filter ที่กำลังใช้งาน
- รองรับ Sort ตามคอลัมน์หลัก
- รองรับ Pagination และเลือกจำนวนรายการต่อหน้า
- URL ควรเก็บ Filter State เพื่อ Bookmark หรือย้อนกลับได้
- แสดง Empty State, Loading State และ Error State ที่เข้าใจง่าย
- ค่า Sensitive ต้องปกปิดทั้งใน List, Detail, Export และ API Response ตาม Role

### FR-09 Reports

รายงานขั้นต่ำใน MVP:

1. Asset Inventory Report
2. Asset by Site/Location/Department
3. Asset by Type and Status
4. Asset by Operating System
5. Software Installed/Allocated by Asset
6. License Inventory Report
7. License Owned vs Allocated vs Available
8. Over-allocated License Report
9. Expired License Report
10. License Expiring in 30/60/90 Days
11. Unused License Report
12. License Allocation by Asset/User
13. Data Quality Report สำหรับรายการที่ข้อมูลสำคัญไม่ครบ
14. Migration Reconciliation Report สำหรับใช้ก่อน Go-live

ข้อกำหนดรายงาน:

- กรองตาม Site, Product, Publisher, Status และช่วงวันที่ตามความเหมาะสม
- User และ Admin ดู/Export ได้ตามสิทธิ์
- Export ต้องระบุวันที่ออกรายงาน ผู้สร้างรายงาน และ Filter ที่ใช้
- จำนวนใน Dashboard และ Report ต้องใช้กฎการคำนวณเดียวกัน
- Report ที่มี License Key ต้องปกปิดตาม Role

### FR-10 Notifications

- ระบบสร้าง In-app Notification เมื่อ License ใกล้หมดอายุตาม Threshold
- ระบบสร้าง Notification เมื่อ License หมดอายุ
- ระบบแจ้งเตือนเมื่อ License ถูกใช้ครบหรือเกินสิทธิ์
- Admin เห็น Notification ทั้งหมด
- User เห็น Notification แบบอ่านอย่างเดียวตามข้อมูลที่มีสิทธิ์เข้าถึง
- รองรับสถานะ Read/Unread
- งานตรวจสอบวันหมดอายุทำงานอย่างน้อยวันละครั้ง

### FR-11 User Management

Admin สามารถ:

- สร้างบัญชีผู้ใช้
- กำหนด Role Admin หรือ User
- แก้ชื่อ Email และสถานะบัญชี
- Activate/Deactivate บัญชี
- Reset Password หรือส่งกระบวนการตั้งรหัสผ่านใหม่
- ดูวันที่ Login ล่าสุด

ข้อจำกัด:

- Admin ต้องไม่สามารถ Deactivate บัญชี Admin คนสุดท้ายได้
- ผู้ใช้ที่ถูก Deactivate ต้องไม่สามารถสร้าง Session ใหม่
- การเปลี่ยน Role และสถานะบัญชีต้องถูกบันทึกใน Audit Log

### FR-12 Audit Log

ระบบต้องบันทึกอย่างน้อย:

- Login สำเร็จ/ล้มเหลวและ Logout
- Create, Update, Archive และ Restore ข้อมูลสำคัญ
- การจัดสรรและถอน License
- การเปลี่ยน Role หรือสถานะผู้ใช้
- การเปลี่ยนค่าระบบ
- การดู License Key ฉบับเต็ม
- การ Export รายงานที่มีข้อมูลสำคัญ

ข้อมูลใน Log:

- วันเวลา
- ผู้กระทำ
- ประเภท Action
- Entity Type และ Entity ID
- ค่าเดิม/ค่าใหม่สำหรับฟิลด์ที่เหมาะสม โดยต้องตัดข้อมูลลับออก
- IP Address และ User Agent หากนโยบายองค์กรอนุญาต

Audit Log เป็น Append-only สำหรับผู้ใช้ระบบทั่วไป และต้องกำหนด Retention Policy

### FR-13 System Settings

Admin สามารถตั้งค่า:

- ชื่อองค์กรและโลโก้
- Timezone เริ่มต้น: Asia/Bangkok
- รูปแบบวันที่
- Session Timeout
- จำนวนครั้ง Login ผิดก่อน Lock
- Threshold License Expiration เช่น 30, 60, 90 วัน
- อักขระ License Key ที่ให้ User เห็น
- นโยบาย Allow/Block Over-allocation
- Default Page Size

---

## 9. แบบจำลองข้อมูลระดับผลิตภัณฑ์

### 9.1 Entity หลัก

| Entity | หน้าที่ | ความสัมพันธ์สำคัญ |
|---|---|---|
| UserAccount | บัญชีเข้าใช้ระบบ | มีหนึ่ง Role; อาจเชื่อม Employee ในอนาคต |
| Role | กลุ่มสิทธิ์ | Admin หรือ User ใน MVP |
| Site | พื้นที่องค์กร | มีหลาย Location และ Asset |
| Location | ตำแหน่งย่อย | อยู่ภายใต้ Site; มีหลาย Asset |
| Department | หน่วยงาน/Workgroup | มีหลาย Asset/User |
| Asset | อุปกรณ์คอมพิวเตอร์ | อยู่ใน Site/Location; มีหลาย Allocation |
| AssetNetworkInterface | MAC/IP ของ Asset | Asset หนึ่งรายการมีได้หลาย Interface |
| SoftwareProduct | ผลิตภัณฑ์ซอฟต์แวร์ | มีหลาย License Entitlement |
| Vendor | ผู้ขาย/Dealer | มีหลาย License Entitlement |
| LicenseEntitlement | สิทธิ์ License ที่ซื้อ | อ้าง Product; มีหลาย Allocation |
| LicenseAllocation | การใช้สิทธิ์ | เชื่อม License กับ Asset/User/Site |
| Notification | เหตุการณ์แจ้งเตือน | อ้าง License หรือ Asset ได้ |
| AuditLog | ประวัติการกระทำ | อ้างผู้กระทำและ Entity |
| MasterData | ค่ามาตรฐาน | สนับสนุนประเภทและสถานะต่าง ๆ |

### 9.2 ความสัมพันธ์เชิงแนวคิด

```text
Site 1 ── * Location 1 ── * Asset
Department 1 ── * Asset
Asset 1 ── * Network Interface
Software Product 1 ── * License Entitlement
Vendor 1 ── * License Entitlement
License Entitlement 1 ── * License Allocation
Asset/User/Site 1 ── * License Allocation
User Account * ── 1 Role
```

### 9.3 หลักการเก็บข้อมูล

- ใช้ Internal ID ที่ไม่เปลี่ยนแปลงเป็น Primary Key
- Asset Code, Computer Name, Product Name และ License Reference เป็น Business Identifier ไม่ใช้แทน Primary Key
- ใช้ Soft Delete/Archive สำหรับข้อมูลธุรกิจ
- เก็บ Created At, Created By, Updated At, Updated By ในตารางสำคัญ
- เก็บวันที่เป็น Date/DateTime แบบมาตรฐาน และแสดงผลตาม Timezone/Locale
- แยกข้อมูล Network หลาย Interface ออกจาก Asset เพื่อรองรับ LAN/Wi-Fi หลายรายการ
- ไม่สร้างคอลัมน์ใหม่ทุกครั้งที่มีซอฟต์แวร์ใหม่
- License Key/Serial Number ต้องใช้ Field-level Encryption หรือกลไกเทียบเท่า

---

## 10. Initial Data Migration

### 10.1 ขอบเขต

ใช้ Excel สองไฟล์เป็นแหล่งย้ายข้อมูลครั้งแรกเท่านั้น การ Migration ต้องทำผ่าน Script/เครื่องมือควบคุมโดยทีมโครงการ ไม่เปิดเป็นเมนูให้ผู้ใช้ทั่วไป

### 10.2 Source-to-Target Mapping ระดับสูง

| ข้อมูลต้นทาง | เป้าหมายในระบบ |
|---|---|
| Factory / Bangkok Office | Site |
| Location | Location |
| Workgroup | Department/Workgroup |
| Code No. | Asset Code |
| Computer Name | Asset Computer Name |
| NB / PC / Server | Asset Type |
| Persons responsible / User 1-4 | Asset Owner/User Association |
| Maker / Type / Pr.date | Asset Manufacturer/Model/Purchase Date |
| LAN/Wi-Fi MAC และ IP | Asset Network Interface |
| VLAN / Internet Level | Asset Network/Access Metadata |
| OS / License Key | Software Product + License/Allocation ตามกฎ Mapping |
| Maker | Software Publisher |
| Dealer | Vendor |
| Product Name + Version | Software Product |
| Product Classification | Product/License Classification |
| Purchase Form | License Purchase Form |
| Own License | License Owned Quantity |
| Use License | จำนวนใช้สำหรับ Reconciliation; เป้าหมายจริงมาจาก Allocation |
| Serial No. | License Serial/Key (Encrypted) |
| Purchase/Start/End Date | License Dates |
| Status | License Business/Lifecycle Status |
| Name / Remark | License Owner/Notes |
| Summary Factory/Office | ใช้ตรวจยอด ไม่ Import เป็นข้อมูล Transaction |

### 10.3 ขั้นตอน Migration

1. สำรองไฟล์ต้นฉบับและคำนวณ Checksum
2. Extract ข้อมูลจากแต่ละชีตเข้าสู่ Staging
3. Normalize ชื่อ Site, Location, Department, Publisher, Product, Version, Status และวันที่
4. ตรวจสอบ Duplicate Asset ด้วย Asset Code, Computer Name, MAC และ IP
5. ตรวจสอบ Duplicate License ด้วย Product, Version, Serial/Key, Vendor และ Purchase Reference
6. แปลงคอลัมน์ซอฟต์แวร์แบบแนวนอนของไฟล์ Asset เป็น Product/Allocation แบบรายการ
7. แยกค่าพิเศษ เช่น DHCP, NOT CONNECT NETWORK, OEM, NO KEY และช่องว่างออกจากค่าปกติ
8. สร้าง Data Quality Report และรายการที่ต้องให้ Admin ตัดสินใจ
9. ทำ Dry Run เข้าฐานข้อมูลทดสอบ
10. Reconcile ยอด Asset, Owned License และ Used License กับ Source Summary
11. ให้ผู้รับผิดชอบลงนามรับรองผล
12. ทำ Final Migration และล็อกไฟล์เดิมเป็น Read-only Archive

### 10.4 กฎ Data Quality

- วันที่ต้องแปลงเป็นรูปแบบเดียวและตรวจค่าที่ Excel เก็บเป็น Serial Date
- Trim ช่องว่างและ Normalize ตัวพิมพ์สำหรับการตรวจข้อมูลซ้ำ โดยไม่ทำลายค่าที่แสดงผล
- รายการที่ไม่มี Asset Code ต้องสร้าง Migration Reference ชั่วคราวและ Flag ให้ตรวจสอบ
- License ที่ไม่มี Owned Quantity ต้องเป็น `Untracked` ไม่สมมติเป็น 0 หรือ 1
- Status เช่น Active, Deactivate, Expired และค่าที่ว่างต้อง Mapping ด้วยตารางกฎที่อนุมัติ
- รายการ `CANCEL` หรือ `Not connect` ต้องเก็บ Remark และกำหนดสถานะตามกฎที่อนุมัติ
- Key ซ้ำอาจเป็น Volume License ที่ถูกต้อง ต้องไม่ Deduplicate โดยอัตโนมัติโดยไม่มีการตรวจสอบ
- Summary Sheet ใช้เป็น Control Total เท่านั้น เนื่องจากอาจเป็น Pivot/ข้อมูลสรุปหลายระดับ

### 10.5 Acceptance Criteria ของ Migration

- ทุกแถวต้นทางต้องมีสถานะ Imported, Merged, Skipped หรือ Error พร้อมเหตุผล
- ไม่มี Error ที่ยังไม่ถูกตัดสินใจก่อน Go-live
- จำนวน Asset แยกตาม Site ตรงกับ Control Total ที่ได้รับอนุมัติ
- Owned/Used License ตรงกับนิยามและรายงาน Reconciliation ที่ได้รับอนุมัติ
- ข้อมูล Sensitive ถูกเข้ารหัสก่อนเปิดระบบให้ผู้ใช้
- Sampling Asset และ License อย่างน้อยตามแผน UAT แสดงข้อมูลตรงกับ Excel
- เก็บ Migration Log, Mapping Rules และ Source Checksum เพื่อ Audit

---

## 11. Business Rules

| รหัส | กฎ |
|---|---|
| BR-01 | Asset Code ต้องไม่ซ้ำเมื่อมีค่า |
| BR-02 | Asset หนึ่งรายการอยู่ภายใต้ Site หลักหนึ่งแห่ง ณ เวลาปัจจุบัน |
| BR-03 | Software Product ไม่เท่ากับ License; Product หนึ่งรายการมี License ได้หลายรายการ |
| BR-04 | License หนึ่งรายการมี Allocation ได้หลายรายการตามจำนวนสิทธิ์ |
| BR-05 | Available License คำนวณจาก Owned ลบ Active Allocated เท่านั้น |
| BR-06 | License แบบ Perpetual ไม่มีวันหมดอายุ แต่ยังสามารถถูก Deactivate/Archive ได้ |
| BR-07 | License ที่ End Date ผ่านแล้วเป็น Expired แม้ Business Status เดิมไม่ถูกอัปเดต |
| BR-08 | การจัดสรรเกิน Owned Quantity ถูก Block เว้นแต่เปิด Override และระบุเหตุผล |
| BR-09 | ข้อมูลที่มีประวัติใช้งานแล้วใช้ Archive แทน Hard Delete |
| BR-10 | User ไม่เห็น Secret ฉบับเต็มผ่าน UI, Export หรือ API |
| BR-11 | Dashboard และ Report ต้องคำนวณจากแหล่งข้อมูลและกฎเดียวกัน |
| BR-12 | การแก้ Owned Quantity ให้ต่ำกว่า Allocated Quantity ต้องเตือนหรือ Block ตามนโยบาย |
| BR-13 | Asset ที่ Retired ต้องไม่มี Active Allocation โดยไม่มี Warning/Exception |
| BR-14 | ทุกการเปลี่ยนแปลงข้อมูลสำคัญต้องระบุผู้กระทำและเวลา |

---

## 12. UX/UI Requirements

### 12.1 Visual Direction

ใช้โทนสีฟ้า เทา และขาว ให้ความรู้สึกสะอาด เป็นระบบ และเหมาะกับ Enterprise Application

สีแนะนำ:

- Primary Blue: `#2563EB`
- Dark Blue: `#1E3A8A`
- Light Blue Background: `#EFF6FF`
- Slate Gray: `#475569`
- Light Gray: `#E2E8F0`
- Page Background: `#F8FAFC`
- White: `#FFFFFF`
- Success: `#16A34A`
- Warning: `#D97706`
- Error/Critical: `#DC2626`

### 12.2 Layout

- Sidebar สำหรับเมนูหลัก
- Top bar สำหรับชื่อหน้า Search/Notification/Profile ตามความเหมาะสม
- Dashboard ใช้ KPI Cards, ตารางแจ้งเตือน และกราฟที่อ่านง่าย
- หน้ารายการใช้ Data Table พร้อม Filter Bar
- หน้า Detail แบ่งเป็น Overview, Network, Software/License และ History
- Form ใช้ Section และ Label ชัดเจน พร้อมระบุ Required Field
- ยืนยันก่อน Archive, ถอน Allocation หรือทำ Action ที่มีผลกระทบสูง

### 12.3 Accessibility และ Usability

- Contrast ของข้อความและปุ่มต้องผ่าน WCAG 2.1 AA เป็นเป้าหมาย
- ไม่ใช้สีเป็นวิธีเดียวในการสื่อสถานะ ต้องมีข้อความหรือ Icon ร่วมด้วย
- รองรับ Keyboard Navigation สำหรับงานหลัก
- Error Message ต้องบอกวิธีแก้โดยไม่เปิดเผยข้อมูลภายใน
- ตารางขนาดใหญ่ต้องมี Sticky Header หรือวิธีคงบริบท
- รูปแบบวันที่และจำนวนต้องสม่ำเสมอทั้งระบบ
- รองรับหน้าจอ Desktop อย่างน้อย 1366×768 และ Tablet แนวนอน

---

## 13. Non-Functional Requirements

### NFR-01 Performance

- หน้า List และ Dashboard ควรตอบสนองภายใน 3 วินาทีที่ Percentile เป้าหมายภายใต้ปริมาณข้อมูล MVP
- Search/Filter ทั่วไปควรตอบสนองภายใน 2 วินาที
- ใช้ Server-side Pagination สำหรับรายการขนาดใหญ่
- งาน Report ขนาดใหญ่ต้องมี Timeout และแจ้งสถานะที่เข้าใจได้

### NFR-02 Availability และ Reliability

- เป้าหมาย Availability เบื้องต้น 99.5% ต่อเดือน ไม่รวม Planned Maintenance
- Transaction สำคัญต้องรักษาความสอดคล้องระหว่าง License และ Allocation
- ต้องมี Backup อัตโนมัติและทดสอบ Restore ตามรอบ
- กำหนด RPO/RTO ร่วมกับผู้ดูแล Infrastructure ก่อน Production

### NFR-03 Security

- ใช้ HTTPS ทุก Environment ที่มีข้อมูลจริง
- ใช้ RBAC ทั้ง Frontend และ Backend
- ป้องกัน OWASP Top 10 ที่เกี่ยวข้อง
- Validate และ Sanitize Input ฝั่ง Server
- ป้องกัน CSRF/XSS/SQL Injection ตามสถาปัตยกรรมที่เลือก
- Encrypt License Key/Serial ที่กำหนดว่า Sensitive
- Secret และ Encryption Key ต้องอยู่นอก Source Code
- กำหนด Rate Limit สำหรับ Login และ Endpoint สำคัญ
- ห้ามบันทึก Password, Token หรือ License Key ฉบับเต็มใน Log
- Export File ที่มีข้อมูลสำคัญต้องสร้างแบบชั่วคราวและหมดอายุ

### NFR-04 Privacy และ Data Retention

- เก็บเฉพาะข้อมูลบุคลากรที่จำเป็นต่อการบริหาร Asset
- กำหนดผู้มีสิทธิ์ดูข้อมูลผู้ใช้งานภายในตามนโยบายองค์กร
- Audit Log และข้อมูล Archived ต้องมี Retention Period ที่อนุมัติ
- รองรับการปกปิดข้อมูลในการใช้งาน Environment ทดสอบ

### NFR-05 Maintainability

- แยก Module Asset, Product, License, Allocation, Report และ Identity อย่างชัดเจน
- ใช้ API Contract และ Validation Schema ที่มี Version/Documentation
- Business Rule การคำนวณ License ต้องมี Automated Test
- Database Migration ต้องมี Version Control และ Rollback Strategy
- เก็บ Configuration แยกตาม Environment

### NFR-06 Observability

- มี Application Log แบบ Structured
- มี Error Tracking และ Health Check
- มี Metric อย่างน้อยสำหรับ Response Time, Error Rate, Login Failure และ Background Job
- Log ต้องมี Correlation ID เพื่อสืบค้น Request

### NFR-07 Compatibility

- รองรับ Chrome และ Microsoft Edge เวอร์ชันที่องค์กรใช้งานและยังได้รับการสนับสนุน
- UI ต้องไม่พึ่ง Excel หรือ Desktop Application ในการทำงานหลัก

---

## 14. Error Handling

- Validation Error แสดงที่ฟิลด์พร้อมข้อความที่แก้ไขได้
- Duplicate Error ระบุ Business Identifier ที่ชน โดยไม่เปิดเผยข้อมูลเกินสิทธิ์
- Permission Error แสดง Access Denied และไม่ส่งข้อมูล Entity กลับมา
- Concurrent Update ต้องตรวจ Updated Version/Timestamp และเตือนผู้ใช้ก่อนเขียนทับ
- Export หรือ Report Failure ต้องให้ลองใหม่ได้และมี Error Reference
- Background Job Failure ต้องแจ้ง Admin และรองรับ Retry โดยไม่สร้าง Notification ซ้ำ
- ระบบต้องไม่แสดง Stack Trace, SQL หรือ Secret ต่อผู้ใช้

---

## 15. Acceptance Criteria ระดับระบบ

### Authentication/RBAC

- Admin Login แล้วเห็นและเปิดได้ทุกเมนู
- User Login แล้วเห็นเฉพาะเมนูแบบอ่านและรายงาน
- User เรียก Create/Update/Delete API แล้วได้รับการปฏิเสธ
- User ไม่สามารถดู License Key ฉบับเต็มจาก UI, Export, API หรือ Page Source

### Asset

- Admin สร้าง Asset พร้อม Asset Code, Site และ Asset Type ได้
- ระบบป้องกัน Asset Code ซ้ำ
- ค้นหา Asset ด้วย Computer Name, MAC หรือ IP ได้
- Asset Detail แสดงข้อมูล Network และ Allocation ที่สัมพันธ์กัน
- Archive Asset แล้วข้อมูลยังอยู่ใน History/Report ตาม Filter

### License

- Admin สร้าง License ที่อ้างอิง Software Product และ Owned Quantity ได้
- Allocated และ Available Quantity คำนวณอัตโนมัติ
- ระบบแสดง Over-allocated, Expired และ Expiring Soon ถูกต้อง
- การแก้วันสิ้นสุดหรือจำนวนสิทธิ์ทำให้ Dashboard/Report เปลี่ยนตามกฎเดียวกัน

### Allocation

- Admin จัดสรร License ให้ Asset/User ได้
- ระบบป้องกันหรือเตือนการจัดสรรเกินสิทธิ์ตาม Setting
- ถอน Allocation แล้วจำนวน Available เพิ่มขึ้นและประวัติเดิมยังอยู่
- Retire Asset ที่มี Active Allocation แล้วระบบเตือน

### Reports

- ผู้ใช้กรองรายงานตาม Factory, Bangkok Office และ All Sites ได้
- ยอด Owned, Allocated และ Available ตรงกับรายการรายละเอียด
- Export แสดง Filter และวันที่ออกรายงาน
- Export ของ User ปกปิด License Key

### Audit

- Create/Update/Archive/Allocation/Role Change ปรากฏใน Audit Log
- Audit Log ไม่เก็บ Secret ฉบับเต็ม
- การเปิดดู License Key เต็มโดย Admin มี Event บันทึก

### Migration

- Migration Report แสดงผลของทุก Source Row
- Control Total และตัวอย่างข้อมูลผ่านการตรวจรับโดยผู้รับผิดชอบ
- ไม่เปิดเมนู Import Excel ให้ User หลัง Go-live

---

## 16. Testing Strategy และ UAT

### 16.1 Automated Testing

- Unit Test สำหรับ License Calculation, Status และ Permission Rule
- Integration Test สำหรับ Asset-License-Allocation Transaction
- API Authorization Test แยก Admin/User
- Migration Test ด้วยชุดข้อมูลตัวอย่างและ Edge Case
- Security Test สำหรับข้อมูล Sensitive และ Export
- End-to-End Test สำหรับ Critical User Journey

### 16.2 UAT Scenarios

1. Admin เพิ่ม Asset ใหม่และค้นหาเจอ
2. Admin เพิ่ม Product และ License ใหม่
3. Admin จัดสรร License ให้ Asset และตรวจยอดคงเหลือ
4. Admin ถอน Allocation และตรวจ History
5. User ดู Dashboard และ Export Report
6. User พยายามแก้ข้อมูลและถูกปฏิเสธ
7. User เห็น License Key แบบปกปิด
8. Admin ตรวจ License ใกล้หมดอายุ
9. Admin ตรวจรายการใช้เกินสิทธิ์
10. ผู้รับผิดชอบเทียบข้อมูลที่ย้ายกับ Excel ทั้ง Factory และ Office

### 16.3 Exit Criteria ก่อน Go-live

- Critical/High Defect ที่กระทบข้อมูล สิทธิ์ หรือความปลอดภัยต้องถูกแก้ทั้งหมด
- UAT Scenario หลักผ่านและมีผู้อนุมัติ
- Migration Reconciliation ผ่าน
- Backup/Restore และ Rollback Plan ผ่านการทดสอบ
- Admin ได้รับคู่มือและการอบรม
- Production Access และ Secret ได้รับการตรวจสอบ

---

## 17. Release Plan ระดับสูง

### Phase 0: Data Discovery และ Definition

- ยืนยัน Data Dictionary
- ยืนยัน Mapping และ Status Rules
- ระบุ Data Owner ของ Factory และ Bangkok Office
- ทำความสะอาดรายการที่กำกวม

### Phase 1: MVP Build

- Authentication/RBAC
- Master Data
- Asset, Product, License และ Allocation
- Dashboard, Report และ Audit
- In-app Notification

### Phase 2: Migration และ UAT

- Dry Run
- Reconciliation
- UAT
- แก้ Data Quality Issue

### Phase 3: Go-live

- Freeze Excel
- Final Migration
- Production Validation
- ส่งมอบและติดตามผล

### Phase 4: Enhancement

- Integration, Discovery Agent, Procurement, Email Notification และ QR/Barcode ตามลำดับความสำคัญ

---

## 18. Dependencies

- ผู้รับผิดชอบข้อมูลของ Factory และ Bangkok Office
- ผู้ตัดสินใจนิยาม Owned/Used License และสถานะ License
- Infrastructure สำหรับ Web, Database, Backup และ Monitoring
- นโยบาย Authentication และ Password ขององค์กร
- นโยบายการเก็บ License Key, ข้อมูลผู้ใช้งาน และ Audit Log
- การยืนยัน Browser/Network ที่ใช้ภายในองค์กร
- ผู้อนุมัติผล Migration และ UAT

---

## 19. Risks และแนวทางลดความเสี่ยง

| ความเสี่ยง | ผลกระทบ | แนวทางลดความเสี่ยง |
|---|---|---|
| ข้อมูล Excel ไม่สม่ำเสมอ | Migration ผิดหรือสร้างข้อมูลซ้ำ | Staging, Mapping Rule, Data Quality Report, Manual Review |
| Own/Use ใน Summary มีโครงสร้างหลายระดับ | ยอดไม่ตรง | กำหนดนิยามและ Reconcile ราย Product/Site |
| Key เดียวใช้หลายเครื่องโดยถูกต้อง | Deduplicate ผิด | ตรวจ License Type/Volume License ก่อน Merge |
| User เข้าถึง License Key | ความเสี่ยงด้าน Security/Compliance | Encryption, Masking, RBAC, Audit |
| Status เดิมขัดกับวันที่หมดอายุ | รายงานคลาดเคลื่อน | แยก Business Status และ Calculated Lifecycle Status |
| การแก้ข้อมูลพร้อมกัน | ข้อมูลถูกเขียนทับ | Optimistic Concurrency และ Conflict Warning |
| ผู้ใช้กลับไปใช้ Excel หลัง Go-live | ข้อมูลมีหลายแหล่ง | Freeze Excel, กำหนด System of Record และอบรม |
| Scope ขยายไป Workflow จัดซื้อเร็วเกินไป | MVP ล่าช้า | ยึด Out-of-scope และจัด Enhancement Backlog |

---

## 20. Assumptions

- ระบบเป็น Internal Web Application ขององค์กร
- MVP มีสอง Role คือ Admin และ User เท่านั้น
- Admin เข้าถึงทุก Site และทุกเมนู
- User ดูข้อมูลของทุก Site ได้แบบ Read-only ตาม Requirement ปัจจุบัน
- User สามารถ Export Report ได้ แต่ข้อมูล Sensitive ถูกปกปิด
- Excel ทั้งสองไฟล์ใช้ Migration ครั้งเดียว ไม่ใช่ Source of Truth หลัง Go-live
- Factory และ Bangkok Office เป็น Site เริ่มต้น และ Admin เพิ่ม Site ภายหลังได้
- ภาษา UI หลักเป็นภาษาไทย แต่ข้อมูลต้นทางภาษาอังกฤษ/ญี่ปุ่นเก็บและแสดงได้
- Timezone หลักคือ Asia/Bangkok
- License Allocation เป็นแหล่งจริงสำหรับจำนวนการใช้งานหลัง Go-live
- การลบข้อมูลธุรกิจใช้ Archive/Soft Delete เป็นค่าเริ่มต้น
- MVP ใช้ In-app Notification; ช่องทางภายนอกเป็นระยะถัดไป

---

## 21. ประเด็นที่ต้องยืนยันก่อนเริ่มออกแบบเชิงเทคนิค

ประเด็นต่อไปนี้ไม่ขัดขวางการใช้ PRD เป็นฐานวางแผน แต่ต้องได้รับคำตอบก่อน Implementation:

1. วิธี Authentication: บัญชีภายในระบบ หรือเชื่อม Active Directory/Entra ID
2. User เห็นข้อมูลทุก Site หรือจำกัดตาม Site/Department
3. รูปแบบ Export ที่ต้องมีแน่นอน: Excel, CSV, PDF หรือทั้งหมด
4. นิยาม License แบบ Device, User, Concurrent, Site และ Subscription ที่องค์กรใช้งานจริง
5. อนุญาต Over-allocation พร้อมเหตุผล หรือ Block ทุกกรณี
6. ต้องเก็บเอกสาร Invoice/PO/Contract เป็นไฟล์ใน MVP หรือเก็บเฉพาะเลขอ้างอิง
7. ระยะเวลา Session, Password Policy และ Audit Retention
8. รายชื่อผู้รับผิดชอบอนุมัติ Mapping และยอด Migration ของแต่ละ Site
9. เกณฑ์ข้อมูลขั้นต่ำที่ยอมรับได้สำหรับ Asset/License ที่ข้อมูลต้นทางไม่ครบ
10. ปริมาณผู้ใช้พร้อมกันและข้อกำหนด Infrastructure/Deployment

---

## 22. Definition of Done สำหรับ MVP

MVP ถือว่าเสร็จเมื่อ:

- Functional Requirement ที่จัดเป็น MVP ผ่าน Acceptance Criteria
- Admin และ User มีสิทธิ์ตรงตาม Permission Matrix
- Asset, Product, License และ Allocation ใช้ฐานข้อมูลกลางและสัมพันธ์กันถูกต้อง
- Dashboard/Report คำนวณจากข้อมูลจริงและกฎเดียวกัน
- Initial Migration จาก Excel ผ่าน Reconciliation และการอนุมัติ
- ข้อมูล License Key/Serial ได้รับการปกป้องครบทุกช่องทาง
- Audit Log ครอบคลุมการกระทำสำคัญ
- Automated Test, Security Test และ UAT ผ่านเกณฑ์
- มี Backup, Restore, Monitoring และคู่มือ Admin
- Excel เดิมถูกกำหนดเป็น Archive และระบบเว็บเป็น System of Record

---

## 23. ภาคผนวก: คำศัพท์

| คำศัพท์ | ความหมาย |
|---|---|
| Asset | อุปกรณ์ที่องค์กรบริหาร เช่น PC, Notebook, Server |
| Software Product | ชื่อผลิตภัณฑ์ซอฟต์แวร์และเวอร์ชัน โดยยังไม่แทนสิทธิ์ที่ซื้อ |
| License Entitlement | สิทธิ์ใช้งานซอฟต์แวร์ที่องค์กรครอบครอง |
| Allocation | การจัดสรรสิทธิ์ให้ Asset, User หรือ Site |
| Owned Quantity | จำนวนสิทธิ์ที่องค์กรซื้อหรือมีสิทธิ์ใช้งาน |
| Allocated Quantity | จำนวนสิทธิ์ที่ถูกจัดสรรอยู่ |
| Available Quantity | Owned ลบ Allocated |
| Over-allocation | จำนวนที่จัดสรรมากกว่าจำนวนที่ครอบครอง |
| Perpetual License | License ที่ไม่มีวันหมดอายุ แต่ยังอาจมีข้อจำกัดเวอร์ชัน/การสนับสนุน |
| Subscription License | License ที่มีช่วงเวลาเริ่มต้นและสิ้นสุด |
| System of Record | แหล่งข้อมูลหลักที่องค์กรถือว่าเป็นข้อมูลจริง |
| Reconciliation | การตรวจยอดระหว่างข้อมูลต้นทางและข้อมูลหลัง Migration |
| Archive/Soft Delete | ปิดการใช้งานข้อมูลโดยไม่ลบประวัติออกจากฐานข้อมูล |
