-- Closes a previous membership when that same member signs up for a new membership
CREATE TRIGGER IF NOT EXISTS close_previous_membership BEFORE INSERT ON member_membership_history FOR EACH ROW BEGIN UPDATE member_membership_history SET end_date = DATE(NEW.start_date, '-1 day') WHERE member_id = NEW.member_id AND (end_date IS NULL OR end_date > NEW.start_date); 
END;

-- Prevents overbooking if class is already fully enrolled
CREATE TRIGGER IF NOT EXISTS prevent_overbooking BEFORE INSERT ON class_enrollments FOR EACH ROW BEGIN SELECT CASE WHEN ((SELECT COUNT(*) FROM class_enrollments ce WHERE ce.schedule_id = NEW.schedule_id AND ce.status IN ('enrolled', 'attended')) >= (SELECT c.capacity FROM schedules s JOIN classes c ON c.class_id = s.class_id WHERE s.schedule_id = NEW.schedule_id)) THEN RAISE(ABORT, 'Class is at capacity, please sign up for another class or come back another day') END; 
END;