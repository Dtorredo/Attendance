
const admin = require('../../config/firebase');
const db = require('../../config/db');

exports.getAttendance = async (req, res) => {
  try {
    const lecturerId = req.user.uid; // Changed from req.user.id to req.user.uid

    // 1. Find classes for the lecturer
    const classesSnapshot = await db.collection('classes').where('lecturer_id', '==', lecturerId).get();
    if (classesSnapshot.empty) {
      return res.json([]);
    }
    const classIds = classesSnapshot.docs.map(doc => doc.id);

    // 2. Get all enrollments for these classes
    const enrollmentsSnapshot = await db.collection('enrollments').where('class_id', 'in', classIds).get();
    if (enrollmentsSnapshot.empty) {
      return res.json([]);
    }
    const enrollments = enrollmentsSnapshot.docs.map(doc => doc.data());
    const studentIds = [...new Set(enrollments.map(e => e.student_id))];

    // 3. Get student details
    const studentsSnapshot = await db.collection('users').where(admin.firestore.FieldPath.documentId(), 'in', studentIds).get();
    const students = studentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // 4. Get all attendance records for these students and classes
    const attendanceSnapshot = await db.collection('attendance').where('student_id', 'in', studentIds).where('class_id', 'in', classIds).get();
    const attendanceRecords = attendanceSnapshot.docs.map(doc => doc.data());

    // 5. Calculate percentages
    const studentAttendance = students.map(student => {
      const relevantEnrollments = enrollments.filter(e => e.student_id === student.id);
      const relevantClassIds = relevantEnrollments.map(e => e.class_id);

      const totalClasses = relevantClassIds.length;
      if (totalClasses === 0) {
        return {
            ...student,
            attendancePercentage: 0,
        }
      }

      const attendedClasses = attendanceRecords.filter(r => r.student_id === student.id && r.is_present);
      const attendancePercentage = (attendedClasses.length / totalClasses) * 100;

      return {
        ...student,
        attendancePercentage: attendancePercentage.toFixed(2),
      };
    });

    res.json(studentAttendance);

  } catch (error) {
    console.error(error);
    res.status(500).send('Server Error');
  }
};
