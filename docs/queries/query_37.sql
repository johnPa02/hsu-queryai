-- Query #37: Tổng chi tiêu năm nay và thực tế đã nhập học?

WITH total_target_students_cte AS (
  SELECT SUM(expected_admissions) AS total_target_students
  FROM school_kpi_targets
  -- Có thể thêm WHERE nếu cần lọc theo period, region, etc.
),
total_enrolled_leads_cte AS (
  SELECT COUNT(*) AS total_enrolled_leads
  FROM leads 
  WHERE is_enrolled = true
  -- Hoặc WHERE stage = 'enrolled' nếu dùng stage thay vì boolean flag
)
SELECT 
  tts.total_target_students,
  tel.total_enrolled_leads,
  CASE 
    WHEN tts.total_target_students > 0 
    THEN ROUND((tel.total_enrolled_leads::decimal / tts.total_target_students) * 100, 2)
    ELSE 0 
  END as achievement_rate_percentage
FROM total_target_students_cte tts
CROSS JOIN total_enrolled_leads_cte tel;