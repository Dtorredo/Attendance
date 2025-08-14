
const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const { getAttendance } = require('../controllers/dashboardController');

// @route   GET api/dashboard/attendance
// @desc    Get all student attendance for a lecturer
// @access  Private
router.get('/attendance', auth, getAttendance);

module.exports = router;
