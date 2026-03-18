Đúng, đây là module tiếp theo rất logic sau workspace.

Nếu workspace là **bộ nhớ có tổ chức theo domain**, thì **Intent Agent là bộ định tuyến đầu vào**.

Uber đang nói rõ một nguyên lý rất đáng học:

> **Đừng cho user question đi retrieval ngay.**
> Hãy bắt nó đi qua một lớp hiểu ý định trước, rồi mới quyết định tìm cái gì.

Với hệ của bạn, đây gần như là **module bắt buộc phải có**.

---

# 1) Intent Agent của Uber thực chất làm gì?

Theo đoạn bạn đưa, flow là:

`User prompt`
→ `Intent Agent`
→ map sang **1 hoặc nhiều workspace**
→ từ workspace mới lấy:

* SQL samples
* tables
* context để RAG

Tức là Intent Agent không sinh SQL.
Nó làm nhiệm vụ:

### A. Hiểu user đang hỏi loại câu gì

Ví dụ:

* hỏi trạng thái lead
* hỏi chất lượng chat
* hỏi số cuộc gọi
* hỏi hiệu suất CVTS
* hỏi báo cáo tổng hợp

### B. Chọn đúng business domain

Ví dụ:

* `Lead Status & Enrollment`
* `Conversation Insights`
* `Hotline Insights`
* `Staff Productivity`
* hoặc `Executive Admissions Planner`

### C. Giảm search radius cho RAG

Đây là câu quan trọng nhất của Uber.

Thay vì search trên toàn bộ:

* tất cả table
* tất cả SQL examples
* tất cả metadata

hệ thống chỉ search trong **workspace đã chọn**.

---

# 2) Tại sao Intent Agent quan trọng đến vậy?

Vì nếu bỏ Intent Agent, pipeline sẽ thành:

`user question -> retrieve toàn cục -> prompt LLM`

Cách này ở quy mô nhỏ còn tạm được. Nhưng khi bảng nhiều, domain nhiều, câu hỏi mơ hồ, nó sẽ lỗi ở 3 chỗ:

## A. Retrieve sai domain

Ví dụ user hỏi:

> Chất lượng chăm sóc Lead qua Hội thoại của CVTS

Nếu không có intent layer, hệ thống có thể lôi:

* `activities`
* `tasks`
* `lead_stage_history`

trong khi đáng ra domain chính là:

* `Conversation Insights`

---

## B. Lẫn context

Ví dụ user hỏi:

> Thống kê các cuộc gọi trong 3 ngày qua?

Nếu search toàn bộ, có thể model kéo cả:

* Zalo conversations
* activities
* lead status

Thế là prompt bị nhiễu.

---

## C. Tốn token

Bạn có 5 workspace, sau này có thể 10–15 cái.
Không thể mỗi câu hỏi lại nhét toàn bộ schema và samples của cả hệ thống.

Intent Agent giúp:

* giảm token
* tăng precision
* tăng tốc
* giảm hallucination

---

# 3) Với hệ của bạn, Intent Agent nên map ra cái gì?

Không chỉ map ra 1 label đơn.

Tôi khuyên output của Intent Agent nên có cấu trúc như này:

```json
{
  "question_type": "analytics",
  "intents": ["conversation_quality"],
  "workspaces": ["Conversation Insights"],
  "confidence": 0.93,
  "requires_planner": false,
  "time_range_detected": "last_7_days",
  "entities_detected": ["CVTS", "Lead", "Hội thoại"]
}
```

Hoặc với câu phức tạp:

```json
{
  "question_type": "executive_summary",
  "intents": ["admissions_overview", "cross_workspace_summary"],
  "workspaces": ["Lead Status & Enrollment", "Conversation Insights", "Hotline Insights", "Staff Productivity"],
  "confidence": 0.88,
  "requires_planner": true,
  "time_range_detected": "last_2_days",
  "entities_detected": ["tuyển sinh", "2 ngày qua"]
}
```

---

# 4) Cái hay nhất trong thiết kế của Uber: “one or more business domains”

Đây là điểm rất đúng.

Vì không phải câu nào cũng chỉ thuộc 1 workspace.

---

## Ví dụ câu đơn-domain

> Có bao nhiêu lead đã nhập học?

→ chỉ cần:

* `Lead Status & Enrollment`

---

## Ví dụ câu đa-domain

> Tình hình tuyển sinh 2 ngày qua có gì?

Câu này có thể cần:

* lead movement
* chat trend
* hotline trend
* staff activity

→ phải map ra nhiều workspace

---

## Ví dụ câu ranh giới mờ

> Tình hình chăm sóc của các CVTS đang như thế nào?

Câu này có thể cần:

* `Staff Productivity`
* `Conversation Insights`
* `Hotline Insights`

Nên Intent Agent không được ép lúc nào cũng ra đúng 1 workspace.
Nó phải hỗ trợ:

* single-workspace
* multi-workspace
* planner handoff

---

# 5) “Picking a business domain drastically narrows the search radius for RAG” nghĩa là gì trong hệ của bạn?

Nghĩa là sau khi chọn workspace, toàn bộ retrieval phía sau sẽ bị giới hạn.

Ví dụ câu:

> Các chủ đề mà lead hay quan tâm khi chat?

Intent Agent chọn:

* workspace = `Conversation Insights`

Thì RAG chỉ cần tìm trong:

* `zalo_conversations`
* `zalo_ai_analysis`
* `zalo_ai_analysis_recap`
* SQL mẫu của chat analytics
* glossary của conversation topic / sentiment / recap

Không cần xem:

* `tasks`
* `activities`
* `voip_call_records`

Đó chính là “search radius”.

---

# 6) Với 5 workspace của bạn, tôi sẽ thiết kế Intent Agent như sau

## A. Tầng 1: classify câu hỏi thuộc loại nào

Các loại chính:

* `lead_pipeline`
* `conversation_insight`
* `hotline_insight`
* `staff_productivity`
* `executive_summary`

---

## B. Tầng 2: quyết định số workspace cần gọi

### Loại 1: Single workspace

Ví dụ:

* “Có bao nhiêu lead đã nhập học?”
* “CVTS nào chưa login Zalo?”
* “Thống kê các cuộc gọi trong 3 ngày qua?”

→ chỉ map 1 workspace

### Loại 2: Multi workspace

Ví dụ:

* “Tình hình chăm sóc của các CVTS đang như thế nào?”
* “Chất lượng chăm sóc Lead nói chung”
* “Tình hình tuyển sinh 2 ngày qua có gì?”

→ map nhiều workspace

### Loại 3: Planner required

Ví dụ:

* “Bảng xếp hạng CVTS theo số lead đã nhập học”
* “Dự báo doanh thu từ lead tiềm năng A”
* “Tổng hợp tình hình tuyển sinh tuần này”

→ chuyển sang `Executive Admissions Planner`

---

## C. Tầng 3: detect entities và temporal cues

Ví dụ:

* “3 ngày qua”
* “1 tuần qua”
* “từ 1/1 đến giờ”
* “24h gần nhất”
* “quá 14 ngày”

Đây là input rất quan trọng cho downstream SQL generator.

---

# 7) Intent Agent của bạn không nên chỉ đoán “topic”, mà phải đoán “query objective”

Đây là chỗ nhiều hệ làm dở.

Ví dụ hai câu này cùng nhắc đến lead:

### Câu 1

> Có bao nhiêu lead đã nhập học?

Objective = count current status

### Câu 2

> Tỷ lệ lead từ "đã ĐKOL" sang "đã trúng tuyển" là bao nhiêu?

Objective = stage conversion

### Câu 3

> Số lead đã trúng tuyển quá 14 ngày mà chưa có diễn biến thêm?

Objective = stagnation detection

Cả 3 đều thuộc Lead workspace, nhưng **intent khác nhau**.
Nên Intent Agent phải dự đoán được objective, không chỉ domain.

---

# 8) Bộ intent label sơ bộ cho hệ của bạn

Tôi đề xuất luôn để bạn dùng.

## Lead Status & Enrollment

* `lead_current_status`
* `lead_count_by_stage`
* `lead_stage_conversion`
* `lead_stagnation`
* `scholarship_pipeline`
* `tuition_completion`
* `major_interest`
* `enrollment_summary`

## Conversation Insights

* `conversation_topics`
* `conversation_topic_trend`
* `conversation_summary`
* `conversation_quality`
* `care_quality_chat`
* `lead_interest_from_chat`

## Hotline Insights

* `call_volume`
* `call_volume_trend`
* `call_topics`
* `call_quality`
* `care_quality_hotline`

## Staff Productivity

* `staff_login_status`
* `staff_recent_activity`
* `staff_task_status`
* `staff_productivity_summary`
* `staff_care_activity`

## Executive Admissions Planner

* `executive_admissions_overview`
* `staff_ranking`
* `revenue_forecast`
* `cross_workspace_care_quality`
* `admissions_alerts`

---

# 9) Map nhanh câu hỏi mẫu của bạn sang intent

Ví dụ:

* “Trạng thái của các Lead đang ra sao?”
  → `lead_current_status`

* “Có bao nhiêu lead đã nhập học?”
  → `lead_count_by_stage` hoặc `enrollment_summary`

* “Các chủ đề mà lead hay quan tâm khi chat?”
  → `conversation_topics`

* “Thống kê các cuộc gọi trong 3 ngày qua?”
  → `call_volume_trend`

* “CVTS nào chưa login Zalo?”
  → `staff_login_status`

* “Tình hình tuyển sinh 2 ngày qua có gì?”
  → `executive_admissions_overview`

* “Bảng xếp hạng CVTS theo số lead đã nhập học”
  → `staff_ranking`

* “Tỷ lệ lead từ đã ĐKOL sang đã trúng tuyển là bao nhiêu?”
  → `lead_stage_conversion`

* “Số lead đã trúng tuyển quá 14 ngày mà chưa có diễn biến thêm?”
  → `lead_stagnation`

---

# 10) Nên dùng LLM-only hay hybrid?

Uber nói họ dùng LLM call để infer intent.
Với hệ của bạn, tôi khuyên **hybrid**, không nên LLM-only hoàn toàn.

## Nên làm kiểu này:

### Rule layer trước

Bắt các case rõ ràng:

* có “cuộc gọi”, “hotline” → ưu tiên Hotline
* có “hội thoại”, “chat”, “zalo” → ưu tiên Conversation
* có “login”, “nhiệm vụ”, “hoạt động CVTS” → ưu tiên Staff
* có “nhập học”, “trúng tuyển”, “học phí”, “học bổng” → ưu tiên Lead
* có “tình hình tổng quan”, “báo cáo”, “xếp hạng”, “dự báo” → Executive/Planner

### LLM layer sau

Dùng khi:

* câu mơ hồ
* nhiều domain
* cần multi-label classification
* cần suy luận theo ngữ cảnh

Cách này ổn hơn vì:

* rẻ hơn
* dễ debug hơn
* ít random hơn
* vẫn giữ được sự linh hoạt của LLM

---

# 11) Intent Agent nên trả về gì cho downstream?

Tối thiểu nên có 6 field:

```json
{
  "primary_workspace": "Conversation Insights",
  "secondary_workspaces": [],
  "intent": "conversation_topics",
  "requires_planner": false,
  "time_range": "last_7_days",
  "reasoning_summary": "User asks about topics leads care about in chat, so use conversation analysis tables."
}
```

Nếu là câu phức tạp:

```json
{
  "primary_workspace": "Executive Admissions Planner",
  "secondary_workspaces": [
    "Lead Status & Enrollment",
    "Conversation Insights",
    "Hotline Insights",
    "Staff Productivity"
  ],
  "intent": "executive_admissions_overview",
  "requires_planner": true,
  "time_range": "last_2_days",
  "reasoning_summary": "This is a cross-domain admissions summary question."
}
```

`reasoning_summary` rất có ích cho debug, log, analytics nội bộ.

---

# 12) Các failure mode bạn phải đề phòng

## A. Câu ngắn, mơ hồ

> “Tình hình gần đây sao rồi?”

Không đủ thông tin.
Agent dễ route sai.

## B. Câu có nhiều domain chồng nhau

> “Chất lượng chăm sóc lead của CVTS”

Có thể chạm:

* Conversation
* Hotline
* Staff
* Executive

## C. Câu có từ business nội bộ

Ví dụ:

* ĐKOL
* CVTS
* lead A
* chăm sóc tốt
* phụ huynh hỗ trợ cao

Các từ này phải có glossary hoặc examples, không thì LLM đoán bừa.

## D. Câu hỏi “quality” nhưng thiếu metric definition

Ví dụ:

> Chất lượng chăm sóc là gì?

Nếu chưa định nghĩa thì route đúng cũng chưa đủ, SQL vẫn yếu.

---

# 13) Kết luận kiến trúc

Đoạn Uber này xác nhận một thứ rất quan trọng cho hệ của bạn:

> **Workspace chỉ phát huy tác dụng khi có Intent Agent đứng trước nó.**

Không có Intent Agent thì workspace chỉ là cấu trúc lưu trữ.
Có Intent Agent thì workspace mới trở thành **cơ chế điều phối tri thức**.

Nói gọn:

* **Workspace** = kho tri thức theo domain
* **Intent Agent** = bộ định tuyến câu hỏi vào đúng kho
* **RAG** = tìm đúng context trong kho đã chọn
* **SQL Agent** = dùng context đó để lập kế hoạch và sinh SQL

---

Bước tiếp theo đúng nhất bây giờ là làm luôn **spec cho Intent Agent của hệ bạn**:
gồm `input schema`, `output schema`, `intent labels`, `routing rules`, và map toàn bộ 18 câu hỏi mẫu vào format chuẩn.
