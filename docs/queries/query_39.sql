-- Query #39: Top trường có tỷ lệ chuyển đổi lead cao nhất

WITH school_enrolled_stats AS (
    SELECT 
        s.id AS school_id,
        s.name AS school_name,
        s.province AS school_province,
        s.region AS school_region,
        s.tier AS school_tier,
        COUNT(l.id) AS enrolled_count,
        COALESCE(skt.expected_admissions, 0) AS target_admissions
    FROM 
        schools s
    LEFT JOIN 
        leads l ON l.school_id = s.id 
            AND l.stage = 'enrolled' 
            AND l.status = 'active'
    LEFT JOIN 
        school_kpi_targets skt ON skt.school_id = s.id
    WHERE 
        s.status = 'active'
    GROUP BY 
        s.id, s.name, s.province, s.region, s.tier, skt.expected_admissions
)
SELECT 
    school_name AS "Tên Trường",
    school_province AS "Tỉnh/Thành",
    enrolled_count AS "Số Lead Nhập Học",
    target_admissions AS "Chỉ Tiêu",
    CASE 
        WHEN target_admissions > 0 
        THEN ROUND((enrolled_count::numeric / target_admissions) * 100, 2)
        ELSE 0 
    END AS "Tỷ Lệ Chuyển Đổi (%)"
FROM 
    school_enrolled_stats
WHERE 
    target_admissions > 0  -- Chỉ lấy trường có chỉ tiêu
    AND enrolled_count > 0  -- Chỉ lấy trường có lead đã nhập học
ORDER BY 
    "Tỷ Lệ Chuyển Đổi (%)" DESC,
    enrolled_count DESC
LIMIT 5;