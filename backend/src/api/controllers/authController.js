const admin = require('../../config/firebase');
const db = require('../../config/db');

exports.register = async (req, res) => {
  const { email, password, firstName, lastName, role } = req.body;

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`,
    });

    await admin.auth().setCustomUserClaims(userRecord.uid, { role });

    const result = await db.query(
      'INSERT INTO users (first_name, last_name, email, password_hash, role, firebase_uid) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [firstName, lastName, email, '', role, userRecord.uid]
    );

    res.status(201).json({ uid: userRecord.uid });
  } catch (error) {
    console.error(error);
    res.status(500).send('Server error');
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // This is a placeholder. In a real app, you would verify the password.
    // For this example, we'll just get the user by email.
    const userRecord = await admin.auth().getUserByEmail(email);

    const token = await admin.auth().createCustomToken(userRecord.uid);

    res.json({ token });
  } catch (error) {
    console.error(error);
    res.status(500).send('Server error');
  }
};
