import { query } from './_generated/server';
import { v } from 'convex/values';

export const getAttendance = query({
  args: {
    lecturer_id: v.id('users'),
  },
  handler: async (ctx, args) => {
    // 1. Find classes for the lecturer
    const classes = await ctx.db
      .query('classes')
      .filter((q) => q.eq(q.field('lecturer_id'), args.lecturer_id))
      .collect();

    if (classes.length === 0) {
      return []; // No classes for this lecturer
    }

    const classIds = classes.map((c) => c._id);

    // 2. Get all enrollments for these classes
    const enrollments = await ctx.db
      .query('enrollments')
      .filter((q) => q.in(q.field('class_id'), classIds))
      .collect();

    if (enrollments.length === 0) {
      return []; // No students enrolled in any class
    }

    const studentIds = [...new Set(enrollments.map((e) => e.student_id))];

    // 3. Get student details
    const students = await Promise.all(
      studentIds.map(async (studentId) => {
        return await ctx.db.get(studentId);
      })
    );

    // 4. Get all attendance records for these students and classes
    const attendanceRecords = await ctx.db
      .query('attendance_records')
      .filter((q) => q.in(q.field('student_id'), studentIds))
      .filter((q) => q.in(q.field('class_id'), classIds))
      .collect();

    // 5. Calculate percentages
    const studentAttendance = students.map((student) => {
        if (!student) return null;
      const relevantEnrollments = enrollments.filter(
        (e) => e.student_id === student._id
      );
      const relevantClassIds = relevantEnrollments.map((e) => e.class_id);

      const totalClasses = relevantClassIds.length;
      if (totalClasses === 0) {
        return {
          ...student,
          attendancePercentage: 0,
        };
      }

      const attendedClasses = attendanceRecords.filter(
        (r) => r.student_id === student._id && r.is_present
      );
      const attendancePercentage = (attendedClasses.length / totalClasses) * 100;

      return {
        ...student,
        attendancePercentage: attendancePercentage.toFixed(2),
      };
    });

    return studentAttendance.filter(Boolean);
  },
});
