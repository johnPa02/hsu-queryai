-- Query #23: Tình hình học sinh phân bố theo khu vực?

WITH area_stage_stats AS (
    -- Đếm số lead theo area và stage
    SELECT 
        COALESCE(area, 'Chưa phân loại') as area,
        stage,
        COUNT(*) as count
    FROM leads
    WHERE status = 'active'
    GROUP BY area, stage
),
area_totals AS (
    -- Tổng số lead theo area
    SELECT 
        COALESCE(area, 'Chưa phân loại') as area,
        COUNT(*) as total
    FROM leads
    WHERE status = 'active'
    GROUP BY area
),
grand_total AS (
    -- Tổng số lead toàn hệ thống
    SELECT COUNT(*) as total
    FROM leads
    WHERE status = 'active'
),
area_breakdown AS (
    SELECT 
        at.area as area_name,
        at.total as total_leads,
        ROUND(at.total * 100.0 / gt.total, 2) as percentage,
        
        -- Breakdown theo các stage quan trọng
        COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'raw_lead'), 0) as raw_lead,
        COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'interested_in_major'), 0) as interested,
        COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'scholarship_applied'), 0) as scholarship,
        COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'admitted'), 0) as admitted,
        COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'enrolled'), 0) as enrolled,
        COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'tuition_paid'), 0) as tuition_paid,
        
        -- Conversion rate (enrolled / total)
        CASE 
            WHEN at.total > 0 THEN 
                ROUND(COALESCE(SUM(ass.count) FILTER (WHERE ass.stage = 'enrolled'), 0) * 100.0 / at.total, 2)
            ELSE 0
        END as conversion_rate,
        
        -- Sort order
        CASE 
            WHEN at.area = 'DNB & HCM' THEN 1
            WHEN at.area = 'TNB & HCM' THEN 2
            WHEN at.area = 'Chưa phân loại' THEN 98
            ELSE 3
        END as sort_order

    FROM area_totals at
    LEFT JOIN area_stage_stats ass ON at.area = ass.area
    CROSS JOIN grand_total gt
    GROUP BY at.area, at.total, gt.total
)
SELECT 
    area_name as "Khu vực",
    total_leads as "Tổng Lead",
    percentage as "Tỷ lệ (%)",
    raw_lead as "Lead thô",
    interested as "Quan tâm ngành",
    scholarship as "Nộp Học Bổng",
    admitted as "Trúng tuyển",
    enrolled as "Đã nhập học",
    tuition_paid as "Đóng học phí",
    conversion_rate as "Tỷ lệ nhập học (%)"
FROM area_breakdown

UNION ALL

-- Row TOTAL
SELECT 
    'TỔNG CỘNG' as "Khu vực",
    gt.total as "Tổng Lead",
    100.00 as "Tỷ lệ (%)",
    SUM(ass.count) FILTER (WHERE ass.stage = 'raw_lead') as "Lead thô",
    SUM(ass.count) FILTER (WHERE ass.stage = 'interested_in_major') as "Quan tâm ngành",
    SUM(ass.count) FILTER (WHERE ass.stage = 'scholarship_applied') as "Nộp HB",
    SUM(ass.count) FILTER (WHERE ass.stage = 'admitted') as "Trúng tuyển",
    SUM(ass.count) FILTER (WHERE ass.stage = 'enrolled') as "Đã nhập học",
    SUM(ass.count) FILTER (WHERE ass.stage = 'tuition_paid') as "Đóng học phí",
    CASE 
        WHEN gt.total > 0 THEN 
            ROUND(SUM(ass.count) FILTER (WHERE ass.stage = 'enrolled') * 100.0 / gt.total, 2)
        ELSE 0
    END as "Tỷ lệ nhập học (%)"
FROM area_stage_stats ass
CROSS JOIN grand_total gt
GROUP BY gt.total
