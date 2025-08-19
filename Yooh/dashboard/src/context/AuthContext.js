import React, { createContext, useState, useContext, useEffect } from 'react';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);

  const login = async (email, password) => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:5001/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });
      const data = await response.json();
      if (response.ok) {
        localStorage.setItem('token', data.token);
        const userResponse = await fetch('http://localhost:5001/api/auth/me', { // Assuming you have a /me endpoint
            headers: { 'Authorization': `Bearer ${data.token}` }
        });
        const userData = await userResponse.json();
        if (userResponse.ok) {
            setUser(userData);
        }
      } else {
        throw new Error(data.msg || 'Failed to login');
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const register = async (firstName, lastName, email, password, role) => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:5001/api/auth/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ firstName, lastName, email, password, role }),
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.msg || 'Failed to register');
      }
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('token');
  };

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      const verifyToken = async () => {
        try {
          const userResponse = await fetch('http://localhost:5001/api/auth/me', {
            headers: { 'Authorization': `Bearer ${token}` }
          });
          const userData = await userResponse.json();
          if (userResponse.ok) {
            setUser(userData);
          } else {
            localStorage.removeItem('token');
          }
        } catch (error) {
          localStorage.removeItem('token');
        }
      };
      verifyToken();
    }
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
};