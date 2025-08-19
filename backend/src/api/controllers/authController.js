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

    await db.collection('users').doc(userRecord.uid).set({
      first_name: firstName,
      last_name: lastName,
      email,
      role,
    });

    res.status(201).json({ uid: userRecord.uid });
  } catch (error) {
    console.error(error);
    res.status(500).send('Server error');
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    // THIS IS A SECURITY RISK: 
    // In a real app, you would verify the password with Firebase Auth.
    // For this example, we'll just get the user by email and trust the client.
    const userRecord = await admin.auth().getUserByEmail(email);

    // Check if user exists in our DB
    const userDoc = await db.collection('users').doc(userRecord.uid).get();

    if (!userDoc.exists) {
      // User does not exist, create them
      const [firstName, lastName] = userRecord.displayName ? userRecord.displayName.split(' ') : ['',''];
      await db.collection('users').doc(userRecord.uid).set({
        first_name: firstName || '',
        last_name: lastName || '',
        email: userRecord.email,
        role: 'student', // default role
      });
    }

    const user = userDoc.data();
    const token = await admin.auth().createCustomToken(userRecord.uid, { role: user.role });

    res.json({ token });
  } catch (error) {
    console.error(error);
    res.status(500).send('Server error');
  }
};

exports.getMe = async (req, res) => {
    try {
        res.json(req.user);
    } catch (error) {
        console.error(error);
        res.status(500).send('Server error');
    }
};