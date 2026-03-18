-- Query #34: Phân bố chuyên ngành của lead theo khu vực

WITH ranked_majors AS (
    SELECT 
        area,
        major,
        COUNT(*) AS count,
        ROW_NUMBER() OVER (PARTITION BY area ORDER BY COUNT(*) DESC) AS rn
    FROM (
        SELECT 
            area,
            TRIM(unnest(string_to_array(interested_majors, ','))) AS major
        FROM leads
        WHERE status = 'active' 
          AND interested_majors IS NOT NULL 
          AND interested_majors != ''
          AND area IN ('DNB & HCM', 'TNB & HCM')
    ) AS sub
    GROUP BY area, major
),
major_totals AS (
    SELECT 
        major, 
        SUM(count) AS total_count,
        ROW_NUMBER() OVER (ORDER BY SUM(count) DESC) AS overall_rank
    FROM ranked_majors
    GROUP BY major
    ORDER BY total_count DESC
    LIMIT 10
),
pivoted AS (
    SELECT 
        m.major,
        m.overall_rank,
        COALESCE(d.count, 0) AS dnb_count,
        COALESCE(t.count, 0) AS tnb_count,
        m.total_count
    FROM major_totals m
    LEFT JOIN ranked_majors d ON m.major = d.major AND d.area = 'DNB & HCM'
    LEFT JOIN ranked_majors t ON m.major = t.major AND t.area = 'TNB & HCM'
)
SELECT 
    overall_rank AS "Rank",
    major AS "Ngành học",
    dnb_count AS "DNB",
    tnb_count AS "TNB",
    total_count AS "Tổng",
    ROUND(dnb_count * 100.0 / NULLIF(total_count, 0), 1) || '%' AS "% DNB",
    ROUND(tnb_count * 100.0 / NULLIF(total_count, 0), 1) || '%' AS "% TNB"
FROM pivoted
ORDER BY overall_rank;