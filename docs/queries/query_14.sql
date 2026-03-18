-- Query 14: Hoạt động gần nhất trong 24h của các CVTS

WITH extension_mapping AS (
    -- Extension mapping cho VoIP
    SELECT 'Nguyễn Bão Toàn' as cvts_name, '4403' as ext
    UNION ALL SELECT 'Phạm Hoàng Long', '4406'
    UNION ALL SELECT 'Ngô Thị Tường Vy', '4409'
    UNION ALL SELECT 'Huỳnh Phương Anh', '4412'
    UNION ALL SELECT 'Lê Thị Uyên', '4415'
    UNION ALL SELECT 'Vũ Thị Thanh Nhàn', '4416'
    UNION ALL SELECT 'Huỳnh Vũ Khang', '4420'
    UNION ALL SELECT 'Lý Như An', '4422'
    UNION ALL SELECT 'Võ Nguyễn Bảo Anh', '4430'
    UNION ALL SELECT 'Trần Thị Hồ Ngọc Thảo', '4431'
    UNION ALL SELECT 'Nguyễn Huỳnh Hồng Diệu', '4434'
    UNION ALL SELECT 'Đặng Trần Anh Thư', '4438'
    UNION ALL SELECT 'Võ Tuyết Nhung', '4657'
    UNION ALL SELECT 'Mai Anh Vũ', '4660'
    UNION ALL SELECT 'Phan Thị Tuyết Nhung', '4661'
    UNION ALL SELECT 'Huỳnh Văn Quang', '4671'
    UNION ALL SELECT 'Từ Như Hưởng', '4727'
    UNION ALL SELECT 'Võ Tuyết Thanh', '4411'
    UNION ALL SELECT 'Bùi Thành Lộc', '4414'
    UNION ALL SELECT 'Huỳnh Thị Huỳnh Nga', '4404'
    UNION ALL SELECT 'Phạm Xuân Hương', '4430'
    UNION ALL SELECT 'Nguyễn Hà Khánh Linh', '4897'
),
-- Thống kê hội thoại Zalo 24h
zalo_24h AS (
    SELECT 
        u.id as user_id,
        COUNT(DISTINCT zc.id) as conversations_24h,
        COUNT(DISTINCT CASE 
            WHEN zc.last_message_at >= NOW() - INTERVAL '24 hours' 
            THEN zc.id 
        END) as active_conversations_24h
    FROM users u
    LEFT JOIN zalo_conversations zc ON u.id = zc.user_id
        AND zc.updated_at >= NOW() - INTERVAL '24 hours'
    WHERE u.role = 'cvts' AND u.status = 'active'
    GROUP BY u.id
),
-- Thống kê cuộc gọi 24h
voip_24h AS (
    SELECT 
        u.id as user_id,
        COUNT(v.id) as calls_24h,
        SUM(v.duration) as total_duration_24h,
        ROUND(AVG(v.duration)) as avg_duration_24h
    FROM users u
    LEFT JOIN extension_mapping em ON u.full_name = em.cvts_name
    LEFT JOIN voip_call_records v ON em.ext = v.extension
        AND v.createtime >= NOW() - INTERVAL '24 hours'
    WHERE u.role = 'cvts' AND u.status = 'active'
    GROUP BY u.id
),
-- Thống kê tasks 24h
tasks_24h AS (
    SELECT 
        u.id as user_id,
        COUNT(t.id) as tasks_created_24h,
        COUNT(t.id) FILTER (WHERE t.completed = true) as tasks_completed_24h
    FROM users u
    LEFT JOIN tasks t ON u.id = t.assigned_to
        AND t.created_at >= NOW() - INTERVAL '24 hours'
    WHERE u.role = 'cvts' AND u.status = 'active'
    GROUP BY u.id
)
SELECT 
    u.full_name as "CVTS",
    u.area as "Khu vực",
    
    -- Zalo
    COALESCE(z.conversations_24h, 0) as "Hội thoại (24h)",
    COALESCE(z.active_conversations_24h, 0) as "HT có tin nhắn mới",
    
    -- VoIP
    COALESCE(v.calls_24h, 0) as "Cuộc gọi (24h)",
    COALESCE(v.total_duration_24h, 0) as "Tổng TL gọi (s)",
    COALESCE(v.avg_duration_24h, 0) as "TB TL gọi (s)",
    
    -- Tasks
    COALESCE(t.tasks_created_24h, 0) as "Tasks tạo mới",
    COALESCE(t.tasks_completed_24h, 0) as "Tasks hoàn thành",
    
    -- Tổng hoạt động
    COALESCE(z.conversations_24h, 0) + 
    COALESCE(v.calls_24h, 0) + 
    COALESCE(t.tasks_created_24h, 0) as "Tổng hoạt động",
    
    -- Trạng thái
    CASE 
        WHEN COALESCE(z.conversations_24h, 0) + COALESCE(v.calls_24h, 0) + COALESCE(t.tasks_created_24h, 0) = 0 
        THEN '❌ Không hoạt động'
        WHEN COALESCE(z.conversations_24h, 0) + COALESCE(v.calls_24h, 0) + COALESCE(t.tasks_created_24h, 0) < 5 
        THEN '⚠️ Ít hoạt động'
        ELSE '✅ Hoạt động tốt'
    END as "Trạng thái"

FROM users u
LEFT JOIN zalo_24h z ON u.id = z.user_id
LEFT JOIN voip_24h v ON u.id = v.user_id
LEFT JOIN tasks_24h t ON u.id = t.user_id

WHERE u.role = 'cvts' AND u.status = 'active'

ORDER BY 
    COALESCE(z.conversations_24h, 0) + 
    COALESCE(v.calls_24h, 0) + 
    COALESCE(t.tasks_created_24h, 0) DESC;