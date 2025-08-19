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

    const attendanceRecord = {
      student_id: uid,
      class_id: classId,
      attendance_date: attendanceDate,
      is_present: isPresent,
    };

    const docRef = await db.collection('attendance').add(attendanceRecord);

    res.status(201).json({ id: docRef.id, ...attendanceRecord });
  } catch (error) {
    console.error(error);
    res.status(500).send('Server error');
  }
};