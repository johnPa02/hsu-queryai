-- Query #25: Thống kê lead theo điểm tiềm năng

WITH all_scores(score) AS (
    VALUES ('A'), ('B'), ('C+'), ('C'), ('D'), ('QL')
)
SELECT 
    s.score as smart_score,                 
    COUNT(l.id) as total_leads, 
    CASE 
        WHEN SUM(COUNT(l.id)) OVER () = 0 THEN 0
        ELSE ROUND(
            COUNT(l.id) * 100.0 / SUM(COUNT(l.id)) OVER (), 
            2
        ) 
    END as percentage
FROM 
    all_scores s
LEFT JOIN 
    leads l ON s.score = l.smart_score AND l.status = 'active'
GROUP BY 
    s.score
ORDER BY 
    CASE s.score  
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C+' THEN 3
        WHEN 'C' THEN 4
        WHEN 'D' THEN 5
        WHEN 'QL' THEN 6
        ELSE 7
    END;