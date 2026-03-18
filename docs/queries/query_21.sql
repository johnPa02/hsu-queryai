-- Query #21: Tình hình tuyển sinh tuần qua có gì?

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
-- 1. Thống kê Zalo conversations (7 ngày qua)
zalo_stats AS (
    SELECT 
        u.id as user_id,
        u.full_name,
        COUNT(DISTINCT zc.id) as total_zalo_conversations,
        ROUND(AVG(za.quality_score)) as avg_quality_score
    FROM users u
    LEFT JOIN zalo_conversations zc ON u.id = zc.user_id 
        AND zc.created_at >= NOW() - INTERVAL '7 days'
    LEFT JOIN zalo_ai_analysis za ON zc.id = za.zalo_conversation_id
    WHERE u.role IN ('cvts')
        AND u.status = 'active'
    GROUP BY u.id, u.full_name
),
-- 2. Top 3 topics của mỗi CVTS (7 ngày qua)
top_topics_raw AS (
    SELECT 
        zc.user_id,
        unnest(za.topics) as topic,
        COUNT(*) as topic_count
    FROM zalo_conversations zc
    INNER JOIN zalo_ai_analysis za ON zc.id = za.zalo_conversation_id
    WHERE za.topics IS NOT NULL
        AND array_length(za.topics, 1) > 0
        AND zc.created_at >= NOW() - INTERVAL '7 days'
    GROUP BY zc.user_id, unnest(za.topics)
),
top_topics_ranked AS (
    SELECT 
        user_id,
        topic,
        topic_count,
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY topic_count DESC) as rank
    FROM top_topics_raw
),
top_topics AS (
    SELECT 
        user_id,
        array_agg(topic ORDER BY rank) as top_3_topics
    FROM top_topics_ranked
    WHERE rank <= 3
    GROUP BY user_id
),
-- 3. Thống kê VoIP calls (7 ngày qua)
voip_stats AS (
    SELECT 
        u.id as user_id,
        COUNT(v.id) as total_calls,
        SUM(v.duration) as total_call_duration,
        ROUND(AVG(v.duration)) as avg_call_duration
    FROM users u
    LEFT JOIN extension_mapping em ON u.full_name = em.cvts_name
    LEFT JOIN voip_call_records v ON em.ext = v.extension 
        AND v.createtime >= NOW() - INTERVAL '7 days'
    WHERE u.role IN ('cvts')
        AND u.status = 'active'
    GROUP BY u.id
),
-- 4. Thống kê Tasks (7 ngày qua)
task_stats AS (
    SELECT 
        u.id as user_id,
        COUNT(t.id) as total_tasks,
        COUNT(t.id) FILTER (WHERE t.completed = true) as completed_tasks,
        COUNT(t.id) FILTER (WHERE t.completed = false AND t.due_date < NOW()) as overdue_tasks
    FROM users u
    LEFT JOIN tasks t ON u.id = t.assigned_to 
        AND t.created_at >= NOW() - INTERVAL '7 days'
    WHERE u.role IN ('cvts')
        AND u.status = 'active'
    GROUP BY u.id
)
-- Kết hợp tất cả
SELECT 
    u.full_name as "CVTS",
    u.role as "Vai trò",
    u.area as "Khu vực",
    
    -- Zalo
    COALESCE(zs.total_zalo_conversations, 0) as "Tổng hội thoại",
    COALESCE(zs.avg_quality_score, 0) as "Trung bình Quality Score",
    COALESCE(array_to_string(tt.top_3_topics, ', '), 'N/A') as "Top 3 Topics",
    
    -- VoIP
    COALESCE(vs.total_calls, 0) as "Tổng cuộc gọi",
    COALESCE(vs.total_call_duration, 0) as "Tổng TL gọi (s)",
    COALESCE(vs.avg_call_duration, 0) as "TB TL gọi (s)",
    
    -- Tasks
    COALESCE(ts.total_tasks, 0) as "Tổng tasks",
    COALESCE(ts.completed_tasks, 0) as "Tasks hoàn thành",
    COALESCE(ts.overdue_tasks, 0) as "Tasks quá hạn"

FROM users u
LEFT JOIN zalo_stats zs ON u.id = zs.user_id
LEFT JOIN top_topics tt ON u.id = tt.user_id
LEFT JOIN voip_stats vs ON u.id = vs.user_id
LEFT JOIN task_stats ts ON u.id = ts.user_id

WHERE u.role IN ('cvts')
    AND u.status = 'active'

ORDER BY COALESCE(zs.total_zalo_conversations, 0) DESC;
