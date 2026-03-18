-- Query 15: Tình hình nhiệm vụ của các CVTS?

SELECT 
    u.full_name as "CVTS",
    u.area as "Khu vực",
    
    -- Tổng số tasks
    COUNT(t.id) as "Tổng tasks",
    
    -- Phân loại theo trạng thái
    COUNT(t.id) FILTER (WHERE t.completed = true) as "Đã hoàn thành",
    COUNT(t.id) FILTER (WHERE t.completed = false) as "Chưa hoàn thành",
    
    -- Phân loại theo thời hạn
    COUNT(t.id) FILTER (WHERE t.completed = false AND t.due_date < NOW()) as "Quá hạn",
    COUNT(t.id) FILTER (WHERE t.completed = false AND t.due_date >= NOW() AND t.due_date <= NOW() + INTERVAL '3 days') as "Sắp đến hạn (3 ngày)",
    COUNT(t.id) FILTER (WHERE t.completed = false AND t.due_date > NOW() + INTERVAL '3 days') as "Còn thời gian",
    
    -- Phân loại theo độ ưu tiên
    COUNT(t.id) FILTER (WHERE t.priority = 'high') as "Ưu tiên cao",
    COUNT(t.id) FILTER (WHERE t.priority = 'medium') as "Ưu tiên trung bình",
    COUNT(t.id) FILTER (WHERE t.priority = 'low') as "Ưu tiên thấp",
    
    -- Phân loại theo loại task
    COUNT(t.id) FILTER (WHERE t.type = 'follow-up') as "Follow-up",
    COUNT(t.id) FILTER (WHERE t.type = 'callback') as "Callback",
    COUNT(t.id) FILTER (WHERE t.type = 'meeting') as "Meeting",
    COUNT(t.id) FILTER (WHERE t.type = 'email') as "Email",
    
    -- Tỷ lệ hoàn thành
    CASE 
        WHEN COUNT(t.id) > 0 THEN 
            ROUND(COUNT(t.id) FILTER (WHERE t.completed = true) * 100.0 / COUNT(t.id), 2)
        ELSE 0
    END as "Tỷ lệ hoàn thành (%)",
    
    -- Thời gian
    TO_CHAR(MIN(t.created_at), 'DD/MM/YYYY') as "Task đầu tiên",
    TO_CHAR(MAX(t.created_at), 'DD/MM/YYYY') as "Task gần nhất",
    TO_CHAR(MIN(t.due_date) FILTER (WHERE t.completed = false), 'DD/MM/YYYY') as "Deadline gần nhất"

FROM users u

LEFT JOIN tasks t ON u.id = t.assigned_to

WHERE u.role = 'cvts' 
    AND u.status = 'active'

GROUP BY u.id, u.full_name, u.area

ORDER BY COUNT(t.id) FILTER (WHERE t.completed = false AND t.due_date < NOW()) DESC, 
         COUNT(t.id) DESC;