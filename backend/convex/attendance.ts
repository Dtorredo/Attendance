import { mutation } from './_generated/server';
import { v } from 'convex/values';

export const createAttendanceRecord = mutation({
  args: {
    student_id: v.id('users'),
    class_id: v.id('classes'),
    attendance_date: v.string(),
    is_present: v.boolean(),
  },
  handler: async (ctx, args) => {
    const existingRecord = await ctx.db
      .query('attendance_records')
      .withIndex('by_student_class_date', (q) =>
        q
          .eq('student_id', args.student_id)
          .eq('class_id', args.class_id)
          .eq('attendance_date', args.attendance_date)
      )
      .unique();

    if (existingRecord) {
      throw new Error('Attendance record for this student, class, and date already exists.');
    }

    const recordId = await ctx.db.insert('attendance_records', {
      student_id: args.student_id,
      class_id: args.class_id,
      attendance_date: args.attendance_date,
      is_present: args.is_present,
    });

    return { recordId };
  },
});
