-- Query #32: Phân bố giới tính của lead theo tỉnh / thành phố

SELECT 
    COALESCE(region, 'Chưa xác định') AS "Tỉnh / Thành phố",
    COUNT(CASE WHEN gender = 'male' THEN 1 END) AS "Nam",
    COUNT(CASE WHEN gender = 'female' THEN 1 END) AS "Nữ", 
    COUNT(CASE WHEN gender = 'other' THEN 1 END) AS "Khác",
    COUNT(*) AS "Tổng"
FROM leads
WHERE status = 'active'
GROUP BY region
ORDER BY "Tổng" DESC, "Tỉnh / Thành phố";
