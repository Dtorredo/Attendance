import React from 'react';
import { BrowserRouter as Router, Route, Routes, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import AttendancePage from './pages/AttendancePage';
import ManagementPage from './pages/ManagementPage';
import PrivateRoute from './hocs/PrivateRoute';
import Layout from './hocs/Layout';
import { CssBaseline, ThemeProvider, createTheme } from '@mui/material';

// Professional Blue and White color scheme
const theme = createTheme({
  palette: {
    primary: {
      main: '#007AFF', // Professional Blue
    },
    background: {
      default: '#FFFFFF', // Clean White
      paper: '#FFFFFF',
    },
    text: {
      primary: '#000000', // Solid Black
      secondary: '#48484A', // Dark Gray for secondary
    },
  },
  typography: {
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    h4: {
      fontWeight: 700,
      color: '#000000',
    },
    h5: {
      fontWeight: 700,
      color: '#000000',
    },
    h6: {
      fontWeight: 700,
      color: '#000000',
    },
    button: {
      textTransform: 'none',
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 6,
          boxShadow: 'none',
          '&:hover': {
            boxShadow: 'none',
          },
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: '#007AFF',
          boxShadow: 'none',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          border: '1px solid #E5E5EA',
          boxShadow: 'none',
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
            <Route element={<PrivateRoute />}>
              <Route element={<Layout />}>
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/attendance" element={<AttendancePage />} />
                <Route path="/management" element={<ManagementPage />} />
              </Route>
            </Route>
            <Route path="*" element={<Navigate to="/dashboard" />} />
          </Routes>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
