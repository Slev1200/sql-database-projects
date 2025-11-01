-- 1. Average class size by day of week
SELECT s.day_of_week, ROUND(AVG(COUNT(e.enrollment_id)), 1) AS avg_class_size FROM schedules s
LEFT JOIN class_enrollments e ON s.schedule_id = e.schedule_id
AND e.status IN ('enrolled', 'attended')
GROUP BY s.schedule_id, s.day_of_week
ORDER BY avg_class_size DESC;

-- 2. Total revenue by membership type
SELECT ms.membership_type, ROUND(SUM(t.amount), 2) AS total_revenue FROM transactions t
JOIN member_membership_history mmh ON t.member_id = mmh.member_id
JOIN memberships ms ON mmh.membership_id = ms.membership_id
GROUP BY ms.membership_type
ORDER BY total_revenue DESC;

-- 3. Daily attendance tracking
SELECT strftime('%Y-%m-%d', arrival_datetime) AS date, COUNT(*) AS total_checkins
FROM attendance
GROUP BY date
ORDER BY date DESC;

-- 4. Number of members that sign up at the gym monthly
SELECT strftime('%Y-%m', mmh.start_date) AS month, COUNT(DISTINCT mmh.member_id) AS new_signups 
FROM member_membership_history mmh
GROUP BY month
ORDER BY month;

-- 5. Overall instructor performance by class
SELECT s.staff_id, st.first_name || ' ' || st.last_name AS instructor_name, COUNT(e.enrollment_id) AS total_signups
FROM schedules s
JOIN staff st ON s.staff_id = st.staff_id
LEFT JOIN class_enrollments e ON e.schedule_id = s.schedule_id AND e.status IN ('enrolled', 'attended')
GROUP BY s.staff_id
ORDER BY total_signups DESC;