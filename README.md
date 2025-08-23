# Yooh - Attendance Management System

Yooh is a comprehensive attendance management system designed for educational institutions. It consists of an iOS application for students to mark their attendance, having reminders as push notifications for classes, assignments and CATS, and a web-based dashboard for lecturers to monitor and manage it.

## Key Components

*   **iOS Application (`Yooh/Yooh`)**: A native Swift-based iOS app for students.
*   **Lecturer Dashboard (`Yooh/dashboard`)**: A React-based web interface for lecturers to view student attendance data in real-time and allocate assignments and classes to their students
*   **Backend (Firebase)**: The entire system is powered by Google Firebase, handling data storage, authentication, and real-time updates.

---

## Features

*   **Student Attendance**: Students can easily mark their attendance through the iOS app.
*   **Lecturer Dashboard**: Lecturers have a dedicated dashboard to:
    *   View a list of students and their overall attendance percentages.
    *   Quickly identify students with low attendance.
    *   Filter and sort data for better analysis.
*   **Real-Time Sync**: All data is synchronized in real-time between the iOS app, the dashboard, and the Firebase backend.

---

## Getting Started

### Prerequisites

*   [Node.js](https://nodejs.org/) (for running the dashboard locally)
*   [Xcode](https://developer.apple.com/xcode/) (for running the iOS app)
*   A Firebase project with Firestore Database and Authentication enabled.

### 1. Configure Firebase

1.  Create a new project on the [Firebase Console](https://console.firebase.google.com/).
2.  Set up **Firestore Database** and **Authentication** (enable Email/Password).
3.  **For the iOS App:**
    *   Add an iOS app to your Firebase project.
    *   Download the `GoogleService-Info.plist` file and place it in the `Yooh/Yooh/` directory.
4.  **For the Lecturer Dashboard:**
    *   Add a Web app to your Firebase project.
    *   Copy the Firebase configuration object.
    *   Create a `.env` file in the `Yooh/dashboard/` directory and paste the configuration values into it, like so:

    ```env
    REACT_APP_FIREBASE_API_KEY="your-api-key"
    REACT_APP_FIREBASE_AUTH_DOMAIN="your-auth-domain"
    REACT_APP_FIREBASE_PROJECT_ID="your-project-id"
    REACT_APP_FIREBASE_STORAGE_BUCKET="your-storage-bucket"
    REACT_APP_FIREBASE_MESSAGING_SENDER_ID="your-sender-id"
    REACT_APP_FIREBASE_APP_ID="your-app-id"
    ```

### 2. Run the Lecturer Dashboard

```bash
# Navigate to the dashboard directory
cd Yooh/dashboard

# Install dependencies
npm install

# Start the development server
npm start
```
The dashboard will be available at `http://localhost:3000`.

### 3. Run the iOS App

1.  Open the `Yooh.xcworkspace` file in Xcode.
2.  Select your target device or simulator.
3.  Run the build (`Cmd+R`).

---

## Technology Stack

*   **iOS App**: Swift, SwiftUI
*   **Dashboard**: React, JavaScript, CSS
*   **Backend & Database**: Google Firebase (Firestore, Authentication)
