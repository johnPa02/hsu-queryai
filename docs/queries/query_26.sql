-- Query #26: Có bao nhiêu lead mới hôm nay / tuần qua / tháng qua / 2 ngày qua / 3 ngày / 2 tuần qua ...? 

SELECT

    COUNT(CASE WHEN created_at >= CURRENT_DATE THEN 1 END) as today,

    COUNT(CASE WHEN created_at >= date_trunc('week', CURRENT_DATE) THEN 1 END) as this_week,
    COUNT(CASE WHEN created_at >= date_trunc('month', CURRENT_DATE) THEN 1 END) as this_month,
    COUNT(CASE WHEN created_at >= date_trunc('year', CURRENT_DATE) THEN 1 END) as this_year,


    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '2 days' THEN 1 END) as last_2_days,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '3 days' THEN 1 END) as last_3_days,

 
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '2 weeks' THEN 1 END) as last_2_weeks,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '3 weeks' THEN 1 END) as last_3_weeks,
    

    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '2 months' THEN 1 END) as last_2_months,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '3 months' THEN 1 END) as last_3_months

FROM 
    leads
WHERE 
    status = 'active';
