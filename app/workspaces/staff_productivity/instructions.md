# Staff Productivity — Custom Instructions

## Quy tắc SQL cho workspace này

1. **Tên cột snake_case**: KHÔNG cần double quotes.
   - ✅ `user_id`, `entity_type`, `due_date`, `completed_at`, `sub_type`
   - ❌ `"userId"`, `"entityType"`, `"dueDate"`, `"completedAt"`, `"subType"`

2. **CVTS chưa kết nối Zalo**: Dùng LEFT JOIN với `channels` WHERE `channel = 'zalo'` AND `status = 'active'`, rồi check `channels.id IS NULL`.

3. **Activities**: Bảng `activities` ghi log:
   - `action`: 'created', 'updated', 'contacted', 'stage_changed'
   - `entity_type`: 'lead', 'conversation', 'task'
   - Filter theo `created_at` cho time range

4. **Tasks overdue**: `completed = false AND due_date < NOW()`

5. **Tasks pending**: `completed = false AND due_date >= NOW()`

6. **Filter CVTS**: `users.role = 'cvts' AND users.status = 'active'`
