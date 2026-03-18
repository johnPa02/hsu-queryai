-- Query #24: Tình hình học sinh phân bố theo nguồn

WITH source_stage_stats AS (
    -- Đếm số lead theo source và stage
    SELECT 
        source,
        stage,
        COUNT(*) as count
    FROM leads
    WHERE status = 'active'
    GROUP BY source, stage
),
source_totals AS (
    -- Tổng số lead theo source
    SELECT 
        source,
        COUNT(*) as total
    FROM leads
    WHERE status = 'active'
    GROUP BY source
),
grand_total AS (
    -- Tổng số lead toàn hệ thống
    SELECT COUNT(*) as total
    FROM leads
    WHERE status = 'active'
),
source_breakdown AS (
    SELECT 
        CASE st.source
            WHEN 'zalo' THEN 'Zalo'
            WHEN 'facebook' THEN 'Facebook'
            WHEN 'form' THEN 'Form đăng ký'
            WHEN 'direct' THEN 'Trực tiếp'
            WHEN 'event' THEN 'Sự kiện'
            WHEN 'referral' THEN 'Giới thiệu'
            WHEN 'HSU' THEN 'HSU'
            ELSE COALESCE(st.source, 'Chưa xác định')
        END as source_name,
        st.total as total_leads,
        ROUND(st.total * 100.0 / gt.total, 2) as percentage,
        
        -- Conversion rate (enrolled / total)
        CASE 
            WHEN st.total > 0 THEN 
                ROUND(COALESCE(SUM(sss.count) FILTER (WHERE sss.stage = 'enrolled'), 0) * 100.0 / st.total, 2)
            ELSE 0
        END as conversion_rate,
        
        -- Sort order
        CASE st.source
            WHEN 'facebook' THEN 1
            WHEN 'zalo' THEN 2
            WHEN 'form' THEN 3
            WHEN 'HSU' THEN 4
            WHEN 'event' THEN 5
            WHEN 'direct' THEN 6
            WHEN 'referral' THEN 7
            ELSE 98
        END as sort_order

    FROM source_totals st
    LEFT JOIN source_stage_stats sss ON st.source = sss.source
    CROSS JOIN grand_total gt
    GROUP BY st.source, st.total, gt.total
)
SELECT 
    source_name as "Nguồn",
    total_leads as "Tổng Lead",
    percentage as "Tỷ lệ (%)",
    conversion_rate as "Tỷ lệ nhập học (%)"
FROM source_breakdown

UNION ALL

-- Row TOTAL
SELECT 
    'TỔNG CỘNG' as "Nguồn",
    gt.total as "Tổng Lead",
    100.00 as "Tỷ lệ (%)",
    CASE 
        WHEN gt.total > 0 THEN 
            ROUND(SUM(sss.count) FILTER (WHERE sss.stage = 'enrolled') * 100.0 / gt.total, 2)
        ELSE 0
    END as "Tỷ lệ nhập học (%)"
FROM source_stage_stats sss
CROSS JOIN grand_total gt
GROUP BY gt.total