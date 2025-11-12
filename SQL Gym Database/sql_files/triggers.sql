-- Closes a previous membership when that same member signs up for a new membership
DROP TRIGGER IF EXISTS close_previous_membership;

CREATE TRIGGER IF NOT EXISTS close_previous_membership BEFORE INSERT ON member_membership_history FOR EACH ROW BEGIN UPDATE member_membership_history SET end_date = DATE(NEW.start_date, '+1 day') WHERE member_id = NEW.member_id AND (end_date IS NULL OR end_date > NEW.start_date); 
END;

-- Prevents overbooking if class is already fully enrolled
DROP TRIGGER IF EXISTS prevent_overbooking;

CREATE TRIGGER IF NOT EXISTS prevent_overbooking BEFORE INSERT ON class_enrollments FOR EACH ROW BEGIN SELECT CASE WHEN ((SELECT COUNT(*) FROM class_enrollments ce WHERE ce.schedule_id = NEW.schedule_id AND ce.status IN ('enrolled', 'attended')) >= (SELECT c.capacity FROM schedules s JOIN classes c ON c.class_id = s.class_id WHERE s.schedule_id = NEW.schedule_id)) THEN RAISE(ABORT, 'Class is at capacity, please sign up for another class or come back another day') END; 
END;

DROP TRIGGER IF EXISTS mem_start_after_member_joins;

CREATE TRIGGER mem_start_after_member_joins
BEFORE INSERT ON member_membership_history
FOR EACH ROW
BEGIN
  -- ensure member exists (FK should already do this), and compare dates
  SELECT
    CASE
      WHEN (SELECT join_date
            FROM members
            WHERE member_id = NEW.member_id) IS NULL
        THEN RAISE(ABORT, 'Member not found')
      WHEN NEW.start_date <
           (SELECT join_date
            FROM members
            WHERE member_id = NEW.member_id)
        THEN RAISE(ABORT, 'Membership start_date cannot be before member join_date')
    END;
END;

DROP TRIGGER IF EXISTS mmh_start_after_join_upd;

CREATE TRIGGER mem_start_after_join_upd
BEFORE UPDATE OF member_id, start_date ON member_membership_history
FOR EACH ROW
BEGIN
  SELECT
    CASE
      WHEN (SELECT join_date
            FROM members
            WHERE member_id = NEW.member_id) IS NULL
        THEN RAISE(ABORT, 'Member not found')
      WHEN NEW.start_date <
           (SELECT join_date
            FROM members
            WHERE member_id = NEW.member_id)
        THEN RAISE(ABORT, 'Membership start_date cannot be before member join_date')
    END;
END;


-- Automatically inserts the correct data for classes and schedules when a member enrolls into a class
DROP TRIGGER IF EXISTS register_member_for_class;

CREATE TRIGGER register_member_for_class
INSTEAD OF INSERT ON register_request
FOR EACH ROW
BEGIN
    INSERT INTO class_enrollments (member_id, schedule_id, status)
    SELECT
        m.member_id,
        s.schedule_id,
        COALESCE(NEW.status, 'enrolled')
    FROM members m
    JOIN classes c
        ON c.class_name = NEW.class_name
    JOIN schedules s
        ON s.class_id = c.class_id
       AND s.day_of_week = NEW.day_of_week
       AND s.start_time = NEW.start_time
    WHERE m.first_name = NEW.first_name
      AND m.last_name  = NEW.last_name;
END;

DROP TRIGGER IF EXISTS cancel_member_from_class;

CREATE TRIGGER cancel_member_from_class
INSTEAD OF DELETE ON class_registrations
FOR EACH ROW
BEGIN
    DELETE FROM class_enrollments
    WHERE EXISTS (
        SELECT 1
        FROM members AS m
        JOIN classes AS c
          ON c.class_name = OLD.class_name
        JOIN schedules AS s
          ON s.class_id = c.class_id
         AND s.day_of_week = OLD.day_of_week
         AND s.start_time = OLD.start_time
        WHERE m.member_id = class_enrollments.member_id
          AND s.schedule_id = class_enrollments.schedule_id
          AND m.first_name = OLD.first_name
          AND m.last_name = OLD.last_name
    );
END;
