-- Query 10: Nội dung của các cuộc hội thoại trong 1 tuần qua, các bạn quan tâm điều gì?

WITH zalo_topics AS (
    SELECT 
        za.zalo_conversation_id,
        za.sentiment,
        za.quality_grade,
        za.quality_score,
        unnest(za.topics) as topic
    FROM zalo_ai_analysis za
    WHERE za.topics IS NOT NULL
        AND array_length(za.topics, 1) > 0
)
SELECT 
    topic as "Chủ đề",
    COUNT(*) as "Số lần xuất hiện",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as "Tỷ lệ (%)",
    COUNT(DISTINCT zalo_conversation_id) as "Số cuộc hội thoại"

FROM zalo_topics
GROUP BY topic
ORDER BY COUNT(*) DESC
LIMIT 20;