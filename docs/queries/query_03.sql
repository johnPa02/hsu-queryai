-- Query 3: Có bao nhiêu lead đã cọc tiền xét học bổng?

SELECT 
    l.full_name as "Họ và tên",
    l.phone as "Số điện thoại",
    l.city as "Tỉnh/Thành phố",
    l.area as "Khu vực",
    COALESCE(s.name, l.previous_education) as "Trường THPT",
    l.stage as "Trạng thái hiện tại",
    
    -- Ưu tiên lấy từ history, nếu không có thì dùng updated_at
    COALESCE(lsh.changed_at, l.updated_at) as "Thời gian cọc tiền học bổng",
    
    u.full_name as "CVTS phụ trách"

FROM leads l

LEFT JOIN schools s ON l.school_id = s.id
LEFT JOIN users u ON l.assigned_to = u.id

LEFT JOIN LATERAL (
    SELECT changed_at
    FROM lead_stage_history
    WHERE lead_id = l.id
        AND to_stage = 'scholarship_deposited'
    ORDER BY changed_at DESC
    LIMIT 1
) lsh ON true

WHERE l.is_scholarship_deposited = true
    AND l.status = 'active'

ORDER BY 
    CASE 
        WHEN l.area = 'DNB & HCM' THEN 1
        WHEN l.area = 'TNB & HCM' THEN 2
        ELSE 3
    END,
    COALESCE(lsh.changed_at, l.updated_at) DESC NULLS LAST;