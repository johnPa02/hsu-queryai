# Conversation Insights — Custom Instructions

## Quy tắc SQL cho workspace này

1. **Tên cột snake_case**: Tất cả cột đều snake_case, KHÔNG cần double quotes.
   - ✅ `quality_score`, `quality_grade`, `zalo_conversation_id`, `last_message_at`
   - ❌ `"qualityScore"`, `"qualityGrade"`, `"zaloConversationId"`, `"lastMessageAt"`

2. **Topics từ AI analysis**: Cột `topics` là TEXT[], dùng `UNNEST(topics)` để tách mảng.

3. **Quality metrics**:
   - `quality_score`: INTEGER 0-100
   - `quality_grade`: 'A' (xuất sắc), 'B' (tốt), 'C' (trung bình), 'D' (yếu), 'F' (kém)
   - `sentiment`: 'positive', 'neutral', 'negative'

4. **Join chain**:
   - `zalo_ai_analysis` → `zalo_conversations` qua `zalo_conversation_id`
   - `zalo_conversations` → `users` qua `user_id` (CVTS owner)
   - `zalo_conversations` → `leads` qua `lead_id` (nullable)

5. **Time filter**: Dùng `zalo_conversations.last_message_at` cho filter theo thời gian.

6. **Recap data**: `zalo_ai_analysis_recap.analysis` là JSONB chứa tổng hợp nhiều hội thoại.
