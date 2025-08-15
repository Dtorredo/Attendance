import { mutation } from './_generated/server';
import { v } from 'convex/values';
import bcrypt from 'bcryptjs';

export const register = mutation({
  args: {
    first_name: v.string(),
    last_name: v.string(),
    email: v.string(),
    password: v.string(),
    role: v.union(v.literal('student'), v.literal('lecturer')),
  },
  handler: async (ctx, args) => {
    const existingUser = await ctx.db
      .query('users')
      .withIndex('by_email', (q) => q.eq('email', args.email))
      .unique();

    if (existingUser) {
      throw new Error('User with this email already exists');
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(args.password, salt);

    const userId = await ctx.db.insert('users', {
      first_name: args.first_name,
      last_name: args.last_name,
      email: args.email,
      password_hash,
      role: args.role,
    });

    return { userId };
  },
});

export const login = mutation({
  args: {
    email: v.string(),
    password: v.string(),
  },
  handler: async (ctx, args) => {
    const user = await ctx.db
      .query('users')
      .withIndex('by_email', (q) => q.eq('email', args.email))
      .unique();

    if (!user) {
      throw new Error('User not found');
    }

    const isMatch = await bcrypt.compare(args.password, user.password_hash);

    if (!isMatch) {
      throw new Error('Invalid credentials');
    }

    return user;
  },
});
