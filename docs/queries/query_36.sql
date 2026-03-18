-- Query #36: Tổng quan về số lượng trường học, chia theo khu vực, top tỉnh thành có nhiều trường nhất, top trường có nhiều học sinh nhất

WITH 
total_schools_cte AS (
  SELECT COUNT(*) AS total_schools
  FROM schools
  WHERE status = 'active'
),
schools_by_area_cte AS (
  SELECT JSON_AGG(
    JSON_BUILD_OBJECT('area', area, 'school_count', school_count)
  ) AS schools_by_area
  FROM (
    SELECT area, COUNT(*) AS school_count
    FROM schools
    WHERE status = 'active'
    GROUP BY area
    ORDER BY school_count DESC
  ) sub
),
top_provinces_cte AS (
  SELECT JSON_AGG(
    JSON_BUILD_OBJECT('province', province, 'school_count', school_count)
  ) AS top_provinces
  FROM (
    SELECT province, COUNT(*) AS school_count
    FROM schools
    WHERE status = 'active'
    GROUP BY province
    ORDER BY school_count DESC
    LIMIT 5
  ) sub
),
top_school_leads_cte AS (
  SELECT JSON_AGG(
    JSON_BUILD_OBJECT('school_name', school_name, 'lead_count', lead_count)
  ) AS top_school_leads
  FROM (
    SELECT s.name AS school_name, COUNT(l.id) AS lead_count
    FROM leads l
    INNER JOIN schools s ON l.school_id = s.id
    WHERE s.tier IN ('1', '2', '3', '2NT') AND l.status = 'active'
    GROUP BY s.id, s.name
    ORDER BY lead_count DESC
    LIMIT 5  -- Hoặc LIMIT 5 nếu muốn top 5
  ) sub
)
SELECT 
  ts.total_schools,
  sba.schools_by_area,
  tp.top_provinces,
  tsl.top_school_leads
FROM total_schools_cte ts
CROSS JOIN schools_by_area_cte sba
CROSS JOIN top_provinces_cte tp
CROSS JOIN top_school_leads_cte tsl;