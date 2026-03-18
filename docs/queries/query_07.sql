-- Query 7: Các chủ đề mà lead hay quan tâm khi chat?

SELECT 
    g->>'name' as group_topic_name,
    (g->>'percentage')::numeric as percentage,
    (g->>'count')::int as topic_count,
    (g->>'occurrences')::int as occurrences,
    g->>'description' as description,
    g->'topics' as topics
FROM 
    zalo_ai_analysis_recap r,
    jsonb_array_elements(r.analysis->'groups') as g
ORDER BY 
    r.created_at DESC,
    (g->>'percentage')::numeric DESC;