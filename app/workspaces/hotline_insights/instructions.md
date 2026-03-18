# Hotline Insights — Custom Instructions

## Quy tắc SQL cho workspace này

1. **Tên cột snake_case**: KHÔNG cần double quotes.
   - ✅ `call_status`, `record_url`, `imported_at`
   - ❌ `"callStatus"`, `"recordUrl"`, `"importedAt"`

2. **Soft relationships**: KHÔNG CÓ FK cứng.
   - `voip_call_records.dst` ↔ `leads.phone` (match qua số điện thoại)
   - `voip_call_records.extension` ↔ users (match qua extension mapping)

3. **Analysis JSONB**: Truy cập bằng `->` (JSONB) và `->>` (text):
   - `analysis->>'quality_score'` → text, cần cast `::numeric`
   - `analysis->>'sentiment'` → 'positive','neutral','negative'
   - `analysis->'topics'` → JSONB array, dùng `jsonb_array_elements_text()`
   - `analysis->'keywords'` → JSONB array

4. **Call status**: `answered`, `missed`, `voicemail`

5. **Direction**: `inbound` (gọi đến), `outbound` (gọi đi), `internal` (nội bộ)

6. **Time filter**: Dùng `createtime` cho filter thời gian.

7. **Duration**: Đơn vị giây (seconds).
