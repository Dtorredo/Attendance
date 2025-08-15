import { defineSchema, defineTable } from 'convex/server';
import { v } from 'convex/values';

export default defineSchema({
  users: defineTable({
    first_name: v.string(),
    last_name: v.string(),
    email: v.string(),
    password_hash: v.string(),
    role: v.union(v.literal('student'), v.literal('lecturer')),
  }).index('by_email', ['email']),

  classes: defineTable({
    name: v.string(),
    lecturer_id: v.id('users'),
  }),

  enrollments: defineTable({
    student_id: v.id('users'),
    class_id: v.id('classes'),
  }).index('by_student_and_class', ['student_id', 'class_id']),

  attendance_records: defineTable({
    student_id: v.id('users'),
    class_id: v.id('classes'),
    attendance_date: v.string(),
    is_present: v.boolean(),
  }).index('by_student_class_date', ['student_id', 'class_id', 'attendance_date']),
});
