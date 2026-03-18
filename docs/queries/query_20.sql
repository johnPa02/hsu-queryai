-- Query #20: Đang có bao nhiêu hội thoại hoạt động?

WITH cvts_stats AS (
    SELECT 
        u.full_name as cvts_name,
        u.area,
        COUNT(zc.id) as active_conversation_count,
        MAX(zc.last_message_at) as last_message_at
    FROM users u
    LEFT JOIN zalo_conversations zc 
        ON u.id = zc.user_id
    WHERE u.role = 'cvts'
        AND u.status = 'active'
    GROUP BY u.full_name, u.area
    HAVING COUNT(zc.id) > 0  -- Bỏ các CVTS không có conversation nào
),
all_results AS (
    SELECT 
        'TỔNG' as cvts_name,
        NULL as area,
        SUM(active_conversation_count) as active_conversation_count,
        MAX(last_message_at) as last_message_at,
        0 as sort_order
    FROM cvts_stats

    UNION ALL

    SELECT 
        cvts_name,
        area,
        active_conversation_count,
        last_message_at,
        1 as sort_order
    FROM cvts_stats
)
SELECT 
    cvts_name,
    area,
    active_conversation_count,
    last_message_at
FROM all_results
ORDER BY sort_order, active_conversation_count DESC;
