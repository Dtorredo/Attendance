
const express = require('express');
const router = express.Router();
const { register, login, getMe } = require('../controllers/authController');
const auth = require('../middleware/authMiddleware');

// @route   POST api/auth/register
// @desc    Register a user
// @access  Public
router.post('/register', register);

// @route   POST api/auth/login
// @desc    Authenticate user & get token
// @access  Public
router.post('/login', login);

// @route   GET api/auth/me
// @desc    Get user data
// @access  Private
router.get('/me', auth, getMe);

module.exports = router;
