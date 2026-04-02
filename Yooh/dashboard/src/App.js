import React from 'react';
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import AttendancePage from './pages/AttendancePage';
import NotificationsPage from './pages/NotificationsPage';
import PrivateRoute from './hocs/PrivateRoute';
import { CssBaseline, ThemeProvider, createTheme } from '@mui/material';

// iOS Blue color scheme to match the iOS app
const theme = createTheme({
  palette: {
    primary: {
      main: '#007AFF', // iOS System Blue
    },
    secondary: {
      main: '#5856D6', // iOS System Purple
    },
    success: {
      main: '#34C759', // iOS System Green
    },
    error: {
      main: '#FF3B30', // iOS System Red
    },
    warning: {
      main: '#FF9500', // iOS System Orange
    },
    info: {
      main: '#5AC8FA', // iOS System Mint
    },
    background: {
      default: '#F2F2F7', // iOS System Gray 6
    },
  },
  typography: {
    fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    h4: {
      fontWeight: 600,
      fontSize: '1.75rem',
    },
    h5: {
      fontWeight: 600,
      fontSize: '1.5rem',
    },
    h6: {
      fontWeight: 600,
      fontSize: '1.25rem',
    },
    button: {
      textTransform: 'none',
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          padding: '12px 24px',
          fontWeight: 600,
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: 'none',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          boxShadow: '0 2px 8px rgba(0, 0, 0, 0.08)',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 16,
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 600,
        },
      },
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <Router>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/dashboard" element={<PrivateRoute />}>
              <Route path="" element={<DashboardPage />} />
            </Route>
            <Route path="/attendance" element={<PrivateRoute />}>
              <Route path="" element={<AttendancePage />} />
            </Route>
            <Route path="/notifications" element={<PrivateRoute />}>
              <Route path="" element={<NotificationsPage />} />
            </Route>
            <Route path="*" element={<Navigate to="/dashboard" />} />
          </Routes>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
