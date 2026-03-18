-- Query 9: Các chủ đề mà lead hay gọi hotline để hỏi?

WITH call_topics AS (
    SELECT 
        v.dst as phone,
        v.createtime,
        v.duration,
        v.analysis->'ai_summary'->>'summary' as summary,
        v.analysis->'ai_summary'->>'sentiment' as sentiment,
        v.analysis->'ai_summary'->>'customer_intent' as customer_intent,
        -- Unnest main_topics array
        jsonb_array_elements_text(v.analysis->'ai_summary'->'main_topics') as topic
    FROM voip_call_records v
    WHERE v.call_status = 'answered'  -- Chỉ lấy cuộc gọi đã trả lời
        AND v.analysis IS NOT NULL
        AND v.analysis->'ai_summary'->'main_topics' IS NOT NULL
)
SELECT 
    topic as "Chủ đề",
    COUNT(*) as "Số lần xuất hiện",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as "Tỷ lệ (%)",
    COUNT(DISTINCT phone) as "Số lead khác nhau",
    ROUND(AVG(duration)) as "Thời lượng TB (giây)"
FROM call_topics
GROUP BY topic
ORDER BY COUNT(*) DESC;