-- Query #33: Phân bố giới tính của lead theo khu vực

SELECT 
    COALESCE(area, 'Chưa xác định') AS "Khu vực",
    COUNT(CASE WHEN gender = 'male' THEN 1 END) AS "Nam",
    COUNT(CASE WHEN gender = 'female' THEN 1 END) AS "Nữ", 
    COUNT(CASE WHEN gender = 'other' THEN 1 END) AS "Khác",
    COUNT(*) AS "Tổng"
FROM leads
WHERE status = 'active'
GROUP BY area
ORDER BY "Tổng" DESC, "Khu vực";