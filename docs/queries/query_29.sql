-- Query #29: Phân bố lead theo từng tỉnh / thành phố

SELECT 
    -- Ưu tiên lấy tên chuẩn từ bảng danh mục, nếu không có thì lấy cột city cũ, nếu null thì báo "Chưa cập nhật"
    COALESCE(p.province_name, l.city, 'Chưa cập nhật') AS province_name,
    
    -- Số lượng lead
    COUNT(l.id) AS total_leads,
    
    -- Tỷ lệ phần trăm
    ROUND(
        COUNT(l.id) * 100.0 / SUM(COUNT(l.id)) OVER (), 
        2
    ) AS percentage

FROM 
    leads l
LEFT JOIN (
    -- Subquery để lấy danh mục tỉnh thành duy nhất (tránh bị nhân đôi do bản ghi theo năm)
    SELECT DISTINCT province_code, province_name 
    FROM province_data
) p ON l.province_code = p.province_code

WHERE 
    l.status = 'active' -- Chỉ lấy lead đang hoạt động

GROUP BY 
    COALESCE(p.province_name, l.city, 'Chưa cập nhật')

ORDER BY 
    total_leads DESC; -- Tỉnh nào đông nhất đưa lên đầu