DROP TABLE IF EXISTS members;
CREATE TABLE members (
    member_id      INTEGER PRIMARY KEY,
    first_name     TEXT NOT NULL,
    last_name      TEXT NOT NULL,
    date_of_birth  DATE,
    gender         TEXT,
    email          TEXT NOT NULL UNIQUE,
    phone_number   TEXT,
    address        TEXT,
    join_date      DATE NOT NULL DEFAULT (DATE('now')),
    status         TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'frozen', 'cancelled')),
    current_payment_type   TEXT NOT NULL DEFAULT 'Card' CHECK (current_payment_type IN ('Cash', 'Card', 'Bank'))
);

DROP TABLE IF EXISTS memberships;
CREATE TABLE memberships (
    membership_id    INTEGER PRIMARY KEY,
    membership_type  TEXT NOT NULL,   -- e.g. "Standard Monthly", "Premium Annual"
    duration_days    INTEGER NOT NULL CHECK (duration_days > 0),
    price            REAL NOT NULL CHECK (price >= 0.0)
);

DROP TABLE IF EXISTS member_membership_history;
CREATE TABLE member_membership_history (
    history_id      INTEGER PRIMARY KEY,
    member_id       INTEGER NOT NULL,
    membership_id   INTEGER NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE CHECK (end_date IS NULL OR end_date >= start_date),
    
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    
    FOREIGN KEY (membership_id) REFERENCES memberships(membership_id) ON DELETE RESTRICT
);

DROP TABLE IF EXISTS staff;
CREATE TABLE staff (
    staff_id     INTEGER PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    role         TEXT NOT NULL,    -- e.g. "trainer", "front_desk", "manager", "instructor"
    hire_date    DATE NOT NULL DEFAULT (DATE('now')),
    phone_number TEXT,
    email        TEXT NOT NULL UNIQUE,
    status       TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'terminated'))
);

DROP TABLE IF EXISTS rooms;
CREATE TABLE rooms (
    room_id     INTEGER PRIMARY KEY,
    room_name   TEXT NOT NULL,     -- e.g. "Spin Studio A"
    capacity    INTEGER NOT NULL CHECK (capacity > 0)
);

DROP TABLE IF EXISTS classes;
CREATE TABLE classes (
    class_id      INTEGER PRIMARY KEY,
    class_name    TEXT NOT NULL,
    description   TEXT,
    capacity      INTEGER NOT NULL CHECK (capacity > 0)
);

DROP TABLE IF EXISTS schedules;
CREATE TABLE schedules (
    schedule_id   INTEGER PRIMARY KEY,
    class_id      INTEGER NOT NULL,
    staff_id      INTEGER NOT NULL,   -- instructor / trainer running it
    room_id       INTEGER NOT NULL,
    day_of_week   TEXT NOT NULL CHECK (day_of_week IN ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')),
    start_time    TEXT NOT NULL,
    end_time      TEXT NOT NULL CHECK (end_time > start_time),
    
    FOREIGN KEY (class_id) REFERENCES classes(class_id) ON DELETE CASCADE,

    FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE RESTRICT,

    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE RESTRICT
);

DROP TABLE IF EXISTS class_enrollments;
CREATE TABLE class_enrollments (
    enrollment_id    INTEGER PRIMARY KEY,
    member_id        INTEGER NOT NULL,
    schedule_id      INTEGER NOT NULL,
    enrollment_date  DATE NOT NULL DEFAULT (DATE('now')),
    status           TEXT NOT NULL DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'cancelled', 'attended', 'no_show')),

    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    
    FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS attendance;
CREATE TABLE attendance (
    attendance_id        INTEGER PRIMARY KEY,
    member_id            INTEGER NOT NULL,
    arrival_datetime     NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,  -- 'YYYY-MM-DD HH:MM:SS'
    departure_datetime   NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (departure_datetime >= arrival_datetime),
    
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    transaction_id    INTEGER PRIMARY KEY,
    member_id         INTEGER NOT NULL,
    amount            REAL NOT NULL CHECK (amount >= 0.0),
    transaction_date  DATE NOT NULL DEFAULT (DATE('now')),
    transaction_type  TEXT NOT NULL CHECK (transaction_type IN ('membership','class','training','retail','refund')),
    payment_method    TEXT NOT NULL CHECK (payment_method IN ('card','cash','bank','other')),

    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);
