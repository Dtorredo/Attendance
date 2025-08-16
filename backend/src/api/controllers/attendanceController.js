const admin = require('../../config/firebase');
const db = require('../../config/db');

exports.createAttendanceRecord = async (req, res) => {
  const { classId, attendanceDate, isPresent } = req.body;
  const idToken = req.headers.authorization?.split('Bearer ')[1];

  if (!idToken) {
    return res.status(401).send('Unauthorized');
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;

    const result = await db.query(
      'INSERT INTO attendance_records (student_id, class_id, attendance_date, is_present) VALUES ((SELECT id FROM users WHERE firebase_uid = $1), $2, $3, $4) RETURNING *',
      [uid, classId, attendanceDate, isPresent]
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