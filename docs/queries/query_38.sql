-- Query #38: Danh sách phân công trường và lead chăm sóc của từng CVTS

WITH cvts_users AS (
  SELECT id, "full_name" 
  FROM users 
  WHERE role = 'cvts' AND status = 'active'
),
school_counts AS (
  SELECT "user_id", COUNT(DISTINCT "school_id") as "totalSchools"
  FROM user_school_assignments 
  WHERE status = 'active'
  GROUP BY "user_id"
),
lead_counts AS (
  SELECT "assigned_to", COUNT(*) as "totalLeads"
  FROM leads 
  WHERE "assigned_to" IS NOT NULL
  GROUP BY "assigned_to"
)
SELECT 
  cu."full_name",
  COALESCE(sc."totalSchools", 0) as "total_schools",
  COALESCE(lc."totalLeads", 0) as "total_leads"
FROM cvts_users cu
LEFT JOIN school_counts sc ON cu.id = sc."user_id"
LEFT JOIN lead_counts lc ON cu.id = lc."assigned_to"
ORDER BY "totalSchools" DESC, cu."full_name";