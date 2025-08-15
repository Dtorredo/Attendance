import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import { TextField, Button, Container, Typography, Box, Tabs, Tab } from '@mui/material';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [role, setRole] = useState('student');
  const [isLogin, setIsLogin] = useState(true);
  const { login, register } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (isLogin) {
        await login(email, password);
      } else {
        await register(firstName, lastName, email, password, role);
      }
      navigate('/dashboard');
    } catch (error) {
      console.error(`Failed to ${isLogin ? 'login' : 'register'}` , error);
      // You can add user-facing error handling here
    }
  };

  return (
    <Container component="main" maxWidth="xs">
      <Box
        sx={{
          marginTop: 8,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
        }}
      >
        <Tabs value={isLogin} onChange={() => setIsLogin(!isLogin)} centered>
          <Tab label="Login" value={true} />
          <Tab label="Register" value={false} />
        </Tabs>
        <Typography component="h1" variant="h5">
          {isLogin ? 'Lecturer Login' : 'Register'}
        </Typography>
        <Box component="form" onSubmit={handleSubmit} noValidate sx={{ mt: 1 }}>
          {!isLogin && (
            <>
              <TextField
                margin="normal"
                required
                fullWidth
                id="firstName"
                label="First Name"
                name="firstName"
                autoComplete="fname"
                autoFocus
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
              />
              <TextField
                margin="normal"
                required
                fullWidth
                id="lastName"
                label="Last Name"
                name="lastName"
                autoComplete="lname"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
              />
            </>
          )}
          <TextField
            margin="normal"
            required
            fullWidth
            id="email"
            label="Email Address"
            name="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <TextField
            margin="normal"
            required
            fullWidth
            name="password"
            label="Password"
            type="password"
            id="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
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
              SelectProps={{
                native: true,
              }}
            >
              <option value="student">Student</option>
              <option value="lecturer">Lecturer</option>
            </TextField>
          )}
          <Button
            type="submit"
            fullWidth
            variant="contained"
            sx={{ mt: 3, mb: 2 }}
          >
            {isLogin ? 'Sign In' : 'Sign Up'}
          </Button>
        </Box>
      </Box>
    </Container>
  );
};

export default LoginPage;