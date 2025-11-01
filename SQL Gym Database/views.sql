/* class_utilization(class_name,day_of_week,start_time,enrolled_count,class_capacity,utilization_percent) */;
CREATE VIEW IF NOT EXISTS class_utilization AS 
SELECT c.class_name, s.day_of_week, s.start_time, COUNT(e.enrollment_id) AS count_enrolled, c.capacity AS class_capacity, ROUND(100.0 * COUNT(e.enrollment_id) / c.capacity, 1) AS percent_utilized FROM schedules s JOIN classes c ON s.class_id = c.class_id LEFT JOIN class_enrollments e ON e.schedule_id = s.schedule_id AND e.status IN ('enrolled', 'attended') GROUP BY s.schedule_id ORDER BY percent_utilized DESC

/* monthly_revenue(date,transaction_type,revenue_in_month) */;
CREATE VIEW IF NOT EXISTS monthly_revenue AS 
SELECT strftime('%Y-%m', transaction_date) AS date, transaction_type, SUM(amount) AS monthly_revenue FROM transactions GROUP BY date, transaction_type ORDER BY date, transaction_type

/* active_memberships(member_id,first_name,last_name,membership_type,start_date,end_date) */;
CREATE VIEW IF NOT EXISTS active_memberships AS 
SELECT m.member_id, m.first_name, m.last_name, ms.membership_type, mmh.start_date, mmh.end_date FROM members m JOIN member_membership_history mmh ON m.member_id = mmh.member_id JOIN memberships ms ON mmh.membership_id = ms.membership_id WHERE mmh.end_date IS NULL OR mmh.end_date >= DATE('now')

/* member_activity_30d(member_id,first_name,last_name,checkins_last_15_days) */;
CREATE VIEW IF NOT EXISTS member_activity_30d AS 
SELECT m.member_id, m.first_name, m.last_name, COUNT(a.attendance_id) AS checkins_last_15_days FROM members m LEFT JOIN attendance a ON a.member_id = m.member_id AND a.arrival_datetime >= DATE('now', '-15 days') GROUP BY m.member_id ORDER BY checkins_last_15_days DESC