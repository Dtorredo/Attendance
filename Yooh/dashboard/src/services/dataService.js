import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  onSnapshot,
} from "firebase/firestore";
import { db } from "./firebase";
import authService from "./authService";

class DataService {
  constructor() {
    this.listeners = new Map();
  }

  // Generic method to get user's data from a collection
  async getUserData(collectionName, orderByField = "createdAt") {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      const q = query(
        collection(db, collectionName),
        where("userId", "==", user.uid),
        orderBy(orderByField, "desc")
      );

      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      console.error(`Error fetching ${collectionName}:`, error);
      throw error;
    }
  }

  // Real-time listener for user's data
  subscribeToUserData(collectionName, callback, orderByField = "createdAt") {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      const q = query(
        collection(db, collectionName),
        where("userId", "==", user.uid),
        orderBy(orderByField, "desc")
      );

      const unsubscribe = onSnapshot(q, (querySnapshot) => {
        const data = querySnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
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
    this.listeners.forEach((unsubscribe) => unsubscribe());
    this.listeners.clear();
  }

  // ASSIGNMENTS
  async getAssignments() {
    return this.getUserData("assignments", "dueDate");
  }

  subscribeToAssignments(callback) {
    return this.subscribeToUserData("assignments", callback, "dueDate");
  }

  async createAssignment(assignmentData) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      const data = {
        ...assignmentData,
        userId: user.uid,
        createdAt: new Date(),
      };

      const docRef = await addDoc(collection(db, "assignments"), data);
      return { id: docRef.id, ...data };
    } catch (error) {
      console.error("Error creating assignment:", error);
      throw error;
    }
  }

  // Create assignment for a specific student (used by lecturers)
  async createAssignmentForStudent(assignmentData, studentId) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      // Generate a unique ID for the assignment
      const assignmentId = `assignment_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`;

      const data = {
        id: assignmentId, // Add the id field that iOS expects
        userId: studentId, // Assign to specific student
        title: assignmentData.title,
        dueDate: new Date(assignmentData.dueDate), // Convert to Timestamp
        isCompleted: false, // Default to not completed
        priority: assignmentData.priority || "Medium", // Default priority (capitalized for iOS enum)
        details: assignmentData.details || "",
        createdBy: user.uid,
        createdAt: new Date(),
      };

      // Use the generated ID as the document ID
      await setDoc(doc(db, "assignments", assignmentId), data);
      return { id: assignmentId, ...data };
    } catch (error) {
      console.error("Error creating assignment for student:", error);
      throw error;
    }
  }

  async updateAssignment(assignmentId, updates) {
    try {
      const assignmentRef = doc(db, "assignments", assignmentId);
      await updateDoc(assignmentRef, {
        ...updates,
        updatedAt: new Date(),
      });
      return true;
    } catch (error) {
      console.error("Error updating assignment:", error);
      throw error;
    }
  }

  async deleteAssignment(assignmentId) {
    try {
      await deleteDoc(doc(db, "assignments", assignmentId));
      return true;
    } catch (error) {
      console.error("Error deleting assignment:", error);
      throw error;
    }
  }

  // CLASSES
  async getClasses() {
    return this.getUserData("classes", "startDate");
  }

  subscribeToClasses(callback) {
    return this.subscribeToUserData("classes", callback, "startDate");
  }

  async createClass(classData) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      const data = {
        ...classData,
        userId: user.uid,
        createdAt: new Date(),
      };

      const docRef = await addDoc(collection(db, "classes"), data);
      return { id: docRef.id, ...data };
    } catch (error) {
      console.error("Error creating class:", error);
      throw error;
    }
  }

  // Create class for a specific student (used by lecturers)
  async createClassForStudent(classData, studentId) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      // Generate a unique ID for the class
      const classId = `class_${Date.now()}_${Math.random()
        .toString(36)
        .substr(2, 9)}`;

      const data = {
        id: classId, // Add the id field that iOS expects
        userId: studentId, // Assign to specific student
        title: classData.title,
        startDate: new Date(classData.startDate), // Convert to Timestamp
        endDate: new Date(classData.endDate), // Convert to Timestamp
        location: classData.location || "",
        notes: classData.notes || "",
        dayOfWeek: classData.dayOfWeek,
        isRecurring: classData.isRecurring || false,
        createdBy: user.uid,
        createdAt: new Date(),
      };

      // Use the generated ID as the document ID
      await setDoc(doc(db, "classes", classId), data);
      return { id: classId, ...data };
    } catch (error) {
      console.error("Error creating class for student:", error);
      throw error;
    }
  }

  async updateClass(classId, updates) {
    try {
      const classRef = doc(db, "classes", classId);
      await updateDoc(classRef, {
        ...updates,
        updatedAt: new Date(),
      });
      return true;
    } catch (error) {
      console.error("Error updating class:", error);
      throw error;
    }
  }

  async deleteClass(classId) {
    try {
      await deleteDoc(doc(db, "classes", classId));
      return true;
    } catch (error) {
      console.error("Error deleting class:", error);
      throw error;
    }
  }

  // ATTENDANCE RECORDS
  async getAttendanceRecords() {
    return this.getUserData("attendance", "timestamp");
  }

  subscribeToAttendanceRecords(callback) {
    return this.subscribeToUserData("attendance", callback, "timestamp");
  }

  async getAttendanceForClass(classId) {
    try {
      const user = authService.getCurrentUser();
      if (!user) throw new Error("User not authenticated");

      const q = query(
        collection(db, "attendance"),
        where("userId", "==", user.uid),
        where("classId", "==", classId),
        orderBy("timestamp", "desc")
      );

      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      console.error("Error fetching attendance for class:", error);
      throw error;
    }
  }

  // USERS (for admin/lecturer access)
  async getAllUsers() {
    try {
      const user = authService.getCurrentUser();
      if (!user) {
        throw new Error("User not authenticated");
      }

      console.log("🔄 Fetching all users for lecturer...");
      const querySnapshot = await getDocs(collection(db, "users"));
      const users = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      console.log("✅ Users fetched:", users.length);
      return users;
    } catch (error) {
      console.error("❌ Error fetching users:", error);
      throw error;
    }
  }

  // Get all data from a collection (for lecturers to see all student data)
  async getAllData(collectionName, orderByField = "createdAt") {
    try {
      const user = authService.getCurrentUser();
      if (!user) {
        throw new Error("User not authenticated");
      }

      console.log(`🔄 Fetching all ${collectionName} data for lecturer...`);
      const q = query(
        collection(db, collectionName),
        orderBy(orderByField, "desc")
      );

      const querySnapshot = await getDocs(q);
      const data = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      console.log(`✅ ${collectionName} data fetched:`, data.length);
      return data;
    } catch (error) {
      console.error(`❌ Error fetching ${collectionName}:`, error);
      throw error;
    }
  }

  // Get user profile
  async getUserProfile(userId = null) {
    try {
      const targetUserId = userId || authService.getCurrentUser()?.uid;
      if (!targetUserId) throw new Error("User ID not provided");

      const userDoc = await getDoc(doc(db, "users", targetUserId));
      if (userDoc.exists()) {
        return { id: userDoc.id, ...userDoc.data() };
      }
      return null;
    } catch (error) {
      console.error("Error fetching user profile:", error);
      throw error;
    }
  }
}

// Create and export singleton instance
const dataService = new DataService();
export default dataService;
