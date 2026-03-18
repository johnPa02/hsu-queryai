-- Query 8: Thống kê các cuộc gọi trong 3 ngày qua? / Đang có tổng cộng bao nhiêu cuộc gọi hotline?

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
    DATE(v.createtime) as "Ngày",
    TO_CHAR(v.createtime, 'Day') as "Thứ",
    COALESCE(em.cvts_name, 'Chưa xác định') as "CVTS",
    u.role as "Vai trò",
    v.extension as "Extension",
    u.area as "Khu vực",
    
    -- Tổng số cuộc gọi
    COUNT(*) as "Số cuộc gọi",
    
    -- Tổng thời lượng
    SUM(v.duration) as "Tổng thời lượng (giây)",
    CASE 
        WHEN SUM(v.duration) >= 3600 THEN 
            FLOOR(SUM(v.duration) / 3600) || ' giờ ' || 
            FLOOR((SUM(v.duration) % 3600) / 60) || ' phút'
        WHEN SUM(v.duration) >= 60 THEN 
            FLOOR(SUM(v.duration) / 60) || ' phút'
        ELSE 
            SUM(v.duration) || ' giây'
    END as "Tổng thời lượng",
    
    -- Thời lượng trung bình
    ROUND(AVG(v.duration)) as "TB thời lượng (giây)",
    
    -- Phân loại theo trạng thái
    COUNT(*) FILTER (WHERE v.call_status = 'answered') as "Đã trả lời",
    COUNT(*) FILTER (WHERE v.call_status = 'missed') as "Nhớ cuộc gọi",
    
    -- Tỷ lệ trả lời
    CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND(COUNT(*) FILTER (WHERE v.call_status = 'answered') * 100.0 / COUNT(*), 2)
        ELSE 0
    END as "Tỷ lệ trả lời (%)"

FROM voip_call_records v

LEFT JOIN extension_mapping em ON v.extension = em.ext
LEFT JOIN users u ON em.cvts_name = u.full_name

GROUP BY DATE(v.createtime), TO_CHAR(v.createtime, 'Day'), em.cvts_name, u.role, v.extension, u.area

ORDER BY DATE(v.createtime) DESC, COUNT(*) DESC;