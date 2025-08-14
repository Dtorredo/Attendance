
const db = require('../../config/db');

exports.getAttendance = async (req, res) => {
  try {
    const lecturerId = req.user.id;

    // 1. Find classes for the lecturer
    const classesResult = await db.query('SELECT * FROM classes WHERE lecturer_id = $1', [lecturerId]);
    const classes = classesResult.rows;

    if (classes.length === 0) {
      return res.json([]); // No classes for this lecturer
    }

    const classIds = classes.map(c => c.id);

    // 2. Get all enrollments for these classes
    const enrollmentsResult = await db.query(`SELECT * FROM enrollments WHERE class_id = ANY($1::int[])`, [classIds]);
    const enrollments = enrollmentsResult.rows;

    if (enrollments.length === 0) {
        return res.json([]); // No students enrolled in any class
    }

    const studentIds = [...new Set(enrollments.map(e => e.student_id))];

    // 3. Get student details
    const studentsResult = await db.query(`SELECT id, first_name, last_name FROM users WHERE id = ANY($1::int[])`, [studentIds]);
    const students = studentsResult.rows;

    // 4. Get all attendance records for these students and classes
    const attendanceResult = await db.query(
      `SELECT student_id, class_id, is_present FROM attendance_records WHERE student_id = ANY($1::int[]) AND class_id = ANY($2::int[])`,
      [studentIds, classIds]
    );
    const attendanceRecords = attendanceResult.rows;

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
