-- Query 6: Các chuyên ngành mà lead hay quan tâm nhất?

SELECT 
    interested_majors as "Chuyên ngành",
    COUNT(*) as "Số lead quan tâm",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as "Tỷ lệ (%)",
    
    -- Phân tích theo stage
    COUNT(*) FILTER (WHERE stage = 'raw_lead') as "Raw Lead",
    COUNT(*) FILTER (WHERE stage = 'interested_in_major') as "Quan tâm ngành",
    COUNT(*) FILTER (WHERE stage = 'scholarship_applied') as "Đã nộp HB",
    COUNT(*) FILTER (WHERE stage = 'enrolled') as "Đã nhập học",
    
    -- Tỷ lệ chuyển đổi
    ROUND(COUNT(*) FILTER (WHERE stage = 'enrolled') * 100.0 / NULLIF(COUNT(*), 0), 2) as "Tỷ lệ nhập học (%)",
    
    -- Phân tích theo khu vực
    COUNT(*) FILTER (WHERE area = 'DNB & HCM') as "DNB & HCM",
    COUNT(*) FILTER (WHERE area = 'TNB & HCM') as "TNB & HCM"

FROM leads

WHERE interested_majors IS NOT NULL
    AND interested_majors != ''
    AND status = 'active'

GROUP BY interested_majors

ORDER BY COUNT(*) DESC

LIMIT 20;