require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('./config/firebase'); // Add this line

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Basic Route
app.get('/', (req, res) => {
  res.send('Yooh API is running...');
});

// Define Routes
app.use('/api/auth', require('./api/routes/auth'));
app.use('/api/dashboard', require('./api/routes/dashboard'));
app.use('/api/attendance', require('./api/routes/attendance'));


const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});