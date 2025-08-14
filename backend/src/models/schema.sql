
-- Drop tables if they exist to start fresh
DROP TABLE IF EXISTS attendance_records;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS classes;

-- Users Table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'lecturer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Classes Table
CREATE TABLE classes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    lecturer_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enrollments Table (Junction table for students and classes)
CREATE TABLE enrollments (
    student_id INTEGER NOT NULL REFERENCES users(id),
    class_id INTEGER NOT NULL REFERENCES classes(id),
    PRIMARY KEY (student_id, class_id)
);

-- Attendance Records Table
CREATE TABLE attendance_records (
    id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL REFERENCES users(id),
    class_id INTEGER NOT NULL REFERENCES classes(id),
    attendance_date DATE NOT NULL,
    is_present BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, class_id, attendance_date)
);

