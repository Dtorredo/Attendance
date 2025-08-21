import React, { createContext, useState, useContext, useEffect } from "react";
import authService from "../services/authService";

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [userRole, setUserRole] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const login = async (email, password) => {
    setLoading(true);
    setError(null);
    try {
      console.log("🔥 Attempting login with Firebase...");
      const result = await authService.signIn(email, password);
      if (result.success) {
        console.log("✅ Login successful");
        setUser(result.user);
        setUserRole(authService.getUserRole());
      } else {
        console.error("❌ Login failed:", result.error);
        setError(result.error);
        throw new Error(result.error);
      }
    } catch (error) {
      console.error("❌ Login error:", error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const register = async (firstName, lastName, email, password, role) => {
    setLoading(true);
    setError(null);
    try {
      console.log("🔥 Attempting registration with Firebase...");
      const result = await authService.signUp(
        email,
        password,
        firstName,
        lastName,
        role
      );
      if (result.success) {
        console.log("✅ Registration successful");
        setUser(result.user);
        setUserRole(authService.getUserRole());
      } else {
        console.error("❌ Registration failed:", result.error);
        setError(result.error);
        throw new Error(result.error);
      }
    } catch (error) {
      console.error("❌ Registration error:", error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    try {
      await authService.signOut();
      setUser(null);
      setUserRole(null);
    } catch (error) {
      console.error("❌ Logout error:", error);
    }
  };

  useEffect(() => {
    console.log("🔄 Initializing auth service...");
    const initAuth = async () => {
      try {
        await authService.init();
        setLoading(false);
      } catch (error) {
        console.error("❌ Auth initialization error:", error);
        setLoading(false);
      }
    };

    // Set up auth state listener
    const unsubscribe = authService.onAuthStateChanged((user, role) => {
      console.log(
        "🔄 Auth state changed:",
        user ? user.uid : "null",
        "Role:",
        role
      );
      setUser(user);
      setUserRole(role);
      setLoading(false);
    });

    initAuth();

    return unsubscribe;
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, userRole, loading, error, login, register, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
};
