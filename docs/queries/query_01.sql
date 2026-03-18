-- Query 1: Giai đoạn của các Lead đang ra sao?

WITH all_stages AS (
    -- Danh sách tất cả 12 stages với label tiếng Việt
    SELECT 'raw_lead' as stage, 'Lead thô' as stage_name, 1 as sort_order
    UNION ALL SELECT 'interested_in_major', 'Quan tâm đến chuyên ngành', 2
    UNION ALL SELECT 'scholarship_applied', 'Đã nộp hồ sơ học bổng', 3
    UNION ALL SELECT 'scholarship_deposited', 'Đã cọc tiền học bổng', 4
    UNION ALL SELECT 'account_created', 'Đã tạo tài khoản xét tuyển', 5
    UNION ALL SELECT 'online_admission', 'Đã đăng ký xét tuyển Online', 6
    UNION ALL SELECT 'hardcopy_submitted', 'Đã nộp hồ sơ giấy', 7
    UNION ALL SELECT 'admitted', 'Đã trúng tuyển', 8
    UNION ALL SELECT 'enrolled', 'Đã nhập học', 9
    UNION ALL SELECT 'tuition_paid', 'Đã hoàn tất đóng học phí', 10
    UNION ALL SELECT 'enrollment_cancelled', 'Hủy nhập học', 11
    UNION ALL SELECT 'not_interested', 'Không quan tâm', 12
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
),
stage_stats AS (
    -- Thống kê từng stage
    SELECT 
        s.stage,
        s.stage_name,
        COALESCE(l.count, 0) as count,
        CASE 
            WHEN t.total > 0 THEN ROUND(COALESCE(l.count, 0) * 100.0 / t.total, 2)
            ELSE 0
        END as percentage,
        s.sort_order
    FROM all_stages s
    LEFT JOIN lead_counts l ON s.stage = l.stage
    CROSS JOIN total_leads t
)
-- Kết hợp stage stats + row TOTAL
SELECT 
    stage_name,
    count,
    percentage
FROM stage_stats

UNION ALL

-- Row TOTAL
SELECT 
    'TỔNG CỘNG' as stage_name,
    total as count,
    100.00 as percentage
FROM total_leads