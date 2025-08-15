import React, { createContext, useState, useContext } from 'react';
import { useMutation } from 'convex/react';
import { api } from '../../convex/_generated/api';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);

  const loginMutation = useMutation(api.auth.login);
  const registerMutation = useMutation(api.auth.register);

  const login = async (email, password) => {
    setLoading(true);
    try {
      const userData = await loginMutation({ email, password });
      setUser(userData);
    } catch (error) {
      console.error('Login failed:', error);
      // Handle login error (e.g., show a message to the user)
    } finally {
      setLoading(false);
    }
  };

  const register = async (firstName, lastName, email, password, role) => {
    setLoading(true);
    try {
      await registerMutation({ first_name: firstName, last_name: lastName, email, password, role });
      // Optionally, log the user in automatically after registration
      await login(email, password);
    } catch (error) {
      console.error('Registration failed:', error);
      // Handle registration error
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
};