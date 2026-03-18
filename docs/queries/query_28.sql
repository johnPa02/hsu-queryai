-- Query #28: Tỷ lệ huỷ nhập học của học sinh

WITH stats AS (
    SELECT
        -- Mẫu số: Tổng lead được TẠO MỚI trong kỳ
        COUNT(CASE WHEN date_trunc('week', created_at) = date_trunc('week', CURRENT_DATE) THEN 1 END) as created_week,
        COUNT(CASE WHEN date_trunc('month', created_at) = date_trunc('month', CURRENT_DATE) THEN 1 END) as created_month,
        COUNT(CASE WHEN date_trunc('year', created_at) = date_trunc('year', CURRENT_DATE) THEN 1 END) as created_year,

        -- Tử số: Số lead bị HUỶ trong kỳ
        COUNT(CASE WHEN date_trunc('week', updated_at) = date_trunc('week', CURRENT_DATE) AND stage = 'enrollment_cancelled' THEN 1 END) as cancelled_week,
        COUNT(CASE WHEN date_trunc('month', updated_at) = date_trunc('month', CURRENT_DATE) AND stage = 'enrollment_cancelled' THEN 1 END) as cancelled_month,
        COUNT(CASE WHEN date_trunc('year', updated_at) = date_trunc('year', CURRENT_DATE) AND stage = 'enrollment_cancelled' THEN 1 END) as cancelled_year
    FROM leads
    WHERE status = 'active'
),
details AS (
    SELECT 
        l.full_name AS "Họ Tên",
        l.gender AS "Giới Tính",
        l.notes AS "Ghi Chú Chi Tiết",
        to_char(l.created_at, 'DD/MM/YYYY HH24:MI') AS "Ngày Tạo Lead",
        to_char(COALESCE(MAX(h.changed_at), l.updated_at), 'DD/MM/YYYY HH24:MI') AS "Ngày Lead Huỷ",
        u.full_name AS "Người Phụ Trách",
        l.interested_program AS "Ngành Quan Tâm", -- Đã thêm lại cột này
        1 AS sort_order,                          -- Đã thêm lại cột này
        COALESCE(MAX(h.changed_at), l.updated_at) AS sort_date -- Đã thêm lại cột này
    FROM 
        leads l
    LEFT JOIN 
        lead_stage_history h ON l.id = h.lead_id AND h.to_stage = 'enrollment_cancelled'
    LEFT JOIN 
        users u ON l.assigned_to = u.id
    WHERE 
        l.stage = 'enrollment_cancelled' 
        AND l.status = 'active'
    GROUP BY 
        l.id, l.full_name, l.phone, l.gender, l.care_status, 
        l.notes, l.created_at, l.updated_at, 
        u.full_name, l.interested_program
),
summary AS (
    SELECT 
        '=== THỐNG KÊ HUỶ ===' AS "Họ Tên",
        
        -- Hiển thị Tỷ lệ Tuần
        format('Tuần: %s%% (%s huỷ / %s mới)', 
            CASE WHEN created_week > 0 THEN ROUND((cancelled_week::numeric / created_week) * 100, 2) ELSE 0 END,
            cancelled_week, created_week
        ) AS "Giới Tính",
        
        -- Hiển thị Tỷ lệ Tháng
        format('Tháng: %s%% (%s huỷ / %s mới)', 
             CASE WHEN created_month > 0 THEN ROUND((cancelled_month::numeric / created_month) * 100, 2) ELSE 0 END,
             cancelled_month, created_month
        ) AS "Ghi Chú Chi Tiết",
        
        -- Hiển thị Tỷ lệ Năm
        format('Năm: %s%% (%s huỷ / %s mới)', 
             CASE WHEN created_year > 0 THEN ROUND((cancelled_year::numeric / created_year) * 100, 2) ELSE 0 END,
             cancelled_year, created_year
        ) AS "Ngày Tạo Lead",
        
        NULL AS "Ngày Lead Huỷ",
        NULL AS "Người Phụ Trách",
        NULL AS "Ngành Quan Tâm", -- Cột này phải có để khớp với details
        0 AS sort_order,
        NULL::timestamp AS sort_date
    FROM stats
)
-- FINAL QUERY
SELECT 
    "Họ Tên", 
    "Giới Tính", 
    "Ghi Chú Chi Tiết", 
    "Ngày Tạo Lead", 
    "Ngày Lead Huỷ", 
    "Người Phụ Trách"
FROM (
    SELECT * FROM details
    UNION ALL
    SELECT * FROM summary
) combined_data