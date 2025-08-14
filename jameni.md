Plan: Attendance API & Lecturer Dashboard for Yooh

  This plan outlines the development of a backend API for storing attendance data and a web-based dashboard for lecturers to monitor student attendance.

  1. High-Level Architecture

  The final system will consist of three main components:

   1. Yooh iOS App (Existing): The app will be updated to send attendance data to our new backend API instead of (or in addition to) storing it locally.
   2. Backend API (New): A Node.js server that will receive data from the iOS app, store it in a database, and provide data to the admin dashboard.
   3. Admin Dashboard (New): A web interface for lecturers to log in, view, and analyze student attendance data.

  Data Flow:
  iOS App -> Backend API -> Database <- Admin Dashboard

  2. Proposed Technology Stack

   * Backend: Node.js with Express.js. It's a popular, fast, and relatively simple framework for building APIs.
   * Database: PostgreSQL. A robust and reliable open-source relational database that is perfect for handling structured data like attendance records.
   * Admin Dashboard: React.js. A powerful library for building modern, interactive user interfaces. We'll use a component library like Material-UI or Ant Design to create a
     professional-looking dashboard quickly.
   * Authentication: JWT (JSON Web Tokens) for securing the API endpoints and managing user sessions in the dashboard.

  3. Development Phases

  I'll break down the work into four distinct phases.

  Phase 1: Backend API Development

  This is the foundation of the new system.

   * Setup Node.js Project: Initialize a new Node.js project with Express.js.
   * Database Schema Design: Define the structure for our data. We'll need tables for:
       * users (to store student and lecturer information, including roles).
       * classes (for school classes/courses).
       * enrollments (to link students to the classes they are enrolled in).
       * attendance_records (to store each attendance event).
   * API Endpoint Implementation: Create the following API endpoints:
       * POST /api/auth/login: For lecturers to log in and receive an authentication token.
       * POST /api/attendance: The endpoint the iOS app will call to submit an attendance record.
       * GET /api/dashboard/attendance: A protected endpoint for the dashboard to fetch attendance data for all students in a lecturer's classes. It will calculate attendance percentages on
         the fly.

  Phase 2: iOS App Integration

   * Modify `AttendanceManager.swift`: Update the existing attendance logic. When a user signs attendance, besides the current functionality, it will make a network request to the new POST
     /api/attendance endpoint on our backend.
   * Secure API Calls: Ensure that any API keys or tokens needed to communicate with the backend are stored securely within the iOS app.

  Phase 3: Admin Dashboard Development

   * Setup React Project: Initialize a new React application.
   * Implement Login Page: Create a login form for lecturers. On successful login, the app will store the JWT and use it for subsequent API requests.
   * Create Dashboard View:
       * Fetch and display a list of students and their overall attendance percentage for the classes managed by the logged-in lecturer.
       * The list will clearly show the student's name, ID, and attendance percentage.
       * Conditional Formatting: Students with an attendance percentage below 70% will be visually highlighted (e.g., with a red background color) to make them easy to spot.
       * Add sorting and filtering options (e.g., by student name, by percentage).

  Phase 4: Additional Features (Recommended)

  To make the dashboard even more powerful, I suggest we add these features:

   * Detailed Student View: Allow a lecturer to click on a student to see a more detailed breakdown of their attendance, including which specific classes they missed and on what dates.
   * Class-Specific Filtering: Add a dropdown menu to filter the dashboard by a specific class, showing attendance for only the students enrolled in that class.
   * Reporting & Exports: An "Export to CSV" button that allows lecturers to download the attendance data for their records.
   * User Management: A section in the dashboard (perhaps for a super-admin role) to add, edit, and remove student and lecturer accounts.
   * Automated Email/Push Notifications: The system could automatically send a notification to students who drop below the 70% threshold.