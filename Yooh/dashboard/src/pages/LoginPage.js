import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { useNavigate } from "react-router-dom";
import {
  TextField,
  Button,
  Container,
  Typography,
  Box,
  Tabs,
  Tab,
  Paper,
  Alert,
  CircularProgress,
  Divider,
  IconButton,
  InputAdornment,
} from "@mui/material";
import {
  Visibility,
  VisibilityOff,
  Google as GoogleIcon,
  School as SchoolIcon,
} from "@mui/icons-material";

const LoginPage = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [role, setRole] = useState("lecturer");
  const [isLogin, setIsLogin] = useState(true);
  const [showPassword, setShowPassword] = useState(false);
  const [localError, setLocalError] = useState("");

  const { user, loading, error, login, register } = useAuth();
  const navigate = useNavigate();

  // Redirect if already authenticated
  useEffect(() => {
    if (user && !loading) {
      navigate("/dashboard");
    }
  }, [user, loading, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLocalError("");

    try {
      if (isLogin) {
        await login(email, password);
      } else {
        await register(firstName, lastName, email, password, role);
      }
      // Navigation will happen automatically via useEffect when user state changes
    } catch (error) {
      console.error(`Failed to ${isLogin ? "login" : "register"}:`, error);
      setLocalError(
        error.message || `Failed to ${isLogin ? "login" : "register"}`
      );
    }
  };

  const handleGoogleSignIn = async () => {
    setLocalError("");
    try {
      // Google Sign-In will be implemented later
      setLocalError("Google Sign-In not yet implemented for web dashboard");
    } catch (error) {
      console.error("Google Sign-In failed:", error);
      setLocalError(error.message || "Google Sign-In failed");
    }
  };

  const displayError = error || localError;

  if (loading) {
    return (
      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          height: "100vh",
          flexDirection: "column",
          gap: 2,
        }}
      >
        <CircularProgress size={60} />
        <Typography variant="h6" color="text.secondary">
          Loading...
        </Typography>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        minHeight: "100vh",
        background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 2,
      }}
    >
      <Container component="main" maxWidth="sm">
        <Paper
          elevation={24}
          sx={{
            padding: 4,
            borderRadius: 3,
            background: "rgba(255, 255, 255, 0.95)",
            backdropFilter: "blur(10px)",
          }}
        >
          <Box
            sx={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
            }}
          >
            {/* Logo and Title */}
            <Box sx={{ display: "flex", alignItems: "center", mb: 3 }}>
              <SchoolIcon sx={{ fontSize: 40, color: "primary.main", mr: 1 }} />
              <Typography
                component="h1"
                variant="h4"
                fontWeight="bold"
                color="primary.main"
              >
                Yooh
              </Typography>
            </Box>

            <Typography variant="h5" color="text.secondary" sx={{ mb: 3 }}>
              Lecturer Dashboard
            </Typography>

            {/* Tabs */}
            <Tabs
              value={isLogin ? 0 : 1}
              onChange={(e, newValue) => setIsLogin(newValue === 0)}
              centered
              sx={{ mb: 3, width: "100%" }}
            >
              <Tab label="Sign In" />
              <Tab label="Sign Up" />
            </Tabs>

            {/* Error Alert */}
            {displayError && (
              <Alert severity="error" sx={{ width: "100%", mb: 2 }}>
                {displayError}
              </Alert>
            )}
            {/* Form */}
            <Box
              component="form"
              onSubmit={handleSubmit}
              noValidate
              sx={{ width: "100%" }}
            >
              {!isLogin && (
                <Box sx={{ display: "flex", gap: 2, mb: 2 }}>
                  <TextField
                    required
                    fullWidth
                    id="firstName"
                    label="First Name"
                    name="firstName"
                    autoComplete="fname"
                    autoFocus
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    variant="outlined"
                  />
                  <TextField
                    required
                    fullWidth
                    id="lastName"
                    label="Last Name"
                    name="lastName"
                    autoComplete="lname"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    variant="outlined"
                  />
                </Box>
              )}

              <TextField
                margin="normal"
                required
                fullWidth
                id="email"
                label="Email Address"
                name="email"
                autoComplete="email"
                autoFocus={isLogin}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                variant="outlined"
                sx={{ mb: 2 }}
              />

              <TextField
                margin="normal"
                required
                fullWidth
                name="password"
                label="Password"
                type={showPassword ? "text" : "password"}
                id="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                variant="outlined"
                sx={{ mb: 2 }}
                InputProps={{
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        aria-label="toggle password visibility"
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  ),
                }}
              />

              {!isLogin && (
                <TextField
                  margin="normal"
                  required
                  fullWidth
                  select
                  label="Role"
                  value={role}
                  onChange={(e) => setRole(e.target.value)}
                  variant="outlined"
                  sx={{ mb: 2 }}
                  SelectProps={{
                    native: true,
                  }}
                >
                  <option value="lecturer">Lecturer</option>
                  <option value="student">Student</option>
                </TextField>
              )}

              <Button
                type="submit"
                fullWidth
                variant="contained"
                disabled={loading}
                sx={{
                  mt: 2,
                  mb: 2,
                  py: 1.5,
                  fontSize: "1.1rem",
                  fontWeight: "bold",
                  borderRadius: 2,
                  background:
                    "linear-gradient(45deg, #667eea 30%, #764ba2 90%)",
                  "&:hover": {
                    background:
                      "linear-gradient(45deg, #5a6fd8 30%, #6a4190 90%)",
                  },
                }}
              >
                {loading ? (
                  <CircularProgress size={24} color="inherit" />
                ) : isLogin ? (
                  "Sign In"
                ) : (
                  "Sign Up"
                )}
              </Button>

              {/* Divider */}
              <Divider sx={{ my: 2 }}>
                <Typography variant="body2" color="text.secondary">
                  or
                </Typography>
              </Divider>

              {/* Google Sign-In Button */}
              <Button
                fullWidth
                variant="outlined"
                onClick={handleGoogleSignIn}
                disabled={loading}
                sx={{
                  py: 1.5,
                  borderRadius: 2,
                  borderColor: "#dadce0",
                  color: "#3c4043",
                  "&:hover": {
                    backgroundColor: "#f8f9fa",
                    borderColor: "#dadce0",
                  },
                }}
                startIcon={<GoogleIcon />}
              >
                Continue with Google
              </Button>
            </Box>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default LoginPage;
