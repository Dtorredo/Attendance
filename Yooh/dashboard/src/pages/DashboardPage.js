import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import dataService from "../services/dataService";
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
  TableSortLabel,
  Alert,
  AppBar,
  Toolbar,
  Chip,
  Card,
  CardContent,
  Grid,
} from "@mui/material";
import {
  School as SchoolIcon,
  People as PeopleIcon,
  Assignment as AssignmentIcon,
  EventAvailable as AttendanceIcon,
} from "@mui/icons-material";
import { useNavigate } from "react-router-dom";

const DashboardPage = () => {
  const { user, userRole, logout } = useAuth();
  const navigate = useNavigate();
  const [order, setOrder] = useState("asc");
  const [orderBy, setOrderBy] = useState("lastName");

  const [students, setStudents] = useState([]);
  const [attendance, setAttendance] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [classes, setClasses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    console.log(
      "🔍 Dashboard useEffect - userRole:",
      userRole,
      "user:",
      user?.email
    );

    if (userRole === "lecturer") {
      console.log("✅ User is lecturer, loading dashboard data...");
      loadDashboardData();
    } else if (userRole && userRole !== "lecturer") {
      console.log("❌ User is not lecturer, role:", userRole);
      setError(
        "Access denied. This dashboard is only available for lecturers."
      );
      setLoading(false);
    } else if (userRole === null && user) {
      console.log("⚠️ User exists but role is null, user:", user.email);
      setError(
        "Unable to determine user role. Please try logging out and back in."
      );
      setLoading(false);
    }
  }, [userRole, user]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      setError("");
      console.log("🔄 Loading dashboard data...");

      // Load all data
      const [usersData, attendanceData, assignmentsData, classesData] =
        await Promise.all([
          dataService.getAllUsers(),
          dataService.getAllData("attendance", "timestamp"),
          dataService.getAllData("assignments", "dueDate"),
          dataService.getAllData("classes", "startDate"),
        ]);

      console.log("📊 Data loaded:", {
        users: usersData.length,
        attendance: attendanceData.length,
        assignments: assignmentsData.length,
        classes: classesData.length,
      });

      // Filter students only
      const studentsOnly = usersData.filter((user) => user.role === "student");

      setStudents(studentsOnly);
      setAttendance(attendanceData);
      setAssignments(assignmentsData);
      setClasses(classesData);
    } catch (error) {
      console.error("❌ Error loading dashboard data:", error);
      setError("Failed to load dashboard data: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const getStudentStats = (student) => {
    const studentAttendance = attendance.filter(
      (record) => record.userId === student.id
    );
    const studentAssignments = assignments.filter(
      (assignment) => assignment.userId === student.id
    );

    const totalClasses = studentAttendance.length;
    const attendedClasses = studentAttendance.filter(
      (record) => record.status === "present"
    ).length;
    const attendanceRate =
      totalClasses > 0 ? Math.round((attendedClasses / totalClasses) * 100) : 0;

    const totalAssignments = studentAssignments.length;
    const completedAssignments = studentAssignments.filter(
      (assignment) => assignment.isCompleted
    ).length;
    const completionRate =
      totalAssignments > 0
        ? Math.round((completedAssignments / totalAssignments) * 100)
        : 0;

    return {
      attendance: {
        total: totalClasses,
        attended: attendedClasses,
        rate: attendanceRate,
      },
      assignments: {
        total: totalAssignments,
        completed: completedAssignments,
        rate: completionRate,
      },
    };
  };

  const handleSortRequest = (property) => {
    const isAsc = orderBy === property && order === "asc";
    setOrder(isAsc ? "desc" : "asc");
    setOrderBy(property);
  };

  const sortedStudents = React.useMemo(() => {
    if (!students.length) return [];

    const studentsWithStats = students.map((student) => ({
      ...student,
      stats: getStudentStats(student),
    }));

    const comparator = (a, b) => {
      let valA, valB;

      if (orderBy === "firstName") {
        valA = a.firstName || "";
        valB = b.firstName || "";
      } else if (orderBy === "lastName") {
        valA = a.lastName || "";
        valB = b.lastName || "";
      } else if (orderBy === "attendanceRate") {
        valA = a.stats.attendance.rate;
        valB = b.stats.attendance.rate;
      } else if (orderBy === "assignmentRate") {
        valA = a.stats.assignments.rate;
        valB = b.stats.assignments.rate;
      } else {
        return 0;
      }

      if (typeof valA === "string") {
        valA = valA.toLowerCase();
        valB = valB.toLowerCase();
      }

      if (valB < valA) {
        return order === "asc" ? 1 : -1;
      }
      if (valB > valA) {
        return order === "asc" ? -1 : 1;
      }
      return 0;
    };

    return studentsWithStats.sort(comparator);
  }, [students, attendance, assignments, order, orderBy]);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  if (loading) {
    return (
      <Container>
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
            Loading dashboard data...
          </Typography>
        </Box>
      </Container>
    );
  }

  if (error) {
    return (
      <Container sx={{ mt: 4 }}>
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
        <Box sx={{ display: "flex", gap: 2 }}>
          <Button variant="contained" onClick={() => window.location.reload()}>
            Retry
          </Button>
          <Button variant="outlined" onClick={handleLogout}>
            Logout & Sign Up as Lecturer
          </Button>
        </Box>
      </Container>
    );
  }

  return (
    <Box sx={{ flexGrow: 1 }}>
      {/* App Bar */}
      <AppBar
        position="static"
        sx={{ background: "linear-gradient(45deg, #667eea 30%, #764ba2 90%)" }}
      >
        <Toolbar>
          <SchoolIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Yooh - Lecturer Dashboard
          </Typography>
          <Typography variant="body2" sx={{ mr: 2 }}>
            Welcome, {user?.email}
          </Typography>
          <Button color="inherit" onClick={handleLogout}>
            Logout
          </Button>
        </Toolbar>
      </AppBar>

      <Container sx={{ mt: 4, mb: 4 }}>
        {/* Stats Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: "flex", alignItems: "center" }}>
                  <PeopleIcon
                    sx={{ fontSize: 40, color: "primary.main", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" gutterBottom>
                      Total Students
                    </Typography>
                    <Typography variant="h4">{students.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: "flex", alignItems: "center" }}>
                  <AttendanceIcon
                    sx={{ fontSize: 40, color: "success.main", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" gutterBottom>
                      Total Attendance Records
                    </Typography>
                    <Typography variant="h4">{attendance.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: "flex", alignItems: "center" }}>
                  <AssignmentIcon
                    sx={{ fontSize: 40, color: "warning.main", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" gutterBottom>
                      Total Assignments
                    </Typography>
                    <Typography variant="h4">{assignments.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box sx={{ display: "flex", alignItems: "center" }}>
                  <SchoolIcon
                    sx={{ fontSize: 40, color: "info.main", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" gutterBottom>
                      Total Classes
                    </Typography>
                    <Typography variant="h4">{classes.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Students Table */}
        <Paper sx={{ width: "100%", overflow: "hidden" }}>
          <Box sx={{ p: 2 }}>
            <Typography variant="h5" component="h2" gutterBottom>
              Student Performance Overview
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Track attendance rates and assignment completion for all students
            </Typography>
          </Box>

          <TableContainer>
            <Table stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell>
                    <TableSortLabel
                      active={orderBy === "firstName"}
                      direction={orderBy === "firstName" ? order : "asc"}
                      onClick={() => handleSortRequest("firstName")}
                    >
                      First Name
                    </TableSortLabel>
                  </TableCell>
                  <TableCell>
                    <TableSortLabel
                      active={orderBy === "lastName"}
                      direction={orderBy === "lastName" ? order : "asc"}
                      onClick={() => handleSortRequest("lastName")}
                    >
                      Last Name
                    </TableSortLabel>
                  </TableCell>
                  <TableCell align="center">Email</TableCell>
                  <TableCell align="center">
                    <TableSortLabel
                      active={orderBy === "attendanceRate"}
                      direction={orderBy === "attendanceRate" ? order : "asc"}
                      onClick={() => handleSortRequest("attendanceRate")}
                    >
                      Attendance Rate
                    </TableSortLabel>
                  </TableCell>
                  <TableCell align="center">
                    <TableSortLabel
                      active={orderBy === "assignmentRate"}
                      direction={orderBy === "assignmentRate" ? order : "asc"}
                      onClick={() => handleSortRequest("assignmentRate")}
                    >
                      Assignment Completion
                    </TableSortLabel>
                  </TableCell>
                  <TableCell align="center">Classes Attended</TableCell>
                  <TableCell align="center">Assignments Done</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {sortedStudents.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                      <Typography variant="body1" color="text.secondary">
                        No student data available yet
                      </Typography>
                    </TableCell>
                  </TableRow>
                ) : (
                  sortedStudents.map((student) => (
                    <TableRow
                      key={student.id}
                      sx={{
                        backgroundColor:
                          student.stats.attendance.rate < 70
                            ? "rgba(255, 152, 0, 0.1)"
                            : "inherit",
                        "&:hover": {
                          backgroundColor: "rgba(0, 0, 0, 0.04)",
                        },
                      }}
                    >
                      <TableCell>{student.firstName || "N/A"}</TableCell>
                      <TableCell>{student.lastName || "N/A"}</TableCell>
                      <TableCell align="center">{student.email}</TableCell>
                      <TableCell align="center">
                        <Chip
                          label={`${student.stats.attendance.rate}%`}
                          color={
                            student.stats.attendance.rate >= 80
                              ? "success"
                              : student.stats.attendance.rate >= 70
                              ? "warning"
                              : "error"
                          }
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={`${student.stats.assignments.rate}%`}
                          color={
                            student.stats.assignments.rate >= 80
                              ? "success"
                              : student.stats.assignments.rate >= 70
                              ? "warning"
                              : "error"
                          }
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell align="center">
                        {student.stats.attendance.attended} /{" "}
                        {student.stats.attendance.total}
                      </TableCell>
                      <TableCell align="center">
                        {student.stats.assignments.completed} /{" "}
                        {student.stats.assignments.total}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
      </Container>
    </Box>
  );
};

export default DashboardPage;
