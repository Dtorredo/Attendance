import React, { useState, useEffect, useMemo } from "react";
import dataService from "../services/dataService";
import {
  Container,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Box,
  Button,
  Chip,
  TextField,
  InputAdornment,
  Grid,
  Card,
  CardContent,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Alert,
  CircularProgress,
} from "@mui/material";
import {
  Search as SearchIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  FilterList as FilterIcon,
  Download as DownloadIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
} from "@mui/icons-material";

import { useAuth } from "../context/AuthContext";

const AttendancePage = () => {
  const { user, userRole } = useAuth();
  const [records, setRecords] = useState([]);
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedRecord, setSelectedRecord] = useState(null);
  const [openEditDialog, setOpenEditDialog] = useState(false);

  useEffect(() => {
    if (userRole === "lecturer") {
      loadData();
      // Set up real-time listener for ALL records (Lecturer view)
      const unsubscribe = dataService.subscribeToAllAttendance((attendanceData) => {
        setRecords(attendanceData);
      });
      return () => unsubscribe();
    }
  }, [userRole]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [attendanceData, usersData] = await Promise.all([
        dataService.getAllData("attendance", "timestamp"),
        dataService.getAllUsers(),
      ]);
      setRecords(attendanceData);
      setStudents(usersData.filter((u) => u.role === "student"));
    } catch (error) {
      console.error("❌ Error loading attendance:", error);
      setError("Failed to load records: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const getStudentName = (userId) => {
    const student = students.find((s) => s.id === userId);
    return student ? `${student.firstName} ${student.lastName}` : "Unknown Student";
  };

  const getStudentEmail = (userId) => {
    const student = students.find((s) => s.id === userId);
    return student?.email || "N/A";
  };

  // Filter records
  const filteredRecords = useMemo(() => {
    return records.filter((record) => {
      const search = searchTerm.toLowerCase();
      const studentName = getStudentName(record.userId).toLowerCase();
      const studentEmail = getStudentEmail(record.userId).toLowerCase();
      const matchesSearch = studentName.includes(search) || studentEmail.includes(search);
      const matchesStatus = statusFilter === "all" || record.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [records, searchTerm, statusFilter, students]);

  // Get stats
  const stats = useMemo(() => {
    const totalRecords = records.length;
    const present = records.filter((r) => r.status === "present").length;
    // Real calculation: Total instances - Present check-ins
    // For your 0/8 case, we ensure it reflects correctly
    const absent = records.filter((r) => r.status === "absent").length;
    
    return { 
      total: totalRecords, 
      present, 
      absent: absent || (totalRecords - present), 
      rate: totalRecords > 0 ? Math.round((present / totalRecords) * 100) : 0 
    };
  }, [records]);

  // Export to CSV
  const exportToCSV = () => {
    const headers = ["Student", "Email", "Date", "Status", "Location"];
    const rows = filteredRecords.map((r) => [
      getStudentName(r.userId),
      getStudentEmail(r.userId),
      new Date(r.timestamp?.toDate?.() || r.timestamp).toLocaleString(),
      r.status,
      r.location || "N/A",
    ]);
    const csvContent = [headers, ...rows].map((e) => e.join(",")).join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `attendance-report-${new Date().toISOString().split("T")[0]}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const handleDeleteRecord = async (recordId) => {
    if (window.confirm("Are you sure you want to delete this attendance record?")) {
      try {
        await dataService.deleteAttendance(recordId);
        setOpenEditDialog(false);
      } catch (error) {
        console.error("❌ Error deleting attendance:", error);
        alert("Failed to delete attendance record");
      }
    }
  };

  const handleUpdateRecord = async () => {
    try {
      await dataService.updateAttendance(selectedRecord.id, {
        status: selectedRecord.status,
      });
      setOpenEditDialog(false);
    } catch (error) {
      console.error("❌ Error updating attendance:", error);
      alert("Failed to update attendance record");
    }
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
            Loading attendance records...
          </Typography>
        </Box>
      </Container>
    );
  }

  if (error) {
    return (
      <Container sx={{ mt: 4 }}>
        <Alert severity="error">{error}</Alert>
        <Button variant="contained" onClick={loadData} sx={{ mt: 2 }}>
          Retry
        </Button>
      </Container>
    );
  }

  return (
    <Container sx={{ mt: 4, mb: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Attendance Records
        </Typography>
        <Typography variant="body1" color="text.secondary">
          View, filter, and manage all student attendance records
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              backgroundColor: "#FFFFFF",
              border: '1px solid #E5E5EA',
              boxShadow: 'none',
            }}
          >
            <CardContent>
              <Typography color="textSecondary" variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
                Total Records
              </Typography>
              <Typography variant="h4" fontWeight="bold">{stats.total}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              backgroundColor: "#FFFFFF",
              border: '1px solid #E5E5EA',
              boxShadow: 'none',
            }}
          >
            <CardContent>
              <Typography color="textSecondary" variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
                Present
              </Typography>
              <Typography variant="h4" fontWeight="bold" color="primary.main">
                {stats.present}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              backgroundColor: "#FFFFFF",
              border: '1px solid #E5E5EA',
              boxShadow: 'none',
            }}
          >
            <CardContent>
              <Typography color="textSecondary" variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
                Absent
              </Typography>
              <Typography variant="h4" fontWeight="bold" sx={{ color: '#8E8E93' }}>
                {stats.absent}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card
            sx={{
              backgroundColor: "#FFFFFF",
              border: '1px solid #E5E5EA',
              boxShadow: 'none',
            }}
          >
            <CardContent>
              <Typography color="textSecondary" variant="caption" sx={{ fontWeight: 600, textTransform: 'uppercase' }}>
                Attendance Rate
              </Typography>
              <Typography variant="h4" fontWeight="bold" color="primary.main">
                {stats.rate}%
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Filters */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              placeholder="Search by student name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
          </Grid>
          <Grid item xs={12} md={4}>
            <FormControl fullWidth>
              <InputLabel>Filter by Status</InputLabel>
              <Select
                value={statusFilter}
                label="Filter by Status"
                onChange={(e) => setStatusFilter(e.target.value)}
                startAdornment={
                  <InputAdornment position="start">
                    <FilterIcon />
                  </InputAdornment>
                }
              >
                <MenuItem value="all">All Records</MenuItem>
                <MenuItem value="present">Present Only</MenuItem>
                <MenuItem value="absent">Absent Only</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item xs={12} md={2}>
            <Button
              fullWidth
              variant="outlined"
              startIcon={<DownloadIcon />}
              onClick={exportToCSV}
              disabled={filteredRecords.length === 0}
            >
              Export
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Table */}
      <Paper sx={{ width: "100%", overflow: "hidden" }}>
        <TableContainer>
          <Table stickyHeader>
            <TableHead>
              <TableRow>
                <TableCell>Student Name</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Date & Time</TableCell>
                <TableCell align="center">Status</TableCell>
                <TableCell>Location</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredRecords.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                    <Typography variant="body1" color="text.secondary">
                      {searchTerm || statusFilter !== "all"
                        ? "No records match your filters"
                        : "No attendance records yet"}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                filteredRecords.map((record) => (
                  <TableRow
                    key={record.id}
                    sx={{
                      backgroundColor:
                        record.status === "absent"
                          ? "rgba(244, 67, 54, 0.05)"
                          : "inherit",
                      "&:hover": {
                        backgroundColor: "rgba(0, 0, 0, 0.04)",
                      },
                    }}
                  >
                    <TableCell>{getStudentName(record.userId)}</TableCell>
                    <TableCell>{getStudentEmail(record.userId)}</TableCell>
                    <TableCell>
                      {new Date(
                        record.timestamp?.toDate?.() || record.timestamp
                      ).toLocaleString()}
                    </TableCell>
                    <TableCell align="center">
                      <Chip
                        icon={
                          record.status === "present" ? (
                            <CheckCircleIcon sx={{ color: 'inherit !important' }} />
                          ) : (
                            <CancelIcon sx={{ color: 'inherit !important' }} />
                          )
                        }
                        label={record.status}
                        sx={{
                          backgroundColor: record.status === 'present' ? '#007AFF' : '#F2F2F7',
                          color: record.status === 'present' ? '#FFFFFF' : '#000000',
                          fontWeight: 700,
                          borderRadius: 1,
                          '& .MuiChip-icon': { color: 'inherit' }
                        }}
                      />
                    </TableCell>
                    <TableCell>{record.location || "N/A"}</TableCell>
                    <TableCell align="center">
                      <Tooltip title="Edit">
                        <IconButton
                          size="small"
                          onClick={() => {
                            setSelectedRecord(record);
                            setOpenEditDialog(true);
                          }}
                        >
                          <EditIcon />
                        </IconButton>
                      </Tooltip>
                      <Tooltip title="Delete">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => handleDeleteRecord(record.id)}
                        >
                          <DeleteIcon />
                        </IconButton>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Edit Dialog */}
      <Dialog
        open={openEditDialog}
        onClose={() => setOpenEditDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        {selectedRecord && (
          <>
            <DialogTitle>
              <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                <EditIcon color="primary" />
                Edit Attendance Record
              </Box>
            </DialogTitle>
            <DialogContent>
              <Box sx={{ mt: 2 }}>
                <Typography variant="body1" paragraph>
                  <strong>Student:</strong> {getStudentName(selectedRecord.userId)}
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>Date:</strong>{" "}
                  {new Date(
                    selectedRecord.timestamp?.toDate?.() ||
                      selectedRecord.timestamp
                  ).toLocaleString()}
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>Location:</strong>{" "}
                  {selectedRecord.location || "N/A"}
                </Typography>
                <FormControl fullWidth sx={{ mt: 2 }}>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={selectedRecord.status}
                    label="Status"
                    onChange={(e) =>
                      setSelectedRecord({
                        ...selectedRecord,
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
                onClick={() => handleDeleteRecord(selectedRecord.id)}
                color="error"
                startIcon={<DeleteIcon />}
              >
                Delete
              </Button>
              <Button onClick={() => setOpenEditDialog(false)}>Cancel</Button>
              <Button onClick={handleUpdateRecord} variant="contained">
                Update
              </Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </Container>
  );
};

export default AttendancePage;
