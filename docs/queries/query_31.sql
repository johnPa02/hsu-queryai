-- Query #31: Phân bố giới tính của lead theo ngành

WITH majors AS (
    SELECT 
        gender,
        TRIM(unnest(string_to_array(interested_majors, ','))) AS major
    FROM leads
    WHERE status = 'active' 
      AND interested_majors IS NOT NULL 
      AND interested_majors != ''
)
SELECT 
    major AS "Ngành học",
    COUNT(CASE WHEN gender = 'male' THEN 1 END) AS "Nam",
    COUNT(CASE WHEN gender = 'female' THEN 1 END) AS "Nữ", 
    COUNT(CASE WHEN gender = 'other' THEN 1 END) AS "Khác",
    COUNT(*) AS "Tổng"
FROM majors
GROUP BY major
ORDER BY "Tổng" DESC, "Ngành học";