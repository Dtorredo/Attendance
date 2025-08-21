import { 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  GoogleAuthProvider,
  signInWithPopup
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase';

class AuthService {
  constructor() {
    this.currentUser = null;
    this.userRole = null;
    this.authStateListeners = [];
  }

  // Initialize auth state listener
  init() {
    return new Promise((resolve) => {
      onAuthStateChanged(auth, async (user) => {
        if (user) {
          this.currentUser = user;
          await this.fetchUserRole(user.uid);
        } else {
          this.currentUser = null;
          this.userRole = null;
        }
        
        // Notify all listeners
        this.authStateListeners.forEach(callback => callback(user, this.userRole));
        resolve(user);
      });
    });
  }

  // Add auth state listener
  onAuthStateChanged(callback) {
    this.authStateListeners.push(callback);
    
    // Return unsubscribe function
    return () => {
      const index = this.authStateListeners.indexOf(callback);
      if (index > -1) {
        this.authStateListeners.splice(index, 1);
      }
    };
  }

  // Sign in with email and password
  async signIn(email, password) {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      await this.fetchUserRole(userCredential.user.uid);
      return { success: true, user: userCredential.user };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Sign up with email and password
  async signUp(email, password, firstName, lastName, role = 'lecturer') {
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      
      // Save user profile to Firestore
      await this.saveUserProfile(user.uid, {
        firstName,
        lastName,
        email,
        role,
        createdAt: new Date()
      });
      
      this.userRole = role;
      return { success: true, user };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Sign in with Google
  async signInWithGoogle() {
    try {
      const provider = new GoogleAuthProvider();
      const userCredential = await signInWithPopup(auth, provider);
      const user = userCredential.user;
      
      // Check if user profile exists, if not create one
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      if (!userDoc.exists()) {
        const [firstName, ...lastNameParts] = user.displayName?.split(' ') || ['', ''];
        const lastName = lastNameParts.join(' ');
        
        await this.saveUserProfile(user.uid, {
          firstName,
          lastName,
          email: user.email,
          role: 'lecturer', // Default role for Google sign-in
          createdAt: new Date()
        });
        this.userRole = 'lecturer';
      } else {
        await this.fetchUserRole(user.uid);
      }
      
      return { success: true, user };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Sign out
  async signOut() {
    try {
      await signOut(auth);
      this.currentUser = null;
      this.userRole = null;
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Save user profile to Firestore
  async saveUserProfile(uid, profileData) {
    try {
      await setDoc(doc(db, 'users', uid), profileData);
      return { success: true };
    } catch (error) {
      console.error('Error saving user profile:', error);
      return { success: false, error: error.message };
    }
  }

  // Fetch user role from Firestore
  async fetchUserRole(uid) {
    try {
      const userDoc = await getDoc(doc(db, 'users', uid));
      if (userDoc.exists()) {
        this.userRole = userDoc.data().role;
        return this.userRole;
      }
      return null;
    } catch (error) {
      console.error('Error fetching user role:', error);
      return null;
    }
  }

  // Get current user
  getCurrentUser() {
    return this.currentUser;
  }

  // Get user role
  getUserRole() {
    return this.userRole;
  }

  // Check if user is authenticated
  isAuthenticated() {
    return !!this.currentUser;
  }

  // Check if user is lecturer
  isLecturer() {
    return this.userRole === 'lecturer';
  }

  // Check if user is student
  isStudent() {
    return this.userRole === 'student';
  }
}

// Create and export singleton instance
const authService = new AuthService();
export default authService;
