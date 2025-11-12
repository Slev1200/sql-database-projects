SELECT m.first_name, m.last_name, ms.membership_type, h.start_date
FROM member_membership_history h
JOIN members m ON m.member_id = h.member_id
JOIN memberships ms ON ms.membership_id = h.membership_id
WHERE h.member_id = :mid
  AND h.membership_id = :msid
ORDER BY h.history_id DESC
LIMIT 1;
