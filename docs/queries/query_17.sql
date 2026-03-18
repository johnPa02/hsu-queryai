-- Query 17: Chất lượng chăm sóc Lead qua Hội thoại của CVTS

WITH quality_stats AS (
    SELECT 
        u.id,
        u.full_name,
        u.area,
        COUNT(za.id) as total_conversations,
        ROUND(AVG(za.quality_score)) as avg_quality_score,
        ROUND(AVG((za.quality_breakdown->>'messageQuality')::numeric)) as avg_msg_quality,
        ROUND(AVG((za.quality_breakdown->>'leadEngagement')::numeric)) as avg_engagement,
        ROUND(AVG((za.quality_breakdown->>'conversionIndicators')::numeric)) as avg_conversion,
        COUNT(za.id) FILTER (WHERE za.quality_grade IN ('A', 'B')) as high_quality_count,
        COUNT(za.id) FILTER (WHERE 'NO_LEAD_RESPONSE' = ANY(za.quality_flags)) as no_response_count,
        
        -- Hội thoại 2 chiều (lead có phản hồi)
        COUNT(za.id) FILTER (WHERE NOT ('NO_LEAD_RESPONSE' = ANY(za.quality_flags))) as two_way_conversations,
        
        -- Hội thoại 1 chiều (lead không phản hồi)
        COUNT(za.id) FILTER (WHERE 'NO_LEAD_RESPONSE' = ANY(za.quality_flags)) as one_way_conversations,
        
        -- Tỷ lệ hội thoại 2 chiều
        CASE 
            WHEN COUNT(za.id) > 0 THEN 
                ROUND((COUNT(za.id) FILTER (WHERE NOT ('NO_LEAD_RESPONSE' = ANY(za.quality_flags)))::numeric / COUNT(za.id)::numeric) * 100)
            ELSE 0
        END as two_way_ratio
        
    FROM users u
    LEFT JOIN zalo_conversations zc ON u.id = zc.user_id
    LEFT JOIN zalo_ai_analysis za ON zc.id = za.zalo_conversation_id
    WHERE u.role = 'cvts' AND u.status = 'active'
    GROUP BY u.id, u.full_name, u.area
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY avg_quality_score DESC NULLS LAST) as "Rank",
    full_name as "CVTS",
    area as "Khu vực",
    total_conversations as "Tổng HT",
    two_way_conversations as "HT 2 chiều",
    one_way_conversations as "HT 1 chiều",
    two_way_ratio || '%' as "Tỷ lệ 2 chiều",
    avg_quality_score as "TB Quality",
    
    -- Đánh giá tổng thể
    CASE 
        WHEN avg_quality_score >= 70 THEN '🏆 Xuất sắc'
        WHEN avg_quality_score >= 50 THEN '✅ Tốt'
        WHEN avg_quality_score >= 30 THEN '⚠️ Trung bình'
        ELSE '🔴 Cần cải thiện'
    END as "Đánh giá"

FROM quality_stats

ORDER BY avg_quality_score DESC NULLS LAST;