import React, { useState } from 'react';
import { useQuery } from 'convex/react';
import { api } from '../../convex/_generated/api';
import { useAuth } from '../context/AuthContext';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Container,
  CircularProgress,
  Box,
  Button,
  TableSortLabel
} from '@mui/material';
import { useNavigate } from 'react-router-dom';

const DashboardPage = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [order, setOrder] = useState('asc');
  const [orderBy, setOrderBy] = useState('last_name');

  const attendanceData = useQuery(api.dashboard.getAttendance, {
    lecturer_id: user ? user._id : null,
  });

  const handleSortRequest = (property) => {
    const isAsc = orderBy === property && order === 'asc';
    setOrder(isAsc ? 'desc' : 'asc');
    setOrderBy(property);
  };

  const sortedData = React.useMemo(() => {
    if (!attendanceData) return [];
    const comparator = (a, b) => {
      let valA = a[orderBy];
      let valB = b[orderBy];
      if (orderBy === 'attendancePercentage') {
        valA = parseFloat(valA);
        valB = parseFloat(valB);
      }
      if (valB < valA) {
        return order === 'asc' ? 1 : -1;
      }
      if (valB > valA) {
        return order === 'asc' ? -1 : 1;
      }
      return 0;
    };
    return [...attendanceData].sort(comparator);
  }, [attendanceData, order, orderBy]);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  if (attendanceData === undefined) {
    return <Container><Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}><CircularProgress /></Box></Container>;
  }

  return (
    <Container sx={{ mt: 4 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h4" component="h1">
          Student Attendance Dashboard
        </Typography>
        <Button variant="outlined" onClick={handleLogout}>Logout</Button>
      </Box>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>
                <TableSortLabel
                  active={orderBy === 'first_name'}
                  direction={orderBy === 'first_name' ? order : 'asc'}
                  onClick={() => handleSortRequest('first_name')}
                >
                  First Name
                </TableSortLabel>
              </TableCell>
              <TableCell>
                <TableSortLabel
                  active={orderBy === 'last_name'}
                  direction={orderBy === 'last_name' ? order : 'asc'}
                  onClick={() => handleSortRequest('last_name')}
                >
                  Last Name
                </TableSortLabel>
              </TableCell>
              <TableCell align="right">
                <TableSortLabel
                  active={orderBy === 'attendancePercentage'}
                  direction={orderBy === 'attendancePercentage' ? order : 'asc'}
                  onClick={() => handleSortRequest('attendancePercentage')}
                >
                  Attendance
                </TableSortLabel>
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {sortedData.map((student) => (
              <TableRow
                key={student._id}
                sx={{
                  backgroundColor: parseFloat(student.attendancePercentage) < 70 ? 'rgba(255, 0, 0, 0.1)' : 'inherit'
                }}
              >
                <TableCell>{student.first_name}</TableCell>
                <TableCell>{student.last_name}</TableCell>
                <TableCell align="right">{student.attendancePercentage}%</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Container>
  );
};

export default DashboardPage;