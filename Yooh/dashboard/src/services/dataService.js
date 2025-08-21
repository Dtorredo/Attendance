import { 
  collection, 
  doc, 
  getDocs, 
  getDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  query, 
  where, 
  orderBy,
  onSnapshot
} from 'firebase/firestore';
import { db } from './firebase';
import authService from './authService';

class DataService {
  constructor() {
    this.listeners = new Map();
  }

  // Generic method to get user's data from a collection
  async getUserData(collectionName, orderByField = 'createdAt') {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error('User not authenticated');

      const q = query(
        collection(db, collectionName),
        where('userId', '==', user.uid),
        orderBy(orderByField, 'desc')
      );

      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error(`Error fetching ${collectionName}:`, error);
      throw error;
    }
  }

  // Real-time listener for user's data
  subscribeToUserData(collectionName, callback, orderByField = 'createdAt') {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error('User not authenticated');

      const q = query(
        collection(db, collectionName),
        where('userId', '==', user.uid),
        orderBy(orderByField, 'desc')
      );

      const unsubscribe = onSnapshot(q, (querySnapshot) => {
        const data = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        callback(data);
      });

      // Store the unsubscribe function
      const key = `${collectionName}_${user.uid}`;
      this.listeners.set(key, unsubscribe);

      return unsubscribe;
    } catch (error) {
      console.error(`Error subscribing to ${collectionName}:`, error);
      throw error;
    }
  }

  // Unsubscribe from all listeners
  unsubscribeAll() {
    this.listeners.forEach(unsubscribe => unsubscribe());
    this.listeners.clear();
  }

  // ASSIGNMENTS
  async getAssignments() {
    return this.getUserData('assignments', 'dueDate');
  }

  subscribeToAssignments(callback) {
    return this.subscribeToUserData('assignments', callback, 'dueDate');
  }

  async createAssignment(assignmentData) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error('User not authenticated');

      const data = {
        ...assignmentData,
        userId: user.uid,
        createdAt: new Date()
      };

      const docRef = await addDoc(collection(db, 'assignments'), data);
      return { id: docRef.id, ...data };
    } catch (error) {
      console.error('Error creating assignment:', error);
      throw error;
    }
  }

  async updateAssignment(assignmentId, updates) {
    try {
      const assignmentRef = doc(db, 'assignments', assignmentId);
      await updateDoc(assignmentRef, {
        ...updates,
        updatedAt: new Date()
      });
      return true;
    } catch (error) {
      console.error('Error updating assignment:', error);
      throw error;
    }
  }

  async deleteAssignment(assignmentId) {
    try {
      await deleteDoc(doc(db, 'assignments', assignmentId));
      return true;
    } catch (error) {
      console.error('Error deleting assignment:', error);
      throw error;
    }
  }

  // CLASSES
  async getClasses() {
    return this.getUserData('classes', 'startDate');
  }

  subscribeToClasses(callback) {
    return this.subscribeToUserData('classes', callback, 'startDate');
  }

  async createClass(classData) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error('User not authenticated');

      const data = {
        ...classData,
        userId: user.uid,
        createdAt: new Date()
      };

      const docRef = await addDoc(collection(db, 'classes'), data);
      return { id: docRef.id, ...data };
    } catch (error) {
      console.error('Error creating class:', error);
      throw error;
    }
  }

  async updateClass(classId, updates) {
    try {
      const classRef = doc(db, 'classes', classId);
      await updateDoc(classRef, {
        ...updates,
        updatedAt: new Date()
      });
      return true;
    } catch (error) {
      console.error('Error updating class:', error);
      throw error;
    }
  }

  async deleteClass(classId) {
    try {
      await deleteDoc(doc(db, 'classes', classId));
      return true;
    } catch (error) {
      console.error('Error deleting class:', error);
      throw error;
    }
  }

  // ATTENDANCE RECORDS
  async getAttendanceRecords() {
    return this.getUserData('attendance', 'timestamp');
  }

  subscribeToAttendanceRecords(callback) {
    return this.subscribeToUserData('attendance', callback, 'timestamp');
  }

  async getAttendanceForClass(classId) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error('User not authenticated');

      const q = query(
        collection(db, 'attendance'),
        where('userId', '==', user.uid),
        where('classId', '==', classId),
        orderBy('timestamp', 'desc')
      );

      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error('Error fetching attendance for class:', error);
      throw error;
    }
  }

  // USERS (for admin/lecturer access)
  async getAllUsers() {
    try {
      const user = authService.getCurrentUser();
      if (!user || !authService.isLecturer()) {
        throw new Error('Unauthorized access');
      }

      const querySnapshot = await getDocs(collection(db, 'users'));
      return querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  }

  // Get user profile
  async getUserProfile(userId = null) {
    try {
      const targetUserId = userId || authService.getCurrentUser()?.uid;
      if (!targetUserId) throw new Error('User ID not provided');

      const userDoc = await getDoc(doc(db, 'users', targetUserId));
      if (userDoc.exists()) {
        return { id: userDoc.id, ...userDoc.data() };
      }
      return null;
    } catch (error) {
      console.error('Error fetching user profile:', error);
      throw error;
    }
  }
}

// Create and export singleton instance
const dataService = new DataService();
export default dataService;
