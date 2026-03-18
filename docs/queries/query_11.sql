-- Query 11: Tính từ 1/1 đến giờ, cho thống kê nội dung các cuộc hội thoại

WITH zalo_topics AS (
    SELECT 
        u.full_name as cvts_name,
        u.area,
        unnest(za.topics) as topic
    FROM zalo_ai_analysis za
    INNER JOIN zalo_conversations zc ON za.zalo_conversation_id = zc.id
    LEFT JOIN users u ON zc.user_id = u.id
    WHERE zc.created_at >= '2025-01-01'
        AND za.topics IS NOT NULL
        AND array_length(za.topics, 1) > 0
),
topic_stats AS (
    SELECT 
        cvts_name,
        area,
        topic,
        COUNT(*) as count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY cvts_name), 2) as percentage,
        ROW_NUMBER() OVER(PARTITION BY cvts_name ORDER BY COUNT(*) DESC) as rank
    FROM zalo_topics
    GROUP BY cvts_name, area, topic
)
SELECT 
    cvts_name as "CVTS",
    area as "Khu vực",
    topic as "Chủ đề",
    count as "Số lần"
FROM topic_stats
WHERE rank <= 5
ORDER BY cvts_name, rank;