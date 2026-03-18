-- Query 18: Chất lượng chăm sóc Lead qua Hotline của các CVTS

WITH extension_mapping AS (
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
)
SELECT 
    COALESCE(em.cvts_name, 'Chưa xác định') as "CVTS",
    u.area as "Khu vực",
    
    -- Tổng số cuộc gọi
    COUNT(v.id) as "Tổng cuộc gọi",
    
    -- Phân loại theo call status
    COUNT(v.id) FILTER (WHERE v.call_status = 'answered') as "Đã trả lời",
    COUNT(v.id) FILTER (WHERE v.call_status = 'missed') as "Nhớ cuộc gọi",
    COUNT(v.id) FILTER (WHERE v.call_status = 'busy') as "Máy bận",
    COUNT(v.id) FILTER (WHERE v.call_status = 'voicemail') as "Hộp thư",
    
    -- Tỷ lệ trả lời
    ROUND(COUNT(v.id) FILTER (WHERE v.call_status = 'answered') * 100.0 / NULLIF(COUNT(v.id), 0), 2) as "Tỷ lệ TL (%)",
    
    -- Thời lượng cuộc gọi
    SUM(v.duration) FILTER (WHERE v.call_status = 'answered') as "Tổng TL (s)",
    ROUND(AVG(v.duration) FILTER (WHERE v.call_status = 'answered')) as "TB TL (s)",
    
    -- AI Analysis (chỉ cho cuộc gọi answered có ai_summary)
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary' IS NOT NULL) as "Có AI Analysis",
    
    -- Sentiment distribution
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'sentiment' = 'positive') as "😊 Positive",
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'sentiment' = 'neutral') as "😐 Neutral",
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'sentiment' = 'negative') as "😞 Negative",
    
    -- Customer Intent distribution
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'customer_intent' = 'đăng ký ngay') as "🎯 Đăng ký ngay",
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'customer_intent' = 'quan tâm đăng ký') as "✅ Quan tâm ĐK",
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'customer_intent' = 'cân nhắc') as "🤔 Cân nhắc",
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'customer_intent' = 'chỉ hỏi thông tin') as "ℹ️ Hỏi thông tin",
    COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'customer_intent' = 'từ chối') as "❌ Từ chối",
    
    -- Đánh giá chất lượng
    CASE 
        WHEN COUNT(v.id) FILTER (WHERE v.call_status = 'answered') * 100.0 / NULLIF(COUNT(v.id), 0) >= 70 
            AND COUNT(v.id) FILTER (WHERE v.analysis->'ai_summary'->>'sentiment' = 'positive') * 100.0 / NULLIF(COUNT(v.id) FILTER (WHERE v.call_status = 'answered'), 0) >= 60
        THEN '🏆 Xuất sắc'
        WHEN COUNT(v.id) FILTER (WHERE v.call_status = 'answered') * 100.0 / NULLIF(COUNT(v.id), 0) >= 50 
        THEN '✅ Tốt'
        WHEN COUNT(v.id) FILTER (WHERE v.call_status = 'answered') * 100.0 / NULLIF(COUNT(v.id), 0) >= 30 
        THEN '⚠️ Trung bình'
        ELSE '🔴 Cần cải thiện'
    END as "Đánh giá"

FROM voip_call_records v

LEFT JOIN extension_mapping em ON v.extension = em.ext
LEFT JOIN users u ON em.cvts_name = u.full_name

WHERE u.role = 'cvts' 
    AND u.status = 'active'

GROUP BY em.cvts_name, u.area

ORDER BY COUNT(v.id) FILTER (WHERE v.call_status = 'answered') DESC;