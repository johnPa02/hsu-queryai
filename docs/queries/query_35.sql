-- Query #35: Phân bố chuyên ngành của lead theo tỉnh thành

WITH top_majors AS (
    SELECT major, COUNT(*) AS total_leads
    FROM (
        SELECT TRIM(unnest(string_to_array(interested_majors, ','))) AS major
        FROM leads
        WHERE status = 'active' 
          AND interested_majors IS NOT NULL 
          AND interested_majors != ''
    ) AS unnested
    GROUP BY major
    ORDER BY total_leads DESC
    LIMIT 10
),
major_regions AS (
    SELECT tm.major, l.region, COUNT(*) AS region_count
    FROM top_majors tm
    JOIN leads l ON l.status = 'active' 
                  AND l.interested_majors IS NOT NULL 
                  AND l.interested_majors != ''
    CROSS JOIN LATERAL unnest(string_to_array(l.interested_majors, ',')) AS u(major)
    WHERE TRIM(u.major) = tm.major
    GROUP BY tm.major, l.region
),
ranked_regions AS (
    SELECT major, region, region_count,
           ROW_NUMBER() OVER (PARTITION BY major ORDER BY region_count DESC) AS rn
    FROM major_regions
    WHERE region IS NOT NULL
),
top_regions_per_major AS (
    SELECT major, STRING_AGG(region, ', ') AS top_regions
    FROM ranked_regions
    WHERE rn <= 3
    GROUP BY major
)
SELECT 
    tm.major AS "Ngành học", 
    tm.total_leads AS "Tổng lead", 
    COALESCE(tr.top_regions, 'N/A') AS "Top 3 Region"
FROM top_majors tm
LEFT JOIN top_regions_per_major tr ON tm.major = tr.major
ORDER BY tm.total_leads DESC;