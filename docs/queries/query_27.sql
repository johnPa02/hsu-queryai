-- Query #27: Thống kê lead theo trạng thái chăm sóc

WITH all_care_statuses(status_code, status_label) AS (
    VALUES 
        ('consulted', 'Đã tư vấn'),
        ('unreachable', 'Không liên lạc được'),
        ('wrong_number', 'Sai số'),
        ('callback_scheduled', 'Hẹn gọi lại sau'),
        ('scholarship_completed', 'Đã xét học bổng'),
        ('registered_admission', 'Đăng ký xét tuyển'),
        ('admission_completed', 'Đã hoàn tất xét tuyển'),
        ('enrolled_no_payment', 'Đã tiếp sinh & chưa nộp học phí'),
        ('enrollment_completed', 'Đã hoàn tất nhập học'),
        ('paid_not_enrolled', 'Đã nộp học phí & chưa tiếp sinh'),
        ('insufficient_funds', 'Không đủ tài chính'),
        ('duplicate_lead', 'Trùng Lead'),
        ('interested_other_products', 'Quan tâm sản phẩm khác'),
        ('definitely_choose_hsu', 'Chắc chắn chọn HSU'),
        ('not_choose_hsu', 'Không chọn HSU'),
        ('study_abroad', 'Du học'),
        ('choose_other_school', 'Chọn trường khác'),
        ('waiting_exam_score', 'Đang chờ điểm thi'),
        ('waiting_admission_letter', 'Chờ giấy báo trúng tuyển'),
        ('thinking_more', 'Suy nghĩ thêm'),
        ('planning_to_register', 'Dự kiến ĐKNV vào HSU'),
        ('confirmed_registered', 'Xác nhận đã ĐKNV vào HSU'),
        ('not_yet_grade_12', 'Chưa học lớp 12')
)
SELECT 
    cs.status_label,
    COUNT(l.id) as total_leads,
    CASE 
        WHEN SUM(COUNT(l.id)) OVER () = 0 THEN 0
        ELSE ROUND(
            COUNT(l.id) * 100.0 / SUM(COUNT(l.id)) OVER (), 
            2
        ) 
    END as percentage
FROM 
    all_care_statuses cs
LEFT JOIN 
    leads l ON cs.status_code = l.care_status AND l.status = 'active'
GROUP BY 
    cs.status_code, cs.status_label
ORDER BY 
    total_leads DESC, -- Ưu tiên hiển thị trạng thái có nhiều lead nhất lên đầu
    cs.status_label ASC; -- Sau đó sắp xếp theo tên