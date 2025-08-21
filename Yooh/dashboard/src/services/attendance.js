import { db } from "./firebase";
import { collection, query, where, getDocs } from "firebase/firestore";

export const getAttendance = async (lecturer_id) => {
  if (!lecturer_id) {
    return [];
  }

  const attendanceQuery = query(
    collection(db, "attendance"),
    where("lecturer_id", "==", lecturer_id)
  );
  const attendanceSnapshot = await getDocs(attendanceQuery);
  const attendanceData = attendanceSnapshot.docs.map((doc) => doc.data());

  const studentIds = [
    ...new Set(attendanceData.map((data) => data.student_id)),
  ];

  const studentsQuery = query(
    collection(db, "students"),
    where("student_id", "in", studentIds)
  );
  const studentsSnapshot = await getDocs(studentsQuery);
  const studentsData = studentsSnapshot.docs.map((doc) => doc.data());

  const studentsById = studentsData.reduce((acc, student) => {
    acc[student.student_id] = student;
    return acc;
  }, {});

  const attendanceByStudent = attendanceData.reduce((acc, record) => {
    if (!acc[record.student_id]) {
      acc[record.student_id] = { present: 0, total: 0 };
    }
    acc[record.student_id].total++;
    if (record.present) {
      acc[record.student_id].present++;
    }
    return acc;
  }, {});

  const result = Object.keys(attendanceByStudent).map((student_id) => {
    const student = studentsById[student_id];
    const attendance = attendanceByStudent[student_id];
    const attendancePercentage = (attendance.present / attendance.total) * 100;
    return {
      _id: student_id,
      first_name: student.first_name,
      last_name: student.last_name,
      attendancePercentage: attendancePercentage.toFixed(2),
    };
  });

  return result;
};
