# Firebase Integration Setup Guide

## Overview
This guide will help you complete the Firebase integration for your Yooh app, enabling user authentication and data synchronization between the iOS app and web dashboard.

## 🔥 Firebase Project Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `yooh-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

### 2. Enable Authentication
1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable the following providers:
   - **Email/Password**: Enable
   - **Google**: Enable (configure OAuth consent screen)

### 3. Create Firestore Database
1. Go to **Firestore Database**
2. Click "Create database"
3. Choose **Start in test mode** (we'll update rules later)
4. Select your preferred location
5. Click "Done"

### 4. Set up Security Rules
1. In Firestore Database, go to **Rules** tab
2. Replace the default rules with the content from `firestore.rules`
3. Click "Publish"

## 📱 iOS App Configuration

### 1. Update GoogleService-Info.plist
1. In Firebase Console, go to **Project Settings** > **General**
2. Click "Add app" > iOS
3. Enter your iOS bundle ID (found in Xcode project settings)
4. Download `GoogleService-Info.plist`
5. Replace the existing file in `Yooh/Yooh/GoogleService-Info.plist`

### 2. Configure URL Schemes (for Google Sign-In)
1. Open `Yooh.xcodeproj` in Xcode
2. Select your app target
3. Go to **Info** tab > **URL Types**
4. Add a new URL Type with:
   - Identifier: `GoogleSignIn`
   - URL Schemes: Your `REVERSED_CLIENT_ID` from GoogleService-Info.plist

## 🌐 Web Dashboard Configuration

### 1. Get Web App Config
1. In Firebase Console, go to **Project Settings** > **General**
2. Scroll to "Your apps" section
3. Click "Add app" > Web
4. Register your web app
5. Copy the Firebase configuration object

### 2. Update Firebase Config
1. Open `Yooh/dashboard/src/services/firebase.js`
2. Replace the placeholder config with your actual Firebase config:

```javascript
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};
```

### 3. Install Dependencies
```bash
cd Yooh/dashboard
npm install
```

## 🔄 Data Migration Strategy

### Automatic Migration (Recommended)
The app will automatically sync local SwiftData to Firebase when users first authenticate:

1. **User signs in** → Firebase UID is assigned
2. **Local data is uploaded** → All existing classes, assignments, attendance records
3. **Ongoing sync** → New data is saved to both local and Firebase
4. **Offline support** → App works offline, syncs when online

### Manual Migration (if needed)
If you need to migrate existing user data:

1. Export data from SwiftData
2. Create user accounts in Firebase Auth
3. Import data to Firestore with proper `userId` fields

## 🧪 Testing the Integration

### 1. iOS App Testing
1. Build and run the iOS app
2. Test user registration with email/password
3. Test Google Sign-In
4. Create some test data (classes, assignments)
5. Verify data appears in Firestore Console

### 2. Web Dashboard Testing
1. Start the web dashboard: `cd Yooh/dashboard && npm start`
2. Sign in with the same credentials as iOS app
3. Verify you can see the same data
4. Test creating/editing data from web
5. Verify changes sync to iOS app

### 3. User Isolation Testing
1. Create multiple user accounts
2. Verify each user only sees their own data
3. Test that users cannot access other users' data

## 🔐 Security Considerations

### Firestore Security Rules
The provided rules ensure:
- Users can only access their own data
- All documents require authentication
- User ID validation on all operations

### Additional Security
- Enable App Check for production
- Set up proper CORS for web dashboard
- Use Firebase Security Rules simulator for testing

## 🚀 Production Deployment

### iOS App
1. Update Firebase project to production mode
2. Test thoroughly with production Firebase
3. Submit to App Store

### Web Dashboard
1. Build for production: `npm run build`
2. Deploy to Firebase Hosting or your preferred platform
3. Update Firebase Auth authorized domains

## 📊 Monitoring and Analytics

### Firebase Console
- Monitor authentication usage
- Track Firestore read/write operations
- Set up alerts for unusual activity

### Performance
- Monitor app performance with Firebase Performance
- Track user engagement with Firebase Analytics

## 🔧 Troubleshooting

### Common Issues
1. **Authentication fails**: Check GoogleService-Info.plist and bundle ID
2. **Firestore permission denied**: Verify security rules and user authentication
3. **Data not syncing**: Check network connectivity and Firebase project settings
4. **Google Sign-In fails**: Verify URL schemes and OAuth configuration

### Debug Tools
- Firebase Console logs
- Xcode console for iOS debugging
- Browser developer tools for web dashboard
- Firebase Local Emulator Suite for local testing

## 📝 Next Steps

After completing this setup:
1. Test all functionality thoroughly
2. Add error handling and user feedback
3. Implement offline data caching strategies
4. Add push notifications (optional)
5. Set up continuous integration/deployment
6. Monitor usage and performance metrics

## 🆘 Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Review Firestore security rules
3. Verify all configuration files are correct
4. Test with Firebase Local Emulator Suite
5. Consult Firebase documentation for specific features
