
const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const { createAttendanceRecord } = require('../controllers/attendanceController');

// @route   POST api/attendance
// @desc    Create an attendance record
// @access  Private
router.post('/', auth, createAttendanceRecord);

module.exports = router;
