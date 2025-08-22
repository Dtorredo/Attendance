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
} from "@mui/material";
import {
  School as SchoolIcon,
  People as PeopleIcon,
  Assignment as AssignmentIcon,
  EventAvailable as AttendanceIcon,
  Class as ClassIcon,
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

  // Dialog states
  const [openClassDialog, setOpenClassDialog] = useState(false);
  const [openAssignmentDialog, setOpenAssignmentDialog] = useState(false);
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

  const getStudentStats = React.useCallback(
    (student) => {
      const studentAttendance = attendance.filter(
        (record) => record.userId === student.id
      );
      const studentClasses = classes.filter((c) => c.userId === student.id);
      const studentAssignments = assignments.filter(
        (assignment) => assignment.userId === student.id
      );

      // Total classes should reflect assigned classes, not attendance records
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
  }, [students, order, orderBy, getStudentStats]);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  // Class creation functions
  const handleCreateClass = async () => {
    try {
      console.log("🔄 Creating class:", classForm);

      // Create class for each selected student
      for (const studentId of classForm.selectedStudents) {
        // Parse dates and times properly
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
          userId: studentId, // This will be overridden by createClass, so we need a different approach
          createdBy: user.uid,
          isRecurring: true,
        };

        // We need to use a direct Firestore call since createClass sets userId to current user
        await dataService.createClassForStudent(classData, studentId);
      }

      console.log("✅ Class created successfully");
      setOpenClassDialog(false);
      resetClassForm();
      loadDashboardData(); // Refresh data
    } catch (error) {
      console.error("❌ Error creating class:", error);
      setError("Failed to create class: " + error.message);
    }
  };

  const handleCreateAssignment = async () => {
    try {
      console.log("🔄 Creating assignment:", assignmentForm);

      // Create assignment for each selected student
      for (const studentId of assignmentForm.selectedStudents) {
        const assignmentData = {
          title: assignmentForm.title,
          details: assignmentForm.description,
          dueDate: `${assignmentForm.dueDate}T${assignmentForm.dueTime}`,
          priority: assignmentForm.priority, // Use selected priority
        };

        await dataService.createAssignmentForStudent(assignmentData, studentId);
      }

      console.log("✅ Assignment created successfully");
      setOpenAssignmentDialog(false);
      resetAssignmentForm();
      loadDashboardData(); // Refresh data
    } catch (error) {
      console.error("❌ Error creating assignment:", error);
      setError("Failed to create assignment: " + error.message);
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
            <Card
              sx={{
                borderRadius: 2,
                border: "1px solid",
                borderColor: "divider",
                background: "linear-gradient(180deg, #ffffff 0%, #f8fafc 100%)",
                transition: "all .2s ease",
                boxShadow: 1,
                "&:hover": { transform: "translateY(-3px)", boxShadow: 8 },
              }}
            >
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
            <Card
              sx={{
                borderRadius: 2,
                border: "1px solid",
                borderColor: "divider",
                background: "linear-gradient(180deg, #ffffff 0%, #f8fafc 100%)",
                transition: "all .2s ease",
                boxShadow: 1,
                "&:hover": { transform: "translateY(-3px)", boxShadow: 8 },
              }}
            >
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
            <Card
              sx={{
                borderRadius: 2,
                border: "1px solid",
                borderColor: "divider",
                background: "linear-gradient(180deg, #ffffff 0%, #f8fafc 100%)",
                transition: "all .2s ease",
                boxShadow: 1,
                "&:hover": { transform: "translateY(-3px)", boxShadow: 8 },
              }}
            >
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
            <Card
              sx={{
                borderRadius: 2,
                border: "1px solid",
                borderColor: "divider",
                background: "linear-gradient(180deg, #ffffff 0%, #f8fafc 100%)",
                transition: "all .2s ease",
                boxShadow: 1,
                "&:hover": { transform: "translateY(-3px)", boxShadow: 8 },
              }}
            >
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
                        setClassForm({ ...classForm, endTime: e.target.value })
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
                        setClassForm({ ...classForm, endDate: e.target.value })
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
                        setClassForm({ ...classForm, location: e.target.value })
                      }
                    />
                  </Grid>
                </>
              )}
              {activeTab === 2 && (
                <Grid item xs={12}>
                  <FormControl fullWidth variant="outlined">
                    <InputLabel id="class-assign-students-label">
                      Assign to Students
                    </InputLabel>
                    <Select
                      labelId="class-assign-students-label"
                      id="class-assign-students"
                      label="Assign to Students"
                      multiple
                      value={classForm.selectedStudents}
                      onChange={(e) => {
                        const value = e.target.value;
                        const isSelectAll =
                          value[value.length - 1] === "__all__";
                        if (isSelectAll) {
                          const allIds = students.map((s) => s.id);
                          const allSelected =
                            classForm.selectedStudents.length === allIds.length;
                          setClassForm({
                            ...classForm,
                            selectedStudents: allSelected ? [] : allIds,
                          });
                        } else {
                          setClassForm({
                            ...classForm,
                            selectedStudents: value,
                          });
                        }
                      }}
                    >
                      <MenuItem value="__all__">Select All</MenuItem>
                      {students.map((student) => (
                        <MenuItem key={student.id} value={student.id}>
                          {student.firstName} {student.lastName} (
                          {student.email})
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
              )}
              <Grid item xs={12}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography
                      variant="subtitle2"
                      color="text.secondary"
                      gutterBottom
                    >
                      Live Preview
                    </Typography>
                    <Typography variant="h6">
                      {classForm.name || "Untitled Class"}
                    </Typography>
                    <Typography
                      variant="body2"
                      color="text.secondary"
                      sx={{ mb: 1 }}
                    >
                      {classForm.description || "No description yet"}
                    </Typography>
                    <Chip
                      size="small"
                      label={classForm.dayOfWeek || "Day not set"}
                      sx={{ mr: 1 }}
                    />
                    <Chip
                      size="small"
                      label={classForm.location || "Location TBD"}
                    />
                  </CardContent>
                </Card>
              </Grid>
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
              !classForm.dayOfWeek ||
              classForm.selectedStudents.length === 0
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
        <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} centered>
          <Tab label="Basics" />
          <Tab label="Due" />
          <Tab label="Students" />
        </Tabs>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              {activeTab === 0 && (
                <>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Assignment Title"
                      value={assignmentForm.title}
                      onChange={(e) =>
                        setAssignmentForm({
                          ...assignmentForm,
                          title: e.target.value,
                        })
                      }
                    />
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
                </>
              )}
              {activeTab === 1 && (
                <>
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
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth variant="outlined">
                      <InputLabel id="assignment-priority-label">
                        Priority
                      </InputLabel>
                      <Select
                        labelId="assignment-priority-label"
                        id="assignment-priority"
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
                </>
              )}
              {activeTab === 2 && (
                <Grid item xs={12}>
                  <FormControl fullWidth variant="outlined">
                    <InputLabel id="assignment-assign-students-label">
                      Assign to Students
                    </InputLabel>
                    <Select
                      labelId="assignment-assign-students-label"
                      id="assignment-assign-students"
                      label="Assign to Students"
                      multiple
                      value={assignmentForm.selectedStudents}
                      onChange={(e) => {
                        const value = e.target.value;
                        const isSelectAll =
                          value[value.length - 1] === "__all__";
                        if (isSelectAll) {
                          const allIds = students.map((s) => s.id);
                          const allSelected =
                            assignmentForm.selectedStudents.length ===
                            allIds.length;
                          setAssignmentForm({
                            ...assignmentForm,
                            selectedStudents: allSelected ? [] : allIds,
                          });
                        } else {
                          setAssignmentForm({
                            ...assignmentForm,
                            selectedStudents: value,
                          });
                        }
                      }}
                    >
                      <MenuItem value="__all__">Select All</MenuItem>
                      {students.map((student) => (
                        <MenuItem key={student.id} value={student.id}>
                          {student.firstName} {student.lastName} (
                          {student.email})
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
              )}
              <Grid item xs={12}>
                <Card variant="outlined">
                  <CardContent>
                    <Typography
                      variant="subtitle2"
                      color="text.secondary"
                      gutterBottom
                    >
                      Live Preview
                    </Typography>
                    <Typography variant="h6">
                      {assignmentForm.title || "Untitled Assignment"}
                    </Typography>
                    <Typography
                      variant="body2"
                      color="text.secondary"
                      sx={{ mb: 1 }}
                    >
                      {assignmentForm.description || "No description yet"}
                    </Typography>
                    <Chip
                      size="small"
                      color="default"
                      label={`Priority: ${assignmentForm.priority}`}
                      sx={{ mr: 1 }}
                    />
                    <Chip
                      size="small"
                      label={
                        assignmentForm.dueDate
                          ? `Due ${assignmentForm.dueDate}${
                              assignmentForm.dueTime
                                ? " " + assignmentForm.dueTime
                                : ""
                            }`
                          : "No due date set"
                      }
                    />
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAssignmentDialog(false)}>Cancel</Button>
          <Button
            onClick={handleCreateAssignment}
            variant="contained"
            disabled={
              !assignmentForm.title ||
              !assignmentForm.dueDate ||
              assignmentForm.selectedStudents.length === 0
            }
          >
            Create Assignment
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DashboardPage;
