-- Query 4: Có bao nhiêu lead đã đăng ký xét học bổng?

WITH all_stages AS (
    -- Danh sách các stages quan trọng với label tiếng Việt
    SELECT 'scholarship_applied' as stage, 'Đã nộp xét hồ sơ học bổng' as stage_name, 1 as sort_order
    UNION ALL SELECT 'scholarship_deposited', 'Đã cọc tiền học bổng', 2
    UNION ALL SELECT 'admitted', 'Đã trúng tuyển', 3
    UNION ALL SELECT 'enrolled', 'Đã nhập học', 4
    UNION ALL SELECT 'tuition_paid', 'Đã hoàn tất đóng học phí', 5
    UNION ALL SELECT 'enrollment_cancelled', 'Hủy nhập học', 6
),
lead_counts AS (
    -- Đếm số lead theo từng stage (chỉ active leads)
    SELECT 
        stage,
        COUNT(*) as count
    FROM leads
    WHERE status = 'active'
    GROUP BY stage
),
total_leads AS (
    -- Tổng số lead
    SELECT COUNT(*) as total
    FROM leads
    WHERE status = 'active'
)
-- Thống kê từng stage
SELECT 
    s.stage_name as "Giai đoạn",
    COALESCE(l.count, 0) as "Số lượng",
    CASE 
        WHEN t.total > 0 THEN ROUND(COALESCE(l.count, 0) * 100.0 / t.total, 2)
        ELSE 0
    END as "Tỷ lệ (%)"
FROM all_stages s
LEFT JOIN lead_counts l ON s.stage = l.stage
CROSS JOIN total_leads t
ORDER BY s.sort_order;