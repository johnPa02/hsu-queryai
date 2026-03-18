# Tài liệu giải thích Database Schema - HSU CRM

## Tổng quan

Tài liệu này mô tả chi tiết cấu trúc database của hệ thống HSU CRM, bao gồm các bảng chính, các trường dữ liệu, ý nghĩa và mối quan hệ giữa chúng.

---

## Sơ đồ quan hệ tổng thể

```
users (Người dùng CRM)
  │
  ├──> leads (Học sinh tiềm năng)
  │      │
  │      ├──> lead_stage_history (Lịch sử thay đổi giai đoạn)
  │      │
  │      ├──> zalo_conversations (Cuộc trò chuyện Zalo)
  │      │      └──> zalo_ai_analysis (Phân tích AI cuộc trò chuyện)
  │      │             └──> zalo_ai_analysis_recap (Tổng hợp phân tích chủ đề)
  │      │
  │      ├──> tasks (Nhiệm vụ)
  │      │
  │      ├──> activities (Nhật ký hoạt động)
  │      │
  │      └──> voip_call_records (Lịch sử cuộc gọi VoIP)
  │
  ├──> schools (Trường THPT)
  │      ├──> school_kpi_target (Chỉ tiêu KPI trường)
  │      └──> user_school_assignment (Phân công CVTS cho trường)
  │
  ├──> channels (Kênh kết nối)
  │
  └──> zalo_group_conversations (Nhóm chat Zalo)
```

---

## 1. users - Bảng người dùng hệ thống

### Mục đích
Lưu trữ tất cả người dùng của hệ thống CRM với phân quyền theo vai trò và phân vùng địa lý.

### Các trường chính

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất của người dùng |
| `email` | text | Email đăng nhập (unique) |
| `password` | text | Mật khẩu đã mã hóa (bcrypt) |
| `fullName` | text | Họ và tên đầy đủ |
| `role` | text | Vai trò: 'superadmin', 'manager_l1', 'manager_l2', 'marketing_manager', 'deputy_manager', 'cvts', 'ctv' |
| `region` | text | Khu vực: 'TP.HCM', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ' |
| `area` | text | Vùng: 'DNB & HCM', 'TNB & HCM' |
| `responsibleRegions` | text[] | Danh sách các tỉnh/thành phố phụ trách |
| `managerId` | varchar | ID của quản lý trực tiếp (CTV→CVTS, CVTS→Deputy Manager) |
| `phone` | text | Số điện thoại |
| `avatar` | text | URL ảnh đại diện |
| `channelConnectedId` | text | ID kết nối với kênh bên ngoài (Zalo userId) |
| `status` | text | Trạng thái: 'active', 'inactive', 'deleted' |
| `leadTarget` | integer | Chỉ tiêu số lead hàng tháng (cho CVTS) |
| `conversionRateTarget` | integer | Chỉ tiêu tỷ lệ chuyển đổi (%) |
| `enrollmentTarget` | integer | Chỉ tiêu số sinh viên nhập học |
| `emailNotifications` | boolean | Nhận thông báo qua email |
| `pushNotifications` | boolean | Nhận thông báo trình duyệt |
| `taskReminders` | boolean | Nhận nhắc nhở nhiệm vụ |
| `lastInteraction` | timestamp | Thời gian tương tác cuối cùng |
| `createdAt` | timestamp | Ngày tạo tài khoản |
| `updatedAt` | timestamp | Ngày cập nhật cuối |

### Vai trò hệ thống

1. **superadmin** (Hiệu trưởng): Toàn quyền truy cập tất cả dữ liệu và khu vực
2. **manager_l1** (Phó Hiệu Trưởng): Quản lý theo vùng (DNB & HCM hoặc TNB & HCM)
3. **manager_l2** (Trưởng Phòng): Quản lý theo vùng
4. **marketing_manager** (Quản lý Marketing): Quản lý chiến dịch marketing và insights
5. **deputy_manager** (Phó Quản Lý): Quản lý nhóm CVTS và CTV
6. **cvts** (Cán Bộ Tuyển Sinh): Xử lý và chăm sóc lead
7. **ctv** (Cộng Tác Viên): Hỗ trợ tuyển sinh cơ bản

### Mối quan hệ
- **Self-referencing**: `managerId` → `users.id` (quản lý trực tiếp)
- **One-to-many**: 1 user → nhiều leads (thông qua `leads.assignedTo`)
- **One-to-many**: 1 user → nhiều tasks (thông qua `tasks.assignedTo`)
- **One-to-many**: 1 user → nhiều zalo_conversations
- **One-to-many**: 1 user → nhiều user_school_assignments
- **One-to-many**: 1 user → nhiều channels

---

## 2. leads - Bảng học sinh tiềm năng

### Mục đích
Lưu trữ thông tin chi tiết về học sinh tiềm năng với 58+ trường dữ liệu toàn diện.

### Các nhóm trường

#### A. Thông tin cá nhân (10 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `fullName` | text | Họ và tên học sinh (required) |
| `gender` | text | Giới tính: 'male', 'female', 'other' |
| `dateOfBirth` | timestamp | Ngày sinh |
| `avatar` | text | URL ảnh đại diện |
| `nationality` | text | Quốc tịch (mặc định 'Việt Nam') |
| `identificationNumber` | text | Số CMND/CCCD |
| `placeOfBirth` | text | Nơi sinh |
| `ethnicity` | text | Dân tộc |
| `religion` | text | Tôn giáo |
| `healthStatus` | text | Tình trạng sức khỏe |

#### B. Thông tin liên hệ (6 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `phone` | text | Số điện thoại (required) |
| `email` | text | Email |
| `address` | text | Địa chỉ |
| `socialZalo` | text | Zalo ID/username |
| `socialFacebook` | text | Facebook profile URL |
| `socialTikTok` | text | TikTok username |

#### C. Thông tin địa lý (4 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `provinceCode` | text | Mã tỉnh/thành phố (theo danh mục hành chính) |
| `region` | text | Vùng miền |
| `area` | text | Khu vực: 'DNB & HCM', 'TNB & HCM' |
| `city`, `district`, `ward` | text | Deprecated - dùng provinceCode thay thế |

#### D. Thông tin trường học (11 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `schoolId` | varchar | FK đến bảng schools - để tracking KPI |
| `gradeLevel` | text | Lớp: '10', '11', '12', 'graduated' |
| `gpa` | text | Điểm GPA (e.g., "8.5") |
| `conduct` | text | Hạnh kiểm: 'Tốt', 'Khá', 'Trung bình', 'Yếu' |
| `graduationYear` | integer | Năm tốt nghiệp |
| `highSchoolCode` | text | Mã trường THPT |
| `previousEducation` | text | Lịch sử học vấn |
| `academicAchievements` | text[] | Giải thưởng, chứng chỉ |
| `extracurricularActivities` | text[] | Hoạt động ngoại khóa |
| `languageProficiency` | jsonb | Trình độ ngoại ngữ: `{english: 'intermediate', vietnamese: 'native'}` |
| `computerSkills` | text | Kỹ năng tin học: 'basic', 'intermediate', 'advanced' |
| `specialNeeds` | text | Nhu cầu đặc biệt |

#### E. Thông tin phụ huynh (7 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `parentName` | text | Họ tên phụ huynh |
| `parentPhone` | text | Số điện thoại phụ huynh |
| `parentOccupation` | text | Nghề nghiệp phụ huynh |
| `parentSupport` | text | Mức độ hỗ trợ: 'high', 'medium', 'low' |
| `parentEducationLevel` | text | Trình độ học vấn: 'high_school', 'bachelor', 'master', 'phd' |
| `numberOfSiblings` | integer | Số anh chị em |
| `familyIncome` | text | Thu nhập gia đình: 'low', 'medium', 'high' |

#### F. Trường CRM (4 trường chính)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `source` | text | Nguồn: 'zalo', 'facebook', 'form', 'direct', 'event', 'referral', 'HSU' (required) |
| `stage` | text | Giai đoạn xử lý (xem bảng stages bên dưới) |
| `smartScore` | text | Phân loại tiềm năng: 'A', 'B', 'C+', 'C', 'D', 'QL' |
| `careStatus` | text | Trạng thái chăm sóc (1-23, mapping theo LEAD_STATUS constants) |
| `admissionPreference` | text | Nguyện vọng cổng Bộ GD&ĐT |
| `assignedTo` | varchar | FK đến users.id - CVTS phụ trách |
| `partnerLeadId` | text | ID từ API đối tác (unique, để dedupe) |

#### G. Trạng thái ứng tuyển (9 boolean flags)
| Trường | Giá trị | Ý nghĩa |
|--------|---------|---------|
| `isScholarshipApplied` | boolean | Đã nộp hồ sơ xét học bổng |
| `isScholarshipDeposited` | boolean | Đã cọc tiền học bổng |
| `isAccountCreated` | boolean | Đã tạo tài khoản xét tuyển |
| `isOnlineApplied` | boolean | Đã đăng ký xét tuyển online |
| `isHardcopySubmitted` | boolean | Đã nộp hồ sơ giấy |
| `isAdmitted` | boolean | Đã trúng tuyển |
| `isEnrolled` | boolean | Đã làm thủ tục nhập học |
| `isTuitionPaid` | boolean | Đã đóng học phí |
| `isEnrollmentCancelled` | boolean | Đã hủy nhập học |

#### H. Chương trình & Ngành học (8 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `interestedProgram` | text | Chương trình đào tạo quan tâm |
| `interestedMajors` | text | Ngành học quan tâm |
| `scholarshipMajors` | text | Ngành đăng ký học bổng |
| `admissionMajors` | text | Ngành nhập học |
| `careerGoals` | text | Mục tiêu nghề nghiệp |
| `scholarshipInterest` | boolean | Quan tâm học bổng |
| `financialSituation` | text | Tình hình tài chính: 'good', 'average', 'difficult' |
| `livingSituation` | text | Nơi ở: 'with_parents', 'alone', 'dormitory' |
| `preferredContactMethod` | text | Kênh liên hệ ưa thích: 'phone', 'email', 'zalo', 'facebook' |
| `tags` | text[] | Thẻ tùy chỉnh: ['cntt', 'hoc_bong', 'diem_cao'] |

#### I. Theo dõi hoạt động (6 trường)
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `lastInteraction` | timestamp | Thời gian tương tác cuối |
| `lastInteractionType` | text | Loại tương tác: 'call', 'message', 'email', 'meeting' |
| `interactionCount` | integer | Số lần tương tác |
| `preferredContactTime` | text | Khung giờ liên hệ tốt nhất: 'morning', 'afternoon', 'evening' |
| `nextFollowUpDate` | timestamp | Ngày hẹn follow-up tiếp theo |
| `notes` | text | Ghi chú |
| `comment` | text | Bình luận bổ sung |

#### J. Metadata
| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `status` | text | Trạng thái: 'active', 'inactive', 'deleted' |
| `chunkIds` | jsonb | Array chunk IDs trong vector store (để xóa đúng chunks) |
| `createdAt` | timestamp | Ngày tạo lead |
| `updatedAt` | timestamp | Ngày cập nhật cuối |

### Các giai đoạn (stages) của lead

| Stage | Tên | Mô tả |
|-------|-----|-------|
| `raw_lead` | Lead thô | Lead mới, chưa được xử lý |
| `interested_in_major` | Quan tâm ngành học | Học sinh đã tìm hiểu về ngành |
| `scholarship_applied` | Đã nộp hồ sơ học bổng | Đã apply học bổng |
| `scholarship_deposited` | Đã cọc học bổng | Đã đặt cọc tiền |
| `account_created` | Đã tạo tài khoản | Tạo tài khoản xét tuyển |
| `online_admission` | Đã đăng ký online | Đã submit đơn xét tuyển |
| `hardcopy_submitted` | Đã nộp hồ sơ giấy | Nộp hồ sơ bản cứng |
| `admitted` | Trúng tuyển | Được nhận vào trường |
| `enrolled` | Đã nhập học | Hoàn tất thủ tục nhập học |
| `tuition_paid` | Đã đóng học phí | Đã thanh toán học phí |
| `enrollment_cancelled` | Hủy nhập học | Hủy quyết định nhập học |
| `not_interested` | Không quan tâm | Lead không có nhu cầu |

### Mối quan hệ
- **Many-to-one**: nhiều leads → 1 user (assignedTo)
- **Many-to-one**: nhiều leads → 1 school (schoolId)
- **One-to-many**: 1 lead → nhiều zalo_conversations
- **One-to-many**: 1 lead → nhiều tasks
- **One-to-many**: 1 lead → nhiều activities
- **One-to-many**: 1 lead → nhiều lead_stage_history
- **One-to-many**: 1 lead → nhiều voip_call_records (thông qua phone matching)

---

## 3. lead_stage_history - Lịch sử thay đổi giai đoạn

### Mục đích
Theo dõi tất cả các thay đổi giai đoạn của lead để phân tích conversion funnel và hiệu suất xử lý.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `leadId` | varchar | FK đến leads.id |
| `fromStage` | text | Giai đoạn trước đó (null nếu là lần đầu) |
| `toStage` | text | Giai đoạn mới (required) |
| `changedBy` | varchar | FK đến users.id - người thay đổi |
| `changedAt` | timestamp | Thời gian thay đổi |

### Ứng dụng
- **Conversion Funnel Analysis**: Phân tích tỷ lệ chuyển đổi giữa các giai đoạn
- **Time in Stage**: Tính thời gian lead ở mỗi giai đoạn
- **Bottleneck Detection**: Xác định giai đoạn bị tắc nghẽn
- **Staff Performance**: Đánh giá hiệu suất CVTS trong việc đẩy lead qua các stage

### Mối quan hệ
- **Many-to-one**: nhiều stage_history → 1 lead
- **Many-to-one**: nhiều stage_history → 1 user (changedBy)

---

## 4. schools - Bảng thông tin trường THPT

### Mục đích
Lưu trữ master data về các trường THPT để tracking KPI theo trường và phân tích hiệu suất tuyển sinh.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `name` | text | Tên trường đầy đủ (required) |
| `shortName` | text | Tên viết tắt |
| `code` | text | Mã trường |
| `tier` | text | Hạng trường: '1', '2', '3', '2NT' (required) |
| `provinceCode` | text | Mã tỉnh/thành phố |
| `region` | text | Vùng miền |
| `province` | text | Tên tỉnh/thành phố |
| `district` | text | Quận/huyện |
| `year` | integer | Năm (để tracking theo năm học) |
| `address` | text | Địa chỉ chi tiết |
| `responsibleUserId` | varchar | FK đến users.id - CVTS phụ trách (deprecated, dùng user_school_assignments) |
| `status` | text | Trạng thái: 'active', 'inactive' |
| `metadata` | jsonb | Thông tin bổ sung |
| `createdAt` | timestamp | Ngày tạo |
| `updatedAt` | timestamp | Ngày cập nhật |

### Phân hạng trường (tier)

| Tier | Mô tả |
|------|-------|
| `1` | Tier 1 - Trường chất lượng cao, điểm chuẩn cao |
| `2` | Tier 2 - Trường khá |
| `3` | Tier 3 - Trường trung bình |
| `2NT` | Tier 2 Nông Thôn - Trường khá ở khu vực nông thôn |

### Deprecated fields
- `area`, `ward`, `totalStudents`, `lastYearEnrolled`: Không sử dụng nữa

### Mối quan hệ
- **One-to-many**: 1 school → nhiều leads (schoolId)
- **One-to-one**: 1 school → 1 school_kpi_target
- **One-to-one**: 1 school → 1 user_school_assignment (mỗi trường chỉ được assign cho 1 CVTS)

---

## 5. school_kpi_target - Chỉ tiêu KPI theo trường

### Mục đích
Lưu trữ các chỉ tiêu KPI dự kiến cho từng trường THPT theo kỳ (tháng/quý/năm).

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `schoolId` | varchar | FK đến schools.id (unique - mỗi trường 1 target) |
| `period` | text | Kỳ: 'Q1-2025', 'Q2-2025', '2025' (required) |
| `periodType` | text | Loại kỳ: 'month', 'quarter', 'year' (required) |
| `expectedAdmissions` | integer | KPI Lead - chỉ tiêu số lead (required) |
| `expectedLeads` | integer | SYNCED với expectedAdmissions - dùng để backward compatibility |
| `kpiScholarship` | integer | KPI Xét học bổng |
| `kpiMilestone1` | integer | KPI 1500 (HCM) / KPI 1000 (TNB) |
| `kpiMilestone2` | integer | KPI 2400 (HCM) / KPI 2600 (TNB) |
| `kpiSource` | text | Nguồn: 'manual', 'ai_suggested', 'excel_import' |
| `aiConfidence` | integer | Độ tin cậy AI (0-100) nếu được AI đề xuất |
| `setBy` | varchar | FK đến users.id - người thiết lập |
| `notes` | text | Ghi chú |
| `createdAt` | timestamp | Ngày tạo |
| `updatedAt` | timestamp | Ngày cập nhật |

### Lưu ý quan trọng
> **expectedAdmissions** và **expectedLeads** luôn được đồng bộ cùng giá trị. Cả 2 đều lưu chỉ tiêu KPI Lead để đảm bảo backward compatibility với code cũ.

### Phân loại KPI

| KPI | Mô tả |
|-----|-------|
| **KPI Lead** | Số lượng lead cần tạo mới từ trường này |
| **KPI Xét học bổng** | Số học sinh nộp hồ sơ xét học bổng |
| **KPI 1500/1000** | Milestone 1 (HCM: 1500đ cọc, TNB: 1000đ cọc) |
| **KPI 2400/2600** | Milestone 2 (HCM: 2400đ, TNB: 2600đ) |

### Mối quan hệ
- **One-to-one**: 1 school_kpi_target → 1 school (unique constraint)
- **Many-to-one**: nhiều kpi_targets → 1 user (setBy)

---

## 6. user_school_assignments - Phân công CVTS cho trường

### Mục đích
Quản lý việc phân công CVTS/CTV chịu trách nhiệm cho các trường THPT. Mỗi trường chỉ được assign cho 1 người duy nhất.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `userId` | varchar | FK đến users.id (CVTS/CTV được phân công) |
| `schoolId` | varchar | FK đến schools.id (unique - 1 trường chỉ 1 assignment) |
| `assignedBy` | varchar | FK đến users.id - Manager thực hiện phân công |
| `role` | text | Vai trò: 'primary', 'secondary', 'backup' |
| `status` | text | Trạng thái: 'active', 'inactive' |
| `assignedAt` | timestamp | Ngày phân công |
| `createdAt` | timestamp | Ngày tạo |
| `updatedAt` | timestamp | Ngày cập nhật |

### Quy tắc phân công
- **One-to-one**: 1 trường chỉ được assign cho 1 CVTS/CTV tại một thời điểm
- **Unique constraint**: `schoolId` là unique trong bảng
- **One-to-many**: 1 CVTS/CTV có thể được assign nhiều trường

### Visibility Rules (Quyền xem trường)

| Role | Quyền xem |
|------|-----------|
| `superadmin` | Xem tất cả trường ở mọi khu vực |
| `manager_l1/l2` | Xem trường trong khu vực được assigned |
| `marketing_manager` | Xem trường trong khu vực được assigned |
| `deputy_manager` | CHỈ xem trường được assign cho CVTS mình quản lý |
| `cvts/ctv` | CHỈ xem trường được assign cho mình |

### Mối quan hệ
- **Many-to-one**: nhiều assignments → 1 user (userId)
- **One-to-one**: 1 assignment → 1 school (unique)
- **Many-to-one**: nhiều assignments → 1 user (assignedBy)

---

## 7. tasks - Bảng nhiệm vụ

### Mục đích
Quản lý các nhiệm vụ được giao cho CVTS/CTV, có thể liên quan đến lead cụ thể, trường học, vùng địa lý hoặc giai đoạn lead.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `leadId` | varchar | FK đến leads.id (optional - nhiệm vụ cho lead cụ thể) |
| `schoolId` | varchar | FK đến schools.id (optional - nhiệm vụ cho trường) |
| `region` | text | Vùng địa lý (optional - nhiệm vụ theo tỉnh/thành) |
| `leadStage` | text | Giai đoạn lead (optional - nhiệm vụ cho leads ở stage này) |
| `assignedTo` | varchar | FK đến users.id - người được giao (required) |
| `title` | text | Tiêu đề nhiệm vụ (required) |
| `description` | text | Mô tả chi tiết |
| `type` | text | Loại: 'follow-up', 'callback', 'meeting', 'email' (required) |
| `priority` | text | Ưu tiên: 'high', 'medium', 'low' (required) |
| `dueDate` | timestamp | Hạn hoàn thành (required) |
| `completed` | boolean | Đã hoàn thành chưa |
| `completedAt` | timestamp | Thời gian hoàn thành |
| `createdAt` | timestamp | Ngày tạo |

### Loại nhiệm vụ (task types)

| Type | Mô tả |
|------|-------|
| `follow-up` | Theo dõi lead |
| `callback` | Gọi lại học sinh/phụ huynh |
| `meeting` | Hẹn gặp trực tiếp |
| `email` | Gửi email |

### Validation Rules
> Ít nhất 1 trong 4 trường `leadId`, `schoolId`, `region`, hoặc `leadStage` phải có giá trị.

### Mối quan hệ
- **Many-to-one**: nhiều tasks → 1 lead (optional)
- **Many-to-one**: nhiều tasks → 1 school (optional)
- **Many-to-one**: nhiều tasks → 1 user (assignedTo)

---

## 8. activities - Nhật ký hoạt động

### Mục đích
Lưu trữ nhật ký audit trail đầy đủ về tất cả các hoạt động trong hệ thống để theo dõi, phân tích và compliance.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `leadId` | varchar | ID của lead (không có FK constraint) |
| `userId` | varchar | FK đến users.id - người thực hiện |
| `action` | text | Hành động: 'created', 'updated', 'contacted', 'stage_changed' (required) |
| `entityType` | text | Loại đối tượng: 'lead', 'conversation', 'task' (required) |
| `entityId` | varchar | ID của đối tượng |
| `details` | jsonb | Chi tiết thay đổi (before/after values) |
| `createdAt` | timestamp | Thời gian hoạt động |

### Các loại hành động (actions)

| Action | Mô tả |
|--------|-------|
| `created` | Tạo mới entity |
| `updated` | Cập nhật thông tin |
| `contacted` | Liên hệ với lead |
| `stage_changed` | Thay đổi giai đoạn |

### Ứng dụng
- **Audit Trail**: Theo dõi lịch sử thay đổi
- **Activity Tracking**: Đếm số hoạt động của user trong 7 ngày gần đây
- **Change History**: Chi tiết thay đổi trước/sau trong JSONB
- **Performance Analytics**: Phân tích hiệu suất làm việc

### Mối quan hệ
- **Many-to-one**: nhiều activities → 1 user
- **No FK constraint to leads**: Cho phép tracking activities ngay cả khi lead bị xóa

---

## 9. channels - Kênh kết nối omnichannel

### Mục đích
Quản lý các kênh giao tiếp được tích hợp trong hệ thống (Zalo, Facebook, Email, Hotline, Webchat).

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `channel` | text | Loại kênh: 'zalo', 'facebook', 'email', 'hotline', 'webchat' (required) |
| `subType` | text | Loại con: 'personal', 'oa', 'page', 'smtp', 'voip', 'widget' (required) |
| `name` | text | Tên hiển thị của kênh (required) |
| `status` | text | Trạng thái: 'active', 'inactive', 'error' |
| `channelConnectedId` | text | Session ID/Connection ID từ platform bên ngoài |
| `lastSync` | timestamp | Lần đồng bộ cuối cùng |
| `messageCount` | integer | Tổng số tin nhắn đã xử lý |
| `metadata` | jsonb | Cấu hình và dữ liệu riêng của kênh |
| `userId` | varchar | FK đến users.id - chủ sở hữu kênh |
| `createdAt` | timestamp | Ngày tạo |
| `updatedAt` | timestamp | Ngày cập nhật |

### Phân loại kênh

| Channel | SubType | Mô tả |
|---------|---------|-------|
| `zalo` | `personal` | Tài khoản Zalo cá nhân |
| `zalo` | `oa` | Zalo Official Account |
| `facebook` | `personal` | Facebook cá nhân |
| `facebook` | `page` | Facebook Page |
| `email` | `smtp` | Email server |
| `hotline` | `voip` | Tổng đài VoIP |
| `webchat` | `widget` | Widget chat trên website |

### Mối quan hệ
- **Many-to-one**: nhiều channels → 1 user (userId)

---

## 10. zalo_conversations - Cuộc trò chuyện Zalo

### Mục đích
Lưu trữ các cuộc trò chuyện Zalo 1-1 giữa CVTS và lead, bao gồm toàn bộ lịch sử tin nhắn.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất trong CRM |
| `conversationId` | text | thread_id từ Zalo (unique) |
| `userId` | varchar | FK đến users.id - CVTS sở hữu cuộc trò chuyện (required) |
| `leadId` | varchar | FK đến leads.id - Lead liên quan (nullable, sẽ fill sau) |
| `leadZaloId` | text | Zalo ID của lead |
| `leadPhone` | text | Số điện thoại lead (nếu có) |
| `conversationTitle` | text | Tiêu đề cuộc trò chuyện |
| `conversationThumbnail` | text | URL ảnh đại diện |
| `lastMessage` | text | Preview tin nhắn cuối |
| `lastMessageAt` | timestamp | Thời gian tin nhắn cuối |
| `messages` | jsonb | Array tất cả tin nhắn trong cuộc trò chuyện |
| `createdAt` | timestamp | Ngày tạo |
| `updatedAt` | timestamp | Ngày cập nhật |

### Cấu trúc JSONB messages array

```json
[
  {
    "content": "Nội dung tin nhắn",
    "senderName": "Tên người gửi",
    "senderAvatar": "URL avatar",
    "sender": "lead" hoặc "cvts",
    "timestamp": "ISO 8601 string (Vietnam time GMT+7)"
  }
]
```

### Workflow
1. Sync tin nhắn từ Zalo về hệ thống
2. Tạo/cập nhật record trong `zalo_conversations`
3. Lưu tất cả messages vào JSONB array
4. (Optional) Mapping với lead trong CRM qua phone/Zalo ID
5. Trigger AI analysis tự động

### Mối quan hệ
- **Many-to-one**: nhiều zalo_conversations → 1 user (userId)
- **Many-to-one**: nhiều zalo_conversations → 1 lead (leadId, nullable)
- **One-to-one**: 1 zalo_conversation → 1 zalo_ai_analysis

---

## 11. zalo_group_conversations - Nhóm chat Zalo

### Mục đích
Lưu trữ các cuộc trò chuyện nhóm Zalo (group chat). Hoàn toàn độc lập với hệ thống lead/conversation chính.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `groupId` | text | Zalo group ID (unique) |
| `sessionId` | text | Zalo session ID (tài khoản nào) (required) |
| `userId` | varchar | FK đến users.id - CRM user sở hữu nhóm (required) |
| `groupName` | text | Tên nhóm (required) |
| `groupAvatar` | text | URL ảnh đại diện nhóm |
| `memberCount` | integer | Số lượng thành viên |
| `members` | jsonb | Array danh sách thành viên |
| `messages` | jsonb | Array tất cả tin nhắn trong nhóm |
| `messageCount` | integer | Tổng số tin nhắn |
| `lastMessage` | text | Nội dung tin nhắn cuối |
| `lastMessageAt` | timestamp | Thời gian tin nhắn cuối |
| `status` | text | Trạng thái: 'active', 'archived', 'deleted' |
| `createdAt` | timestamp | Ngày tạo |
| `updatedAt` | timestamp | Ngày cập nhật |

### Cấu trúc JSONB members array

```json
[
  {
    "zalo_id": "123456789000"
  }
]
```

### Cấu trúc JSONB messages array

```json
[
  {
    "sender": "cvts" hoặc "lead",
    "messageFrom": {
      "zalo_id": "123456789000",
      "name": "Tên người gửi",
      "avatar": "URL avatar"
    },
    "content": "Nội dung tin nhắn",
    "timestamp": "ISO 8601 string (Vietnam time GMT+7)"
  }
]
```

### Đặc điểm
- **Không liên kết với lead**: Nhóm chat không map với lead cụ thể
- **Lưu trữ hoàn chỉnh**: Tất cả thành viên và tin nhắn lưu trong JSONB
- **Độc lập**: Không ảnh hưởng đến hệ thống lead chính

### Mối quan hệ
- **Many-to-one**: nhiều group_conversations → 1 user (userId)

---

## 12. zalo_ai_analysis - Phân tích AI cuộc trò chuyện

### Mục đích
Lưu trữ kết quả phân tích AI của các cuộc trò chuyện Zalo 1-1, bao gồm sentiment, chủ đề, đánh giá chất lượng và gợi ý hành động.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `zaloConversationId` | varchar | FK đến zalo_conversations.id (unique - 1 conversation 1 analysis) |
| `sentiment` | text | Cảm xúc: 'positive', 'neutral', 'negative' |
| `summary` | text | Tóm tắt cuộc trò chuyện do AI tạo |
| `topics` | text[] | Array các chủ đề được trích xuất |
| `suggestedActions` | text[] | Array các hành động được đề xuất |
| `analysisData` | jsonb | Full response từ Lumi A.I API |
| `qualityScore` | integer | Điểm chất lượng 0-100 |
| `qualityGrade` | text | Xếp loại: 'A', 'B', 'C', 'D', 'F' |
| `qualityBreakdown` | jsonb | Chi tiết các metrics chất lượng |
| `qualityFlags` | text[] | Cờ cảnh báo: 'SPAM_DETECTED', 'LOW_ENGAGEMENT', etc. |
| `createdAt` | timestamp | Ngày phân tích |
| `updatedAt` | timestamp | Ngày cập nhật |

### Quality Metrics

| Metric | Mô tả |
|--------|-------|
| `qualityScore` | Điểm tổng thể 0-100 |
| `qualityGrade` | A: Xuất sắc, B: Tốt, C: Trung bình, D: Yếu, F: Kém |
| `qualityBreakdown` | Chi tiết: response time, engagement, professionalism |
| `qualityFlags` | Cảnh báo: spam, low engagement, inappropriate content |

### Ứng dụng
- **Sentiment Analysis**: Phân tích cảm xúc học sinh/phụ huynh
- **Topic Extraction**: Trích xuất chủ đề quan tâm
- **Quality Monitoring**: Giám sát chất lượng tư vấn của CVTS
- **Smart Actions**: Gợi ý hành động tiếp theo

### Mối quan hệ
- **One-to-one**: 1 zalo_ai_analysis → 1 zalo_conversation (unique)

---

## 13. zalo_ai_analysis_recap - Tổng hợp phân tích chủ đề

### Mục đích
Lưu trữ kết quả tổng hợp và nhóm các chủ đề từ nhiều cuộc trò chuyện Zalo, giúp phát hiện xu hướng và insights.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất |
| `totalRecords` | integer | Tổng số records `zalo_ai_analysis` được phân tích (required) |
| `totalTopics` | integer | Tổng số topics (có duplicate) (required) |
| `uniqueTopics` | integer | Số topics unique (required) |
| `analysis` | jsonb | Full JSON kết quả từ Lumi A.I (required) |
| `model` | text | Model AI được sử dụng (required) |
| `tokensUsed` | integer | Số tokens API đã tiêu thụ |
| `createdAt` | timestamp | Ngày tạo snapshot |

### Cấu trúc JSONB analysis

```json
{
  "summary": {
    "totalTopics": 150,
    "totalOccurrences": 450,
    "groupCount": 8
  },
  "groups": [
    {
      "name": "Học phí và Học bổng",
      "description": "Thắc mắc về chi phí và cơ hội học bổng",
      "topics": ["học phí", "học bổng", "chi phí", "miễn giảm"],
      "count": 45,
      "percentage": 30,
      "occurrences": 120
    }
  ]
}
```

### Ứng dụng
- **Trend Detection**: Phát hiện xu hướng chủ đề hot
- **Topic Clustering**: Nhóm các chủ đề liên quan
- **Marketing Insights**: Insights cho chiến dịch marketing
- **AI Model Tracking**: Theo dõi chi phí và hiệu quả AI

### Mối quan hệ
- **Aggregate**: Tổng hợp từ nhiều `zalo_ai_analysis` records

---

## 14. voip_call_records - Lịch sử cuộc gọi VoIP

### Mục đích
Lưu trữ lịch sử cuộc gọi từ hệ thống tổng đài VoIP, bao gồm thông tin cuộc gọi và link recording.

### Các trường

| Trường | Kiểu | Ý nghĩa |
|--------|------|---------|
| `id` | varchar | ID duy nhất trong CRM |
| `extension` | text | Số máy lẻ (extension) thực hiện/nhận cuộc gọi (required) |
| `dst` | text | Số điện thoại đích (đã gọi hoặc gọi đến) (required) |
| `duration` | integer | Thời lượng cuộc gọi (giây) (required) |
| `uniqueid` | text | Unique call ID từ VoIP system (unique) (required) |
| `recordUrl` | text | URL file ghi âm cuộc gọi |
| `createtime` | timestamp | Thời gian tạo cuộc gọi (required) |
| `analysis` | jsonb | Kết quả phân tích AI (sentiment, keywords, topics) |
| `direction` | text | Hướng: 'inbound', 'outbound', 'internal' |
| `callStatus` | text | Trạng thái: 'answered', 'missed', 'voicemail' |
| `importedAt` | timestamp | Thời gian import vào CRM |
| `createdAt` | timestamp | Ngày tạo record trong CRM |

### Call Direction

| Direction | Mô tả |
|-----------|-------|
| `inbound` | Cuộc gọi đến từ bên ngoài |
| `outbound` | Cuộc gọi đi ra ngoài |
| `internal` | Cuộc gọi nội bộ |

### Call Status

| Status | Mô tả |
|--------|-------|
| `answered` | Đã trả lời |
| `missed` | Nhỡ không nghe được |
| `voicemail` | Để lại tin nhắn thoại |

### Analysis Data (JSONB)

```json
{
  "sentiment": "positive",
  "keywords": ["học phí", "ngành CNTT", "lịch thi"],
  "topics": ["admission", "tuition"],
  "duration_category": "short",
  "quality_score": 85
}
```

### Ứng dụng
- **Call Tracking**: Theo dõi lịch sử cuộc gọi với lead
- **Performance Metrics**: Đánh giá hiệu suất gọi của CVTS
- **AI Analysis**: Phân tích nội dung qua transcription
- **Lead Matching**: Match cuộc gọi với lead qua số điện thoại

### Mối quan hệ
- **Soft relationship**: Match với leads qua `dst` = `leads.phone` (không có FK)
- **Soft relationship**: Match với users qua `extension` (không có FK)

---

## Tổng kết mối quan hệ chính

### Sơ đồ quan hệ tổng quát

```
┌─────────────────────────────────────────────────────────────────┐
│                           USERS                                  │
│  (Người dùng: superadmin, manager, cvts, ctv)                   │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ├─── assignedTo ──────────────────────────────────┐
       │                                                   │
       ├─── userId ───────────────────────────┐          │
       │                                       │          │
       ├─── assignedBy ──────────┐           │          │
       │                          │           │          │
       ▼                          ▼           ▼          ▼
┌─────────┐             ┌──────────────┐   ┌──────┐   ┌────────┐
│ SCHOOLS │             │   USER_      │   │ZALO_ │   │ LEADS  │
│         │◄────────────┤  SCHOOL_     │   │CONV  │   │        │
│         │  schoolId   │ ASSIGNMENTS  │   │      │   │        │
└────┬────┘             └──────────────┘   └──┬───┘   └───┬────┘
     │                                         │           │
     │ schoolId                    zaloConvId  │           │ leadId
     │                                         │           │
     ▼                                         ▼           ▼
┌────────────┐                    ┌──────────────┐   ┌─────────┐
│  SCHOOL_   │                    │   ZALO_AI_   │   │LEAD_    │
│ KPI_TARGET │                    │   ANALYSIS   │   │STAGE_   │
└────────────┘                    └──────────────┘   │HISTORY  │
                                           │          └─────────┘
                                           │
                                           ▼          ┌─────────┐
                                  ┌──────────────┐   │  TASKS  │
                                  │   ZALO_AI_   │   │         │
                                  │  ANALYSIS_   │   └─────────┘
                                  │   RECAP      │
                                  └──────────────┘   ┌───────────┐
                                                     │ACTIVITIES │
                                                     └───────────┘

                                                     ┌───────────┐
                                                     │  VOIP_    │
                                                     │  CALL_    │
                                                     │ RECORDS   │
                                                     └───────────┘

┌─────────┐
│CHANNELS │
└─────────┘

┌──────────────────┐
│  ZALO_GROUP_     │
│ CONVERSATIONS    │
└──────────────────┘
```

### Foreign Key Constraints Summary

| Parent Table | Child Table | Foreign Key | Relationship |
|--------------|-------------|-------------|--------------|
| users | users | managerId | 1:N (self-referencing) |
| users | leads | assignedTo | 1:N |
| users | zalo_conversations | userId | 1:N |
| users | zalo_group_conversations | userId | 1:N |
| users | tasks | assignedTo | 1:N |
| users | activities | userId | 1:N |
| users | channels | userId | 1:N |
| users | user_school_assignments | userId | 1:N |
| users | user_school_assignments | assignedBy | 1:N |
| schools | leads | schoolId | 1:N |
| schools | school_kpi_targets | schoolId | 1:1 (unique) |
| schools | user_school_assignments | schoolId | 1:1 (unique) |
| leads | lead_stage_history | leadId | 1:N |
| leads | zalo_conversations | leadId | 1:N (nullable) |
| zalo_conversations | zalo_ai_analysis | zaloConversationId | 1:1 (unique) |

### Soft Relationships (no FK)

| Table 1 | Table 2 | Relationship via | Type |
|---------|---------|------------------|------|
| leads | voip_call_records | phone = dst | N:N |
| users | voip_call_records | extension mapping | N:N |
| leads | activities | leadId (no FK) | 1:N |

---

## Best Practices sử dụng Schema

### 1. Area-Based Data Filtering
- **Superadmin**: Truy cập tất cả areas ('DNB & HCM', 'TNB & HCM')
- **Tất cả roles khác**: CHỈ truy cập data từ area được assign

### 2. Role-Based Visibility
- Luôn kiểm tra role và area trước khi query
- Áp dụng filters theo hierarchy (xem CLAUDE.md)

### 3. Lead Stage Management
- Sử dụng enum `STAGE_STATUS` thay vì hardcode strings
- Track mọi thay đổi stage trong `lead_stage_history`

### 4. School Assignment
- Mỗi trường chỉ được assign cho 1 CVTS (unique constraint)
- Dùng `user_school_assignments` thay vì `schools.responsibleUserId` (deprecated)

### 5. Zalo Integration
- Conversations 1-1: Dùng `zalo_conversations`
- Group chats: Dùng `zalo_group_conversations`
- Luôn lưu full message history trong JSONB

### 6. AI Analysis
- Tự động trigger analysis sau khi có conversation mới
- Cache kết quả trong `zalo_ai_analysis`
- Định kỳ tạo recap trong `zalo_ai_analysis_recap`

### 7. VoIP Integration
- Import call records thường xuyên
- Match với leads qua phone number
- Lưu URL recording để audit

### 8. Audit Trail
- Mọi thay đổi quan trọng đều log vào `activities`
- Lưu before/after values trong JSONB `details`

---

## Các lưu ý quan trọng

### ⚠️ Deprecated Fields
- `leads.city`, `leads.district`, `leads.ward` → Dùng `provinceCode`
- `schools.area`, `schools.ward`, `schools.totalStudents`, `schools.lastYearEnrolled`
- `schools.responsibleUserId` → Dùng `user_school_assignments`

### 🔒 Security & Privacy
- Passwords luôn được hash với bcrypt
- JWT tokens có expiration 7 ngày
- Area-based filtering prevents unauthorized data access

### 🚀 Performance Optimization
- Indexes trên các FK và query thường xuyên
- JSONB indexing cho fast lookup
- Cache analytics data trong `analytics_cache`

### 📊 Data Integrity
- Unique constraints: email, phone, conversationId, schoolId trong assignments
- Required fields validation với Zod schemas
- Soft deletes: dùng status thay vì xóa hard

---

## Contact & Support

Để biết thêm chi tiết về implementation và API endpoints, xem:
- [CLAUDE.md](../CLAUDE.md) - Project overview và development guide
- [SRS.md](../SRS.md) - System requirements specification
- [API Documentation](./api-group-topics.md) - API endpoints reference

---

**Version**: 1.0  
**Last Updated**: 2025-01-01  
**Maintained by**: HSU CRM Development Team
