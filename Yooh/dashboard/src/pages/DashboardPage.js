import React, { useState, useEffect, useCallback, useMemo } from "react";
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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Fab,
  Tabs,
  Tab,
  Tooltip,
  IconButton,
  InputAdornment,
  Badge,
} from "@mui/material";
import {
  School as SchoolIcon,
  People as PeopleIcon,
  Assignment as AssignmentIcon,
  EventAvailable as AttendanceIcon,
  Class as ClassIcon,
  Search as SearchIcon,
  Download as DownloadIcon,
  Warning as WarningIcon,
  TrendingUp as TrendingUpIcon,
  Delete as DeleteIcon,
  Notifications as NotificationsIcon,
  Dashboard as DashboardIcon,
  ListAlt as ListAltIcon,
} from "@mui/icons-material";
import { useNavigate } from "react-router-dom";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
} from "recharts";

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

  // Search and filter state
  const [searchTerm, setSearchTerm] = useState("");

  // Dialog states
  const [openClassDialog, setOpenClassDialog] = useState(false);
  const [openAssignmentDialog, setOpenAssignmentDialog] = useState(false);
  const [openAttendanceDialog, setOpenAttendanceDialog] = useState(false);
  const [activeTab, setActiveTab] = useState(0);

  // Class form state
  const [classForm, setClassForm] = useState({
    name: "",
    description: "",
    dayOfWeek: "",
    startTime: "",
    endTime: "",
    startDate: "",
    endDate: "",
    location: "",
    selectedStudents: [],
  });

  // Assignment form state
  const [assignmentForm, setAssignmentForm] = useState({
    title: "",
    description: "",
    dueDate: "",
    dueTime: "",
    priority: "Medium",
    selectedStudents: [],
  });

  // Attendance record for editing
  const [selectedAttendanceRecord, setSelectedAttendanceRecord] = useState(null);

  // Real-time setup
  useEffect(() => {
    console.log("🔍 Dashboard useEffect - userRole:", userRole, "user:", user?.email);

    if (userRole === "lecturer") {
      console.log("✅ User is lecturer, setting up real-time listeners...");
      setupRealTimeListeners();
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

    // Cleanup on unmount
    return () => {
      dataService.unsubscribeAll();
    };
  }, [userRole, user]);

  const setupRealTimeListeners = async () => {
    try {
      setLoading(true);
      setError("");

      // Load users once (doesn't change often)
      const usersData = await dataService.getAllUsers();
      const studentsOnly = usersData.filter((user) => user.role === "student");
      setStudents(studentsOnly);

      // Set up real-time listeners for dynamic data
      dataService.subscribeToAllData("attendance", (attendanceData) => {
        setAttendance(attendanceData);
      }, "timestamp");

      dataService.subscribeToAllData("assignments", (assignmentsData) => {
        setAssignments(assignmentsData);
      }, "dueDate");

      dataService.subscribeToAllData("classes", (classesData) => {
        setClasses(classesData);
      }, "startDate");
    } catch (error) {
      console.error("❌ Error setting up listeners:", error);
      setError("Failed to load dashboard data: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const getStudentStats = useCallback(
    (student) => {
      const studentAttendance = attendance.filter(
        (record) => record.userId === student.id
      );
      const studentClasses = classes.filter((c) => c.userId === student.id);
      const studentAssignments = assignments.filter(
        (assignment) => assignment.userId === student.id
      );

      const totalClasses = studentClasses.length;
      const attendedClasses = studentAttendance.filter(
        (record) => record.status === "present"
      ).length;
      const attendanceRate =
        totalClasses > 0
          ? Math.round((attendedClasses / totalClasses) * 100)
          : 0;

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
    },
    [attendance, classes, assignments]
  );

  const handleSortRequest = (property) => {
    const isAsc = orderBy === property && order === "asc";
    setOrder(isAsc ? "desc" : "asc");
    setOrderBy(property);
  };

  // Filter students by search term
  const filteredStudents = useMemo(() => {
    if (!searchTerm) return students;
    const search = searchTerm.toLowerCase();
    return students.filter(
      (student) =>
        student.firstName?.toLowerCase().includes(search) ||
        student.lastName?.toLowerCase().includes(search) ||
        student.email?.toLowerCase().includes(search)
    );
  }, [students, searchTerm]);

  const sortedStudents = useMemo(() => {
    if (!filteredStudents.length) return [];

    const studentsWithStats = filteredStudents.map((student) => ({
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
  }, [filteredStudents, order, orderBy, getStudentStats]);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  // Export to CSV
  const exportToCSV = () => {
    const headers = [
      "First Name",
      "Last Name",
      "Email",
      "Attendance Rate",
      "Assignment Rate",
      "Classes Attended",
      "Assignments Completed",
    ];
    const rows = sortedStudents.map((s) => [
      s.firstName || "",
      s.lastName || "",
      s.email || "",
      `${s.stats.attendance.rate}%`,
      `${s.stats.assignments.rate}%`,
      `${s.stats.attendance.attended}/${s.stats.attendance.total}`,
      `${s.stats.assignments.completed}/${s.stats.assignments.total}`,
    ]);

    const csvContent = [headers, ...rows].map((e) => e.join(",")).join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `student-report-${new Date().toISOString().split("T")[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  // Class creation functions
  const handleCreateClass = async () => {
    try {
      console.log("🔄 Creating class:", classForm);

      for (const studentId of classForm.selectedStudents) {
        const startDateTime = new Date(
          `${classForm.startDate}T${classForm.startTime}`
        );
        const endDateTime = new Date(
          `${classForm.endDate}T${classForm.endTime}`
        );

        const classData = {
          title: classForm.name,
          description: classForm.description,
          dayOfWeek: classForm.dayOfWeek,
          startDate: startDateTime.toISOString(),
          endDate: endDateTime.toISOString(),
          location: classForm.location,
          notes: classForm.description,
          createdBy: user.uid,
          isRecurring: true,
        };

        await dataService.createClassForStudent(classData, studentId);
      }

      console.log("✅ Class created successfully");
      setOpenClassDialog(false);
      resetClassForm();
    } catch (error) {
      console.error("❌ Error creating class:", error);
      setError("Failed to create class: " + error.message);
    }
  };

  const handleCreateAssignment = async () => {
    try {
      console.log("🔄 Creating assignment:", assignmentForm);

      for (const studentId of assignmentForm.selectedStudents) {
        const assignmentData = {
          title: assignmentForm.title,
          details: assignmentForm.description,
          dueDate: `${assignmentForm.dueDate}T${assignmentForm.dueTime}`,
          priority: assignmentForm.priority,
        };

        await dataService.createAssignmentForStudent(assignmentData, studentId);
      }

      console.log("✅ Assignment created successfully");
      setOpenAssignmentDialog(false);
      resetAssignmentForm();
    } catch (error) {
      console.error("❌ Error creating assignment:", error);
      setError("Failed to create assignment: " + error.message);
    }
  };

  const handleDeleteAttendance = async (recordId) => {
    if (window.confirm("Are you sure you want to delete this attendance record?")) {
      try {
        await dataService.deleteAttendance(recordId);
        setOpenAttendanceDialog(false);
      } catch (error) {
        console.error("❌ Error deleting attendance:", error);
        alert("Failed to delete attendance record");
      }
    }
  };

  const handleUpdateAttendance = async () => {
    try {
      await dataService.updateAttendance(selectedAttendanceRecord.id, {
        status: selectedAttendanceRecord.status,
      });
      setOpenAttendanceDialog(false);
    } catch (error) {
      console.error("❌ Error updating attendance:", error);
      alert("Failed to update attendance record");
    }
  };

  const resetClassForm = () => {
    setClassForm({
      name: "",
      description: "",
      dayOfWeek: "",
      startTime: "",
      endTime: "",
      startDate: "",
      endDate: "",
      location: "",
      selectedStudents: [],
    });
  };

  const resetAssignmentForm = () => {
    setAssignmentForm({
      title: "",
      description: "",
      dueDate: "",
      dueTime: "",
      priority: "Medium",
      selectedStudents: [],
    });
  };

  // Get at-risk students
  const atRiskStudents = useMemo(() => {
    return sortedStudents.filter((s) => s.stats.attendance.rate < 70);
  }, [sortedStudents]);

  // Prepare chart data
  const chartData = useMemo(() => {
    return sortedStudents.slice(0, 10).map((s) => ({
      name: `${s.firstName?.charAt(0) || ""}. ${s.lastName || ""}`,
      attendance: s.stats.attendance.rate,
      assignments: s.stats.assignments.rate,
    }));
  }, [sortedStudents]);

  const attendanceDistributionData = useMemo(() => {
    // Calculate distribution based on actual student performance rates
    const excellent = sortedStudents.filter((s) => s.stats.attendance.rate >= 90).length;
    const good = sortedStudents.filter(
      (s) => s.stats.attendance.rate >= 75 && s.stats.attendance.rate < 90
    ).length;
    const average = sortedStudents.filter(
      (s) => s.stats.attendance.rate >= 60 && s.stats.attendance.rate < 75
    ).length;
    const atRisk = sortedStudents.filter((s) => s.stats.attendance.rate < 60).length;

    return [
      { name: "Excellent (90%+)", value: excellent, color: "#007AFF" },
      { name: "Good (75-89%)", value: good, color: "#5AC8FA" },
      { name: "Average (60-74%)", value: average, color: "#D1D1D6" },
      { name: "At Risk (<60%)", value: atRisk, color: "#8E8E93" },
    ];
  }, [sortedStudents]);

  const recentAttendanceData = useMemo(() => {
    const last7Days = [];
    const today = new Date();
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const dateStr = date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
      const dayAttendance = attendance.filter((record) => {
        const recordDate = record.timestamp?.toDate?.() || new Date(record.timestamp);
        return (
          recordDate.toDateString() === date.toDateString() &&
          record.status === "present"
        );
      }).length;
      last7Days.push({ date: dateStr, count: dayAttendance });
    }
    return last7Days;
  }, [attendance]);

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
      <Container sx={{ mt: 2, mb: 4 }}>
        {/* At-Risk Alert */}
        {atRiskStudents.length > 0 && (
          <Alert
            severity="info"
            sx={{ 
              mb: 3, 
              backgroundColor: '#F2F2F7', 
              color: '#007AFF',
              border: '1px solid #007AFF',
              '& .MuiAlert-icon': { color: '#007AFF' }
            }}
            icon={<TrendingUpIcon fontSize="inherit" />}
          >
            <Typography variant="subtitle2" fontWeight="bold">
              Institutional Insight: {atRiskStudents.length} student(s) have attendance below 70%
            </Typography>
            <Typography variant="caption">
              {atRiskStudents.slice(0, 8).map((s) => `${s.firstName} ${s.lastName}`).join(", ")}
              {atRiskStudents.length > 8 && ` +${atRiskStudents.length - 8} others`}
            </Typography>
          </Alert>
        )}

        {/* Stats Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }} alignItems="stretch">
          <Grid item xs={12} sm={6} md={3} sx={{ display: 'flex' }}>
            <Card
              sx={{
                flexGrow: 1,
                borderRadius: 1,
                border: "1px solid #E5E5EA",
                backgroundColor: "#FFFFFF",
                transition: "all .2s ease",
                boxShadow: "none",
                "&:hover": { borderColor: "#007AFF" },
              }}
            >
              <CardContent sx={{ height: '100%', display: 'flex', alignItems: 'center' }}>
                <Box sx={{ display: "flex", alignItems: "center", width: '100%' }}>
                  <PeopleIcon
                    sx={{ fontSize: 32, color: "#007AFF", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" variant="caption" sx={{ textTransform: 'uppercase', fontWeight: 600, letterSpacing: 1 }}>
                      Total Students
                    </Typography>
                    <Typography variant="h4" fontWeight="bold">{students.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3} sx={{ display: 'flex' }}>
            <Card
              sx={{
                flexGrow: 1,
                borderRadius: 1,
                border: "1px solid #E5E5EA",
                backgroundColor: "#FFFFFF",
                transition: "all .2s ease",
                boxShadow: "none",
                "&:hover": { borderColor: "#007AFF" },
              }}
            >
              <CardContent sx={{ height: '100%', display: 'flex', alignItems: 'center' }}>
                <Box sx={{ display: "flex", alignItems: "center", width: '100%' }}>
                  <AttendanceIcon
                    sx={{ fontSize: 32, color: "#007AFF", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" variant="caption" sx={{ textTransform: 'uppercase', fontWeight: 600, letterSpacing: 1 }}>
                      Attendance Records
                    </Typography>
                    <Typography variant="h4" fontWeight="bold">{attendance.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3} sx={{ display: 'flex' }}>
            <Card
              sx={{
                flexGrow: 1,
                borderRadius: 1,
                border: "1px solid #E5E5EA",
                backgroundColor: "#FFFFFF",
                transition: "all .2s ease",
                boxShadow: "none",
                "&:hover": { borderColor: "#007AFF" },
              }}
            >
              <CardContent sx={{ height: '100%', display: 'flex', alignItems: 'center' }}>
                <Box sx={{ display: "flex", alignItems: "center", width: '100%' }}>
                  <AssignmentIcon
                    sx={{ fontSize: 32, color: "#007AFF", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" variant="caption" sx={{ textTransform: 'uppercase', fontWeight: 600, letterSpacing: 1 }}>
                      Total Assignments
                    </Typography>
                    <Typography variant="h4" fontWeight="bold">{assignments.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} sm={6} md={3} sx={{ display: 'flex' }}>
            <Card
              sx={{
                flexGrow: 1,
                borderRadius: 1,
                border: "1px solid #E5E5EA",
                backgroundColor: "#FFFFFF",
                transition: "all .2s ease",
                boxShadow: "none",
                "&:hover": { borderColor: "#007AFF" },
              }}
            >
              <CardContent sx={{ height: '100%', display: 'flex', alignItems: 'center' }}>
                <Box sx={{ display: "flex", alignItems: "center", width: '100%' }}>
                  <SchoolIcon
                    sx={{ fontSize: 32, color: "#007AFF", mr: 2 }}
                  />
                  <Box>
                    <Typography color="textSecondary" variant="caption" sx={{ textTransform: 'uppercase', fontWeight: 600, letterSpacing: 1 }}>
                      Total Classes
                    </Typography>
                    <Typography variant="h4" fontWeight="bold">{classes.length}</Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Analytics Charts */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} md={7}>
            <Paper sx={{ p: 3, height: '100%' }}>
              <Typography variant="h6" gutterBottom fontWeight="bold">
                <TrendingUpIcon sx={{ mr: 1, verticalAlign: "middle" }} />
                Student Performance Comparison
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} />
                  <YAxis axisLine={false} tickLine={false} />
                  <RechartsTooltip />
                  <Legend iconType="circle" />
                  <Bar dataKey="attendance" fill="#007AFF" name="Attendance %" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="assignments" fill="#5856D6" name="Assignment %" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </Paper>
          </Grid>
          <Grid item xs={12} md={5}>
            <Paper sx={{ p: 3, height: '100%' }}>
              <Typography variant="h6" gutterBottom fontWeight="bold">
                Attendance Distribution
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={attendanceDistributionData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {attendanceDistributionData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip />
                  <Legend verticalAlign="bottom" align="center" layout="horizontal" iconType="circle" />
                </PieChart>
              </ResponsiveContainer>
            </Paper>
          </Grid>
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Attendance Trend (Last 7 Days)
              </Typography>
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={recentAttendanceData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <RechartsTooltip />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="count"
                    stroke="#007AFF"
                    strokeWidth={2}
                    name="Daily Check-ins"
                  />
                </LineChart>
              </ResponsiveContainer>
            </Paper>
          </Grid>
        </Grid>

        {/* Search and Export Bar */}
        <Box sx={{ display: "flex", gap: 2, mb: 3, flexWrap: "wrap" }}>
          <TextField
            fullWidth
            placeholder="Search by name or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            sx={{ maxWidth: 400 }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
          />
          <Button
            variant="outlined"
            startIcon={<DownloadIcon />}
            onClick={exportToCSV}
            disabled={sortedStudents.length === 0}
          >
            Export to CSV
          </Button>
        </Box>

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
                        {searchTerm
                          ? "No students match your search"
                          : "No student data available yet"}
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
                          sx={{
                            backgroundColor: student.stats.attendance.rate >= 80 ? '#007AFF' : '#F2F2F7',
                            color: student.stats.attendance.rate >= 80 ? '#FFFFFF' : '#000000',
                            fontWeight: 700,
                            borderRadius: 1
                          }}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="center">
                        <Chip
                          label={`${student.stats.assignments.rate}%`}
                          sx={{
                            backgroundColor: student.stats.assignments.rate >= 80 ? '#007AFF' : '#F2F2F7',
                            color: student.stats.assignments.rate >= 80 ? '#FFFFFF' : '#000000',
                            fontWeight: 700,
                            borderRadius: 1
                          }}
                          size="small"
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

      {/* Floating Action Buttons */}
      <Tooltip title="Create new class" placement="left">
        <Fab
          color="primary"
          aria-label="add class"
          sx={{ position: "fixed", bottom: 88, right: 16 }}
          onClick={() => setOpenClassDialog(true)}
        >
          <ClassIcon />
        </Fab>
      </Tooltip>

      <Tooltip title="Create new assignment" placement="left">
        <Fab
          color="secondary"
          aria-label="add assignment"
          sx={{ position: "fixed", bottom: 24, right: 16 }}
          onClick={() => setOpenAssignmentDialog(true)}
        >
          <AssignmentIcon />
        </Fab>
      </Tooltip>

      {/* Class Creation Dialog */}
      <Dialog
        open={openClassDialog}
        onClose={() => setOpenClassDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <ClassIcon color="primary" />
            Create New Class
          </Box>
        </DialogTitle>
        <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} centered>
          <Tab label="Basics" />
          <Tab label="Schedule" />
          <Tab label="Students" />
        </Tabs>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              {activeTab === 0 && (
                <>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Class Name"
                      value={classForm.name}
                      onChange={(e) =>
                        setClassForm({ ...classForm, name: e.target.value })
                      }
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth variant="outlined">
                      <InputLabel id="class-dayofweek-label">
                        Day of Week
                      </InputLabel>
                      <Select
                        labelId="class-dayofweek-label"
                        id="class-dayofweek"
                        label="Day of Week"
                        value={classForm.dayOfWeek}
                        onChange={(e) =>
                          setClassForm({
                            ...classForm,
                            dayOfWeek: e.target.value,
                          })
                        }
                      >
                        <MenuItem value="monday">Monday</MenuItem>
                        <MenuItem value="tuesday">Tuesday</MenuItem>
                        <MenuItem value="wednesday">Wednesday</MenuItem>
                        <MenuItem value="thursday">Thursday</MenuItem>
                        <MenuItem value="friday">Friday</MenuItem>
                        <MenuItem value="saturday">Saturday</MenuItem>
                        <MenuItem value="sunday">Sunday</MenuItem>
                      </Select>
                    </FormControl>
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Description"
                      multiline
                      rows={2}
                      value={classForm.description}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          description: e.target.value,
                        })
                      }
                    />
                  </Grid>
                </>
              )}
              {activeTab === 1 && (
                <>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Start Time"
                      type="time"
                      value={classForm.startTime}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          startTime: e.target.value,
                        })
                      }
                      InputLabelProps={{ shrink: true }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="End Time"
                      type="time"
                      value={classForm.endTime}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          endTime: e.target.value,
                        })
                      }
                      InputLabelProps={{ shrink: true }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Start Date"
                      type="date"
                      value={classForm.startDate}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          startDate: e.target.value,
                        })
                      }
                      InputLabelProps={{ shrink: true }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="End Date"
                      type="date"
                      value={classForm.endDate}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          endDate: e.target.value,
                        })
                      }
                      InputLabelProps={{ shrink: true }}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Location"
                      value={classForm.location}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          location: e.target.value,
                        })
                      }
                    />
                  </Grid>
                </>
              )}
              {activeTab === 2 && (
                <Grid item xs={12}>
                  <Box sx={{ mb: 1, display: 'flex', justifyContent: 'flex-end' }}>
                    <Button 
                      size="small" 
                      onClick={() => setClassForm({
                        ...classForm, 
                        selectedStudents: students.map(s => s.id)
                      })}
                    >
                      Select All Students
                    </Button>
                  </Box>
                  <FormControl fullWidth>
                    <InputLabel id="select-students-label">
                      Select Students
                    </InputLabel>
                    <Select
                      labelId="select-students-label"
                      id="select-students"
                      label="Select Students"
                      multiple
                      value={classForm.selectedStudents}
                      onChange={(e) =>
                        setClassForm({
                          ...classForm,
                          selectedStudents: e.target.value,
                        })
                      }
                      renderValue={(selected) =>
                        selected
                          .map(
                            (id) =>
                              students.find((s) => s.id === id)?.email || id
                          )
                          .join(", ")
                      }
                    >
                      {students.map((student) => (
                        <MenuItem key={student.id} value={student.id}>
                          {student.firstName} {student.lastName} ({student.email})
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
              )}
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenClassDialog(false)}>Cancel</Button>
          <Button
            onClick={handleCreateClass}
            variant="contained"
            disabled={
              !classForm.name ||
              !classForm.selectedStudents.length ||
              !classForm.startDate
            }
          >
            Create Class
          </Button>
        </DialogActions>
      </Dialog>

      {/* Assignment Creation Dialog */}
      <Dialog
        open={openAssignmentDialog}
        onClose={() => setOpenAssignmentDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <AssignmentIcon color="secondary" />
            Create New Assignment
          </Box>
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Assignment Title"
                  value={assignmentForm.title}
                  onChange={(e) =>
                    setAssignmentForm({ ...assignmentForm, title: e.target.value })
                  }
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel id="priority-label">Priority</InputLabel>
                  <Select
                    labelId="priority-label"
                    label="Priority"
                    value={assignmentForm.priority}
                    onChange={(e) =>
                      setAssignmentForm({
                        ...assignmentForm,
                        priority: e.target.value,
                      })
                    }
                  >
                    <MenuItem value="Low">Low</MenuItem>
                    <MenuItem value="Medium">Medium</MenuItem>
                    <MenuItem value="High">High</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  multiline
                  rows={3}
                  value={assignmentForm.description}
                  onChange={(e) =>
                    setAssignmentForm({
                      ...assignmentForm,
                      description: e.target.value,
                    })
                  }
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Due Date"
                  type="date"
                  value={assignmentForm.dueDate}
                  onChange={(e) =>
                    setAssignmentForm({
                      ...assignmentForm,
                      dueDate: e.target.value,
                    })
                  }
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Due Time"
                  type="time"
                  value={assignmentForm.dueTime}
                  onChange={(e) =>
                    setAssignmentForm({
                      ...assignmentForm,
                      dueTime: e.target.value,
                    })
                  }
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={12}>
                <Box sx={{ mb: 1, display: 'flex', justifyContent: 'flex-end' }}>
                  <Button 
                    size="small" 
                    onClick={() => setAssignmentForm({
                      ...assignmentForm, 
                      selectedStudents: students.map(s => s.id)
                    })}
                  >
                    Select All Students
                  </Button>
                </Box>
                <FormControl fullWidth>
                  <InputLabel id="select-students-assign-label">
                    Select Students
                  </InputLabel>
                  <Select
                    labelId="select-students-assign-label"
                    label="Select Students"
                    multiple
                    value={assignmentForm.selectedStudents}
                    onChange={(e) =>
                      setAssignmentForm({
                        ...assignmentForm,
                        selectedStudents: e.target.value,
                      })
                    }
                    renderValue={(selected) =>
                      selected
                        .map(
                          (id) =>
                            students.find((s) => s.id === id)?.email || id
                        )
                        .join(", ")
                    }
                  >
                    {students.map((student) => (
                      <MenuItem key={student.id} value={student.id}>
                        {student.firstName} {student.lastName} ({student.email})
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAssignmentDialog(false)}>Cancel</Button>
          <Button
            onClick={handleCreateAssignment}
            variant="contained"
            color="secondary"
            disabled={
              !assignmentForm.title ||
              !assignmentForm.selectedStudents.length ||
              !assignmentForm.dueDate
            }
          >
            Create Assignment
          </Button>
        </DialogActions>
      </Dialog>

      {/* Attendance Records Dialog */}
      <Dialog
        open={openAttendanceDialog}
        onClose={() => setOpenAttendanceDialog(false)}
        maxWidth="md"
        fullWidth
      >
        {selectedAttendanceRecord && (
          <>
            <DialogTitle>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <AttendanceIcon color="success" />
                Attendance Record Details
              </Box>
            </DialogTitle>
            <DialogContent>
              <Box sx={{ mt: 2 }}>
                <Typography variant="body1">
                  <strong>Student:</strong>{" "}
                  {students.find((s) => s.id === selectedAttendanceRecord.userId)
                    ?.email || "Unknown"}
                </Typography>
                <Typography variant="body1">
                  <strong>Date:</strong>{" "}
                  {new Date(
                    selectedAttendanceRecord.timestamp?.toDate?.() ||
                      selectedAttendanceRecord.timestamp
                  ).toLocaleString()}
                </Typography>
                <Typography variant="body1">
                  <strong>Status:</strong>{" "}
                  <Chip
                    label={selectedAttendanceRecord.status}
                    color={
                      selectedAttendanceRecord.status === "present"
                        ? "success"
                        : "error"
                    }
                    size="small"
                  />
                </Typography>
                <Typography variant="body1">
                  <strong>Location:</strong>{" "}
                  {selectedAttendanceRecord.location || "N/A"}
                </Typography>
                <FormControl fullWidth sx={{ mt: 2 }}>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={selectedAttendanceRecord.status}
                    label="Status"
                    onChange={(e) =>
                      setSelectedAttendanceRecord({
                        ...selectedAttendanceRecord,
                        status: e.target.value,
                      })
                    }
                  >
                    <MenuItem value="present">Present</MenuItem>
                    <MenuItem value="absent">Absent</MenuItem>
                  </Select>
                </FormControl>
              </Box>
            </DialogContent>
            <DialogActions>
              <Button
                onClick={() => handleDeleteAttendance(selectedAttendanceRecord.id)}
                color="error"
                startIcon={<DeleteIcon />}
              >
                Delete
              </Button>
              <Button onClick={() => setOpenAttendanceDialog(false)}>
                Close
              </Button>
              <Button onClick={handleUpdateAttendance} variant="contained">
                Update
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
};

export default DashboardPage;
