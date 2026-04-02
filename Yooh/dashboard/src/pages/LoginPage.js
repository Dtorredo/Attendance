import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import authService from "../services/authService";
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
  IconButton,
  InputAdornment,
  Dialog,
  Divider,
} from "@mui/material";
import {
  Visibility,
  VisibilityOff,
  School as SchoolIcon,
  CheckCircle as CheckCircleIcon,
  Google as GoogleIcon,
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
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetSuccess, setResetSuccess] = useState(false);
  const [resetLoading, setResetLoading] = useState(false);

  const { user, loading, error, login, register, resetPassword } = useAuth();
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
    } catch (error) {
      console.error(`Failed to ${isLogin ? "login" : "register"}:`, error);
      setLocalError(
        error.message || `Failed to ${isLogin ? "login" : "register"}`
      );
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    setLocalError("");
    setResetLoading(true);

    try {
      const result = await resetPassword(resetEmail);
      if (result.success) {
        setResetSuccess(true);
      } else {
        setLocalError(result.error || "Failed to send reset email");
      }
    } catch (error) {
      setLocalError(error.message || "Failed to send reset email");
    } finally {
      setResetLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setLocalError("");
    try {
      const result = await authService.signInWithGoogle();
      if (!result.success) {
        throw new Error(result.error);
      }
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
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 4,
        background: "#F2F2F7",
      }}
    >
      <Container component="main" maxWidth="xs">
        <Paper
          elevation={0}
          sx={{
            padding: 4,
            borderRadius: 3,
            background: "white",
          }}
        >
          <Box
            sx={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
            }}
          >
            {/* Logo */}
            <Box sx={{ display: "flex", alignItems: "center", mb: 3 }}>
              <SchoolIcon sx={{ fontSize: 32, color: "primary.main", mr: 1 }} />
              <Typography
                component="h1"
                variant="h5"
                fontWeight="bold"
                color="primary.main"
              >
                Yooh
              </Typography>
            </Box>

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
                sx={{ mb: 1 }}
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
              {isLogin && (
                <Box sx={{ display: "flex", justifyContent: "flex-end", mb: 2 }}>
                  <Button
                    size="small"
                    onClick={() => {
                      setShowForgotPassword(true);
                      setResetEmail(email);
                    }}
                    sx={{ textTransform: "none", fontWeight: "bold" }}
                  >
                    Forgot Password?
                  </Button>
                </Box>
              )}

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
                  fontSize: "1rem",
                  fontWeight: "600",
                  borderRadius: 2,
                }}
              >
                {loading ? (
                  <CircularProgress size={24} color="inherit" />
                ) : isLogin ? (
                  "Sign In"
                ) : (
                  "Create Account"
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

              {/* Footer text */}
              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ mt: 3, textAlign: "center" }}
              >
                {isLogin
                  ? "Don't have an account? "
                  : "Already have an account? "}
                <Button
                  onClick={() => setIsLogin(!isLogin)}
                  sx={{ textTransform: "none", fontWeight: "bold" }}
                >
                  {isLogin ? "Sign Up" : "Sign In"}
                </Button>
              </Typography>
            </Box>
          </Box>
        </Paper>
      </Container>

      {/* Forgot Password Dialog */}
      <Dialog
        open={showForgotPassword}
        onClose={() => {
          setShowForgotPassword(false);
          setResetSuccess(false);
          setLocalError("");
        }}
        maxWidth="sm"
        fullWidth
      >
        <Box
          sx={{
            p: 3,
            background: resetSuccess
              ? "linear-gradient(135deg, #34C759 0%, #30B350 100%)"
              : "linear-gradient(135deg, #007AFF 0%, #5856D6 100%)",
            color: "white",
            borderRadius: 3,
            m: 2,
          }}
        >
          <Box sx={{ textAlign: "center", mb: 2 }}>
            {resetSuccess ? (
              <CheckCircleIcon sx={{ fontSize: 64, mb: 1 }} />
            ) : (
              <SchoolIcon sx={{ fontSize: 64, mb: 1 }} />
            )}
            <Typography variant="h5" fontWeight="bold">
              {resetSuccess ? "Email Sent!" : "Forgot Password?"}
            </Typography>
          </Box>

          {resetSuccess ? (
            <Box sx={{ textAlign: "center" }}>
              <Typography variant="body1" sx={{ mb: 2 }}>
                We've sent a password reset link to:
              </Typography>
              <Typography variant="h6" fontWeight="bold" sx={{ mb: 2 }}>
                {resetEmail}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                Please check your email and follow the instructions to reset your
                password.
              </Typography>
            </Box>
          ) : (
            <Box component="form" onSubmit={handleResetPassword}>
              <Typography variant="body1" sx={{ mb: 2 }}>
                Enter your email address and we'll send you instructions to reset
                your password.
              </Typography>
              <TextField
                fullWidth
                label="Email Address"
                type="email"
                value={resetEmail}
                onChange={(e) => setResetEmail(e.target.value)}
                required
                sx={{
                  mb: 2,
                  "& .MuiOutlinedInput-root": {
                    backgroundColor: "white",
                  },
                }}
              />
              {localError && (
                <Alert severity="error" sx={{ mb: 2 }}>
                  {localError}
                </Alert>
              )}
              <Box sx={{ display: "flex", gap: 2 }}>
                <Button
                  fullWidth
                  variant="outlined"
                  onClick={() => {
                    setShowForgotPassword(false);
                    setResetSuccess(false);
                    setLocalError("");
                  }}
                  disabled={resetLoading}
                  sx={{
                    color: "white",
                    borderColor: "white",
                    "&:hover": {
                      borderColor: "white",
                      backgroundColor: "rgba(255,255,255,0.1)",
                    },
                  }}
                >
                  Cancel
                </Button>
                <Button
                  fullWidth
                  type="submit"
                  variant="contained"
                  disabled={resetLoading}
                  sx={{
                    backgroundColor: "white",
                    color: "#007AFF",
                    "&:hover": {
                      backgroundColor: "rgba(255,255,255,0.9)",
                    },
                  }}
                >
                  {resetLoading ? <CircularProgress size={24} /> : "Send Reset Link"}
                </Button>
              </Box>
            </Box>
          )}
        </Box>
      </Dialog>
    </Box>
  );
};

export default LoginPage;
