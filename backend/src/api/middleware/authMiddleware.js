const admin = require('../../config/firebase');
const db = require('../../config/db');

module.exports = async function (req, res, next) {
  const token = req.header('Authorization')?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();

    if (!userDoc.exists) {
        return res.status(401).json({ msg: 'User not found' });
    }

    req.user = { uid: decodedToken.uid, ...userDoc.data() };
    next();
  } catch (err) {
    res.status(401).json({ msg: 'Token is not valid' });
  }
};