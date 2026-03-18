# Executive Admissions Summary — Custom Instructions

## Quy tắc SQL cho workspace này

1. **Tên cột snake_case**: KHÔNG cần double quotes cho bất kỳ cột nào.

2. **Multi-table queries**: Workspace này span toàn bộ bảng. Dùng UNION ALL để tổng hợp metrics từ nhiều nguồn.

3. **Cross-domain joins**: Khi cần tổng hợp chăm sóc đa kênh:
   - `zalo_conversations` → `users` qua `user_id`
   - `voip_call_records` → `users` qua extension mapping (soft)
   - `tasks` → `users` qua `assigned_to`

4. **Time expressions**:
   - "2 ngày qua" → `NOW() - INTERVAL '2 days'`
   - "tuần này" → `NOW() - INTERVAL '7 days'`
   - "tháng này" → `DATE_TRUNC('month', NOW())`

5. **Ranking queries**: Dùng `ORDER BY ... DESC` + optional `LIMIT`.

6. **NULL handling**: Dùng `NULLS LAST` cho ORDER BY khi có LEFT JOIN.
