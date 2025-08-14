
const db = require('../../config/db');

exports.createAttendanceRecord = async (req, res) => {
  const { studentId, classId, attendanceDate, isPresent } = req.body;

  try {
    const result = await db.query(
      'INSERT INTO attendance_records (student_id, class_id, attendance_date, is_present) VALUES ($1, $2, $3, $4) RETURNING *',
      [studentId, classId, attendanceDate, isPresent]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error(error);
    if (error.code === '23505') { // unique_violation
        return res.status(400).json({ msg: 'Attendance record for this student, class, and date already exists.' });
    }
    res.status(500).send('Server error');
  }
};
