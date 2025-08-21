import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCB94Q3Ih8rA_stjF-yS6ponQPsiNIa36E",
  authDomain: "yooh-eb3ae.firebaseapp.com",
  projectId: "yooh-eb3ae",
  storageBucket: "yooh-eb3ae.firebasestorage.app",
  messagingSenderId: "71962511762",
  appId: "1:71962511762:web:21abdf28706b24a4b2d94b",
  measurementId: "G-ECQ9PBMWJK"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

export { db, auth };