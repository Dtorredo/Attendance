CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    firebase_uid VARCHAR(255) UNIQUE
);

CREATE TABLE attendance_records (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES users(id),
    class_id INTEGER,
    attendance_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL,
    UNIQUE(student_id, class_id, attendance_date)
);