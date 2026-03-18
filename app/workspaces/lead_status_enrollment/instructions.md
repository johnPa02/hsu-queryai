# Lead Status & Enrollment — Custom Instructions

## Quy tắc SQL cho workspace này

1. **Tên cột snake_case**: Tất cả cột trong DB đều dùng snake_case, KHÔNG cần double quotes.
   - ✅ `is_enrolled`, `smart_score`, `care_status`, `full_name`
   - ❌ `"isEnrolled"`, `"smartScore"`, `"careStatus"`, `"fullName"`

2. **Filter active records**: Luôn thêm `status = 'active'` trừ khi câu hỏi rõ ràng hỏi cả deleted/inactive.

3. **⚠️ Boolean flags PHẢI đi kèm stage filter**: Khi đếm lead theo trạng thái, LUÔN filter ĐỒNG THỜI cả boolean flag VÀ stage tương ứng:
   - ✅ `is_enrolled = true AND stage = 'enrolled'`
   - ✅ `is_admitted = true AND stage = 'admitted'`
   - ✅ `is_scholarship_applied = true AND stage = 'scholarship_applied'`
   - ✅ `is_tuition_paid = true AND stage = 'tuition_paid'`
   - ❌ `is_enrolled = true` (thiếu stage filter)

4. **⚠️ Majors columns là comma-separated**: `interested_majors`, `admission_majors`, `scholarship_majors` chứa nhiều giá trị phân cách bằng dấu phẩy.
   PHẢI dùng `string_to_array() + unnest()` để tách:
   ```sql
   SELECT TRIM(program) AS nganh, COUNT(*) AS total
   FROM leads
   CROSS JOIN LATERAL unnest(string_to_array(interested_majors, ',')) AS program
   WHERE interested_majors IS NOT NULL AND status = 'active'
   GROUP BY TRIM(program)
   ORDER BY total DESC;
   ```
   - Luôn dùng `TRIM(program)` để loại bỏ khoảng trắng thừa
   - Filter `TRIM(program) <> 'Khác'` nếu muốn loại bỏ giá trị "Khác"

5. **Stage values**: Dùng enum chính xác:
   - `raw_lead`, `interested_in_major`, `scholarship_applied`, `scholarship_deposited`
   - `account_created`, `online_admission`, `hardcopy_submitted`
   - `admitted`, `enrolled`, `tuition_paid`, `enrollment_cancelled`, `not_interested`

6. **care_status values (23 giá trị)**:
   - `consulted`, `unreachable`, `wrong_number`, `callback_scheduled`
   - `scholarship_completed`, `registered_admission`, `admission_completed`
   - `enrolled_no_payment`, `enrollment_completed`, `paid_not_enrolled`
   - `insufficient_funds`, `duplicate_lead`, `interested_other_products`
   - `definitely_choose_hsu`, `not_choose_hsu`, `study_abroad`, `choose_other_school`
   - `waiting_exam_score`, `waiting_admission_letter`, `thinking_more`
   - `planning_to_register`, `confirmed_registered`, `not_yet_grade_12`

7. **smart_score**: Chỉ có 6 giá trị: `A`, `B`, `C+`, `C`, `D`, `QL`

8. **Thời gian nộp hồ sơ học bổng**: Dùng `lead_stage_history.changed_at` WHERE `to_stage = 'scholarship_applied'`.

9. **Time expressions**:
   - "2 ngày qua" → `NOW() - INTERVAL '2 days'`
   - "1 tuần qua" → `NOW() - INTERVAL '7 days'`

10. **Join users cho CVTS**: Join `leads.assigned_to = users.id` WHERE `users.role = 'cvts'`.
