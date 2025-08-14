
import React, { createContext, useState, useEffect } from 'react';
import axios from 'axios';

const AuthContext = createContext();

const AuthProvider = ({ children }) => {
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadUser = async () => {
      if (token) {
        axios.defaults.headers.common['x-auth-token'] = token;
      } else {
        delete axios.defaults.headers.common['x-auth-token'];
      }

      try {
        // The backend doesn't have a /api/auth/me endpoint yet.
        // We will need to add it later to get the user details from the token.
        // For now, we can decode the token or just set user if token exists.
        if (token) {
            // A simple user object based on token existence.
            // For a real app, you would decode the token or fetch from backend.
            setUser({ isAuthenticated: true });
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    loadUser();
  }, [token]);

  const login = async (email, password) => {
    const config = {
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const body = JSON.stringify({ email, password });

    try {
      const res = await axios.post('http://localhost:5001/api/auth/login', body, config);
      localStorage.setItem('token', res.data.token);
      setToken(res.data.token);
    } catch (err) {
      console.error(err.response.data);
      // Handle login error (e.g., show a message to the user)
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ token, user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export { AuthContext, AuthProvider };
