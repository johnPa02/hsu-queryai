-- Query 13: CVTS nào chưa login Zalo?

SELECT 
    u.full_name as "CVTS",
    u.email as "Email",
    u.area as "Khu vực",
    
    -- Trạng thái Zalo
    CASE 
        WHEN c.id IS NULL THEN '❌ Chưa login'
        WHEN c.status = 'active' THEN '✅ Đang hoạt động'
        WHEN c.status = 'inactive' THEN '⚠️ Đã logout'
        WHEN c.status = 'error' THEN '🔴 Lỗi'
        ELSE '❓ Không xác định'
    END as "Trạng thái Zalo",
    
    -- Thông tin channel
    c.name as "Tên channel",
    
    -- Thời gian
    TO_CHAR(c.created_at, 'DD/MM/YYYY HH24:MI') as "Ngày tạo channel"

FROM users u

LEFT JOIN channels c ON u.id = c.user_id 
    AND c.channel = 'zalo'  -- Chỉ lấy channel Zalo

WHERE u.role = 'cvts'
    AND u.status = 'active'

ORDER BY 
    CASE 
        WHEN c.status = 'active' THEN 1
        WHEN c.status = 'inactive' THEN 2
        WHEN c.id IS NULL THEN 3
        ELSE 4
    END,
    u.full_name;