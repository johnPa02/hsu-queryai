-- Query #30: Tỷ lệ chuyển đổi lead?

WITH stats AS (
    SELECT
        -- Mẫu số: Tổng lead được TẠO MỚI trong kỳ
        COUNT(CASE WHEN date_trunc('week', created_at) = date_trunc('week', CURRENT_DATE) THEN 1 END) as created_week,
        COUNT(CASE WHEN date_trunc('month', created_at) = date_trunc('month', CURRENT_DATE) THEN 1 END) as created_month,
        COUNT(CASE WHEN date_trunc('year', created_at) = date_trunc('year', CURRENT_DATE) THEN 1 END) as created_year,

        -- Tử số: Số lead ĐÃ NHẬP HỌC (Enrolled) trong kỳ (dựa vào created_at)
        COUNT(CASE WHEN date_trunc('week', created_at) = date_trunc('week', CURRENT_DATE) AND stage = 'enrolled' THEN 1 END) as enrolled_week,
        COUNT(CASE WHEN date_trunc('month', created_at) = date_trunc('month', CURRENT_DATE) AND stage = 'enrolled' THEN 1 END) as enrolled_month,
        COUNT(CASE WHEN date_trunc('year', created_at) = date_trunc('year', CURRENT_DATE) AND stage = 'enrolled' THEN 1 END) as enrolled_year
    FROM leads
    WHERE status = 'active'
),
summary AS (
    SELECT 
        '=== TỶ LỆ CHUYỂN ĐỔI ===' AS "Họ Tên",
        
        -- Hiển thị Tỷ lệ Tuần vào cột SĐT (Thay thế vị trí Giới Tính cũ)
        format('Tuần: %s%% (%s/%s)', 
            CASE WHEN created_week > 0 THEN ROUND((enrolled_week::numeric / created_week) * 100, 2) ELSE 0 END,
            enrolled_week, created_week
        ) AS "SĐT",
        
        -- Hiển thị Tỷ lệ Tháng
        format('Tháng: %s%% (%s/%s)', 
             CASE WHEN created_month > 0 THEN ROUND((enrolled_month::numeric / created_month) * 100, 2) ELSE 0 END,
             enrolled_month, created_month
        ) AS "Ghi Chú Chi Tiết",
        
        -- Hiển thị Tỷ lệ Năm
        format('Năm: %s%% (%s/%s)', 
             CASE WHEN created_year > 0 THEN ROUND((enrolled_year::numeric / created_year) * 100, 2) ELSE 0 END,
             enrolled_year, created_year
        ) AS "Ngày Tạo Lead",
        
        NULL AS "Ngày Nhập Học",
        NULL AS "Người Phụ Trách",
        0 AS sort_order,
        NULL::timestamp AS sort_date
    FROM stats
),
details AS (
    SELECT 
        l.full_name AS "Họ Tên",
        l.phone AS "SĐT", -- Lấy SĐT
        l.notes AS "Ghi Chú Chi Tiết",
        to_char(l.created_at, 'DD/MM/YYYY HH24:MI') AS "Ngày Tạo Lead",
        
        -- Lấy ngày nhập học
        to_char(COALESCE(MAX(h.changed_at), l.updated_at), 'DD/MM/YYYY HH24:MI') AS "Ngày Nhập Học",
        
        u.full_name AS "Người Phụ Trách",
        1 AS sort_order,
        COALESCE(MAX(h.changed_at), l.updated_at) AS sort_date
    FROM 
        leads l
    LEFT JOIN 
        lead_stage_history h ON l.id = h.lead_id AND h.to_stage = 'enrolled'
    LEFT JOIN 
        users u ON l.assigned_to = u.id
    WHERE 
        l.stage = 'enrolled' 
        AND l.status = 'active'
    GROUP BY 
        l.id, l.full_name, l.phone, l.notes, l.created_at, l.updated_at, u.full_name
)
-- FINAL QUERY
SELECT 
    "Họ Tên", 
    "SĐT", 
    "Ghi Chú Chi Tiết", 
    "Ngày Tạo Lead", 
    "Ngày Nhập Học", 
    "Người Phụ Trách"
FROM (
    SELECT * FROM summary
    UNION ALL
    SELECT * FROM details
) combined_data
ORDER BY 
    sort_order ASC,
    sort_date DESC;