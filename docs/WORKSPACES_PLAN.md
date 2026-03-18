Workspace A — Lead Status & Enrollment

Mục tiêu: trả lời câu hỏi về trạng thái tuyển sinh, stage, chuyển đổi, học bổng, nhập học, học phí, ngành quan tâm, dự báo cơ bản theo lead lifecycle.

Workspace B — Conversation Insights

Mục tiêu: trả lời câu hỏi về nội dung hội thoại Zalo, chủ đề quan tâm, recap, chất lượng chăm sóc qua chat, xu hướng trao đổi theo thời gian.

Workspace C — Hotline Insights

Mục tiêu: trả lời câu hỏi về cuộc gọi hotline, tần suất, thời lượng, chủ đề cuộc gọi, chất lượng tư vấn qua hotline.

Workspace D — Staff Productivity

Mục tiêu: trả lời câu hỏi về hoạt động CVTS, login, nhiệm vụ, productivity, mức độ vận hành và chăm sóc lead ở góc độ nhân sự.

Workspace E — Executive Admissions Summary

Mục tiêu: tổng hợp đa workspace để tạo báo cáo điều hành, ranking, anomaly, xu hướng tuyển sinh, hiệu suất tổng quan.

Tôi chốt luôn: với bộ FAQ này, **6 workspace trước đó là hợp lý**, nhưng cần gắn rõ từng câu hỏi vào từng workspace và chỉ ra **“coi ở đâu”**.

---

# 1) Mapping FAQ → workspace

## Workspace A — Lead Ops

Dùng cho câu hỏi trạng thái lead, học bổng, nhập học, ngành quan tâm.

**Ăn các câu:**

1. Trạng thái của các Lead đang ra sao?
2. Có bao nhiêu lead đã nhập học?
3. Có bao nhiêu lead đã cọc tiền xét học bổng?
4. Có bao nhiêu lead đã đăng ký xét học bổng?
5. Thời gian nộp hồ sơ của các lead xét học bổng là khi nào?
6. Các chuyên ngành mà lead hay quan tâm nhất?
7. Có bao nhiêu lead có trạng thái chăm sóc là không đủ tài chính
8. Lead nào có phụ huynh hỗ trợ cao nhưng chưa nhập học?
9. Có bao nhiêu lead có điểm tiềm năng là A hiện tại - dự báo doanh thu

**Bảng chính**

* `leads`
* phụ trợ: `lead_stage_history`

**Vì sao**
Các trạng thái như `isScholarshipApplied`, `isScholarshipDeposited`, `isEnrolled`, `isAdmitted`, `isTuitionPaid`, `smartScore`, `parentSupport`, `financialSituation`, `interestedMajors`, `careStatus`, `stage` đều nằm ở `leads`; còn lịch sử đổi stage nằm ở `lead_stage_history`. 

---

## Workspace B — Funnel & Enrollment Analytics

Dùng cho conversion, ranking, stalled lead, so sánh theo ngành.

**Ăn các câu:**

1. Bảng xếp hạng CVTS theo số lead đã nhập học
2. Tỷ lệ lead từ "đã ĐKOL" sang "đã trúng tuyển" là bao nhiêu?
3. Số lead đã trúng tuyển quá 14 ngày mà chưa có diễn biến thêm?
4. So sánh số lượng lead đã hoàn tất học phí giữa các ngành
5. Tỷ lệ hoàn tất học phí theo ngành?

**Bảng chính**

* `leads`
* `lead_stage_history`
* `users`

**Vì sao**
`lead_stage_history` dùng cho conversion giữa các stage và tính thời gian ở stage; `leads` giữ trạng thái hiện tại như `isAdmitted`, `isEnrolled`, `isTuitionPaid`; `users` dùng cho ranking theo `assignedTo`.

---

## Workspace C — Messaging / Conversation Analytics

Dùng cho nội dung hội thoại, chủ đề quan tâm khi chat, insight theo tuần/tháng.

**Ăn các câu:**

1. Các chủ đề mà lead hay quan tâm khi chat?
2. Nội dung của các cuộc hội thoại trong 1 tuần qua, các bạn quan tâm điều gì?
3. Tính từ 1/1 đến giờ, cho thống kê nội dung các cuộc hội thoại
4. Tình hình chăm sóc của các CVTS đang như thế nào?
5. Chất lượng chăm sóc Lead qua Hội thoại của CVTS

**Bảng chính**

* `zalo_conversations`
* `zalo_ai_analysis`
* `zalo_ai_analysis_recap`
* phụ trợ: `users`, `leads`

**Vì sao**

* Nội dung chat gốc nằm trong `zalo_conversations.messages` và preview ở `lastMessage`, `lastMessageAt`.
* Chủ đề, sentiment, quality score nằm ở `zalo_ai_analysis.topics`, `sentiment`, `qualityScore`, `qualityGrade`.
* Thống kê xu hướng/tổng hợp nhiều hội thoại nằm ở `zalo_ai_analysis_recap.analysis`.

---

## Workspace D — Hotline / Call Analytics

Dùng cho thống kê gọi điện, nội dung gọi hotline, chất lượng chăm sóc qua hotline.

**Ăn các câu:**

1. Thống kê các cuộc gọi trong 3 ngày qua?
2. Các chủ đề mà lead hay gọi hotline để hỏi?
3. Chất lượng chăm sóc Lead qua Hotline của các CVTS

**Bảng chính**

* `voip_call_records`
* phụ trợ: `leads`, `users`

**Vì sao**
`voip_call_records` chứa `duration`, `createtime`, `direction`, `callStatus`, `recordUrl` và `analysis` JSONB có `keywords`, `topics`, `sentiment`, `quality_score`. Nhưng lưu ý rất quan trọng: nối lead qua `dst = leads.phone` và nối user qua `extension`, đều là **soft relationship**, không có FK cứng. 

---

## Workspace E — Staff Activity & Productivity

Dùng cho login/kết nối Zalo, hoạt động 24h, nhiệm vụ.

**Ăn các câu:**

1. CVTS nào chưa login Zalo?
2. Hoạt động gần nhất trong 24h của các CVTS
3. Tình hình nhiệm vụ của các CVTS?

**Bảng chính**

* `users`
* `channels`
* `activities`
* `tasks`

**Vì sao**

* `channels` quản lý kênh giao tiếp, có `channel='zalo'`, `status`, `lastSync`, `userId`, nên đây là chỗ tốt nhất để suy ra ai đã kết nối/chưa kết nối Zalo.
* `activities` ghi log hoạt động với `action`, `entityType`, `createdAt`, `userId`.
* `tasks` dùng cho workload, overdue, completed, dueDate.

---

## Workspace F — Executive Daily Summary

Dùng cho câu dạng “tình hình 2 ngày qua có gì”.

**Ăn các câu:**

1. Tình hình tuyển sinh 2 ngày qua có gì?

**Bảng tổng hợp**

* `leads`
* `lead_stage_history`
* `zalo_conversations`
* `zalo_ai_analysis`
* `voip_call_records`
* `activities`
* `tasks`

**Vì sao**
Đây không phải 1 bảng, mà là câu hỏi summary đa nguồn:

* lead mới / đổi stage
* số chat / chủ đề nổi bật
* số call / chủ đề hotline
* task overdue / completed
* hoạt động CVTS

Câu này nên route vào workspace executive summary hoặc multi-workspace planner, không nhét vào 1 workspace đơn.

---

# 2) Trả lời trực tiếp các chỗ “COI Ở ĐÂU?”

Tôi đi thẳng từng câu.

### 7. Các chủ đề mà lead hay quan tâm khi chat? COI Ở ĐÂU?

**Ưu tiên coi ở:**

* `zalo_ai_analysis.topics`
* `zalo_ai_analysis_recap.analysis`
* nếu cần raw content thì `zalo_conversations.messages`


### 8. Thống kê các cuộc gọi trong 3 ngày qua? COI Ở ĐÂU?

**Coi ở:**

* `voip_call_records.createtime`
* `voip_call_records.duration`
* `voip_call_records.direction`
* `voip_call_records.callStatus`


### 9. Các chủ đề mà lead hay gọi hotline để hỏi? COI Ở ĐÂU?

**Coi ở:**

* `voip_call_records.analysis->topics`
* `voip_call_records.analysis->keywords`
  Nếu chưa có analysis/transcription thì hiện schema này không có bảng text transcript riêng, nên mức phân tích sẽ phụ thuộc dữ liệu trong JSONB `analysis`. 

### 10. Nội dung của các cuộc hội thoại trong 1 tuần qua, các bạn quan tâm điều gì? COI Ở ĐÂU?

**Coi ở:**

* raw: `zalo_conversations.messages`, `lastMessageAt`
* extracted topics: `zalo_ai_analysis.topics`
* aggregate trend: `zalo_ai_analysis_recap.analysis`


### 11. Tính từ 1/1 đến giờ, cho thống kê nội dung các cuộc hội thoại - Ở ĐÂU

**Coi ở:**

* `zalo_conversations.lastMessageAt`
* `zalo_ai_analysis.createdAt`
* `zalo_ai_analysis_recap.createdAt`
* nội dung/chủ đề vẫn là `messages`, `topics`, `analysis` recap


### 13. CVTS nào chưa login Zalo? COI Ở ĐÂU?

**Coi ở gần đúng nhất:**

* `channels` với `channel='zalo'`
* `channels.userId`, `status`, `channelConnectedId`, `lastSync`
* join `users` để lấy danh sách CVTS
  Schema này không có cột tên thẳng là “hasLoggedIntoZalo”, nên phải **suy diễn** từ việc có/không có channel Zalo hoặc trạng thái channel. 

### 17. Chất lượng chăm sóc Lead qua Hội thoại của CVTS — COI Ở ĐÂU

**Coi ở:**

* `zalo_ai_analysis.qualityScore`
* `zalo_ai_analysis.qualityGrade`
* `zalo_ai_analysis.qualityBreakdown`
* join `zalo_conversations.userId` để ra CVTS


### 18. Chất lượng chăm sóc Lead qua Hotline của các CVTS — COI Ở ĐÂU

**Coi ở:**

* `voip_call_records.analysis->quality_score`
* `voip_call_records.analysis->sentiment`
* join mềm với user qua `extension`
  Schema có nói rõ user ↔ voip là soft relationship qua extension mapping, không có FK. 

---

# 3) Có vài câu hiện tại còn mơ hồ, phải chuẩn hóa trước khi đưa cho QueryAI

## “5. Thời gian nộp hồ sơ của các lead xét học bổng là khi nào?”

Schema có `isScholarshipApplied`, nhưng **không có cột timestamp rõ ràng kiểu `scholarshipAppliedAt`** trong `leads`.
Nên câu này hiện có 2 cách:

* nếu chỉ hỏi lead nào đã nộp → dùng `isScholarshipApplied`
* nếu hỏi “thời gian nộp” thật → phải suy từ `lead_stage_history.toStage='scholarship_applied'` và lấy `changedAt`


## “12. Tình hình tuyển sinh 2 ngày qua có gì? ----- 2 ngày qua là hôm qua hay hôm kia tới hôm nay?”

Nên chuẩn hóa rule:

* **“2 ngày qua” = rolling 48 hours tính đến hiện tại**
* nếu muốn theo ngày lịch, dùng cụm: “từ 00:00 hôm qua đến hiện tại” hoặc “2 ngày gần nhất gồm hôm nay và hôm qua”

Nếu không chốt rule này, câu trả lời sẽ lúc thì theo calendar day, lúc thì theo 48h.

## “13. CVTS nào chưa login Zalo?”

Nên đổi phrasing cho chuẩn dữ liệu:

* “CVTS nào **chưa kết nối Zalo**?”
* hoặc “CVTS nào **không có channel Zalo active**?”
  Vì schema đang lưu channel integration chứ không lưu login event riêng. 

## “16. Tình hình chăm sóc của các CVTS đang như thế nào?”

Câu này quá rộng. Nên tách thành:

* số hội thoại
* chất lượng hội thoại
* số call
* số lead đang follow
* số task overdue
  Nếu không, planner phải chắp 4–5 metric vào một câu summary.

---

# 4) Kết luận: nên chốt workspace nào cho bộ FAQ này?

Tôi khuyên chốt 5 workspace system trước, đủ dùng ngay:

### 1. Lead Status & Enrollment

* `leads`
* `lead_stage_history`
* `users`

### 2. Conversation Insights

* `zalo_conversations`
* `zalo_ai_analysis`
* `zalo_ai_analysis_recap`
* `users`
* `leads`

### 3. Hotline Insights

* `voip_call_records`
* `users`
* `leads`

### 4. Staff Productivity

* `users`
* `channels`
* `activities`
* `tasks`

### 5. Executive Admissions Summary

* planner workspace tổng hợp từ 4 workspace trên

Cách này gọn hơn 6 workspace trước, sát bộ câu hỏi hiện tại hơn.

---

# 5) Chốt nhanh từng câu thuộc workspace nào

**Lead Status & Enrollment**
1, 2, 3, 4, 5, 6, khó số 3, 4, 5, 6, 7, 8

**Conversation Insights**
7, 10, 11, 16, 17

**Hotline Insights**
8, 9, 18

**Staff Productivity**
13, 14, 15

**Executive Admissions Summary**
12

---

Đi tiếp bước thực dụng nhất là: tôi viết cho bạn luôn **bảng cấu hình workspace + intent routing cho 18 câu này** theo format JSON/YAML để nhét vào backend QueryAI.
