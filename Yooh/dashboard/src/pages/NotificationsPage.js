import React, { useState, useEffect, useMemo } from "react";
import { useAuth } from "../context/AuthContext";
import dataService from "../services/dataService";
import {
  Container,
  Typography,
  Paper,
  Box,
  Button,
  Grid,
  Card,
  CardContent,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Divider,
  IconButton,
  Alert,
  Tabs,
  Tab,
  Badge,
  CircularProgress,
} from "@mui/material";
import {
  Notifications as NotificationsIcon,
  Send as SendIcon,
  Delete as DeleteIcon,
  Event as EventIcon,
  Assignment as AssignmentIcon,
  Warning as WarningIcon,
  Info as InfoIcon,
  AccessTime as AccessTimeIcon,
} from "@mui/icons-material";
import { collection, addDoc, getDocs, query, orderBy, deleteDoc, doc } from "firebase/firestore";
import { db } from "../services/firebase";

const NotificationsPage = () => {
  const { user } = useAuth();
  const [students, setStudents] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [openSendDialog, setOpenSendDialog] = useState(false);
  const [activeTab, setActiveTab] = useState(0);
  const [notificationForm, setNotificationForm] = useState({
    title: "",
    message: "",
    type: "general",
    selectedStudents: [],
    scheduledDate: "",
    scheduledTime: "",
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [usersData, notificationsData] = await Promise.all([
        dataService.getAllUsers(),
        getNotificationsFromFirestore(),
      ]);
      setStudents(usersData.filter((u) => u.role === "student"));
      setNotifications(notificationsData);
    } catch (error) {
      console.error("❌ Error loading data:", error);
      setError("Failed to load data: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const getNotificationsFromFirestore = async () => {
    try {
      const q = query(
        collection(db, "notifications"),
        orderBy("createdAt", "desc")
      );
      const querySnapshot = await getDocs(q);
      return querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      console.error("Error fetching notifications:", error);
      return [];
    }
  };

  const handleSendNotification = async () => {
    try {
      const notificationData = {
        title: notificationForm.title,
        message: notificationForm.message,
        type: notificationForm.type,
        createdBy: user.uid,
        createdAt: new Date(),
        recipientCount: notificationForm.selectedStudents.length,
      };

      // Save notification to Firestore
      const docRef = await addDoc(
        collection(db, "notifications"),
        notificationData
      );

      // Create individual notifications for each selected student
      const batchPromises = notificationForm.selectedStudents.map(
        async (studentId) => {
          await addDoc(collection(db, "userNotifications"), {
            userId: studentId,
            notificationId: docRef.id,
            title: notificationForm.title,
            message: notificationForm.message,
            type: notificationForm.type,
            isRead: false,
            createdAt: new Date(),
          });
        }
      );

      await Promise.all(batchPromises);

      console.log("✅ Notification sent successfully");
      setOpenSendDialog(false);
      resetForm();
      loadData();
    } catch (error) {
      console.error("❌ Error sending notification:", error);
      setError("Failed to send notification: " + error.message);
    }
  };

  const handleDeleteNotification = async (notificationId) => {
    if (window.confirm("Are you sure you want to delete this notification?")) {
      try {
        await deleteDoc(doc(db, "notifications", notificationId));
        loadData();
      } catch (error) {
        console.error("❌ Error deleting notification:", error);
        alert("Failed to delete notification");
      }
    }
  };

  const resetForm = () => {
    setNotificationForm({
      title: "",
      message: "",
      type: "general",
      selectedStudents: [],
      scheduledDate: "",
      scheduledTime: "",
    });
  };

  const getNotificationIcon = (type) => {
    switch (type) {
      case "assignment":
        return <AssignmentIcon color="warning" />;
      case "cat":
        return <EventIcon color="error" />;
      case "urgent":
        return <WarningIcon color="error" />;
      default:
        return <InfoIcon color="info" />;
    }
  };

  const getNotificationColor = (type) => {
    switch (type) {
      case "assignment":
        return "warning";
      case "cat":
        return "error";
      case "urgent":
        return "error";
      default:
        return "default";
    }
  };

  const stats = useMemo(() => {
    const total = notifications.length;
    const today = new Date().toDateString();
    const sentToday = notifications.filter(
      (n) => new Date(n.createdAt?.toDate?.() || n.createdAt).toDateString() === today
    ).length;
    const urgent = notifications.filter((n) => n.type === "urgent").length;
    return { total, sentToday, urgent };
  }, [notifications]);

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
            Loading notifications...
          </Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container sx={{ mt: 4, mb: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          <NotificationsIcon sx={{ mr: 1, verticalAlign: "middle" }} />
          Notification Center
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Send announcements, reminders, and alerts to students
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={4}>
          <Card
            sx={{
              background: "linear-gradient(180deg, #ffffff 0%, #e3f2fd 100%)",
              boxShadow: 1,
            }}
          >
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Sent
              </Typography>
              <Typography variant="h4">{stats.total}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card
            sx={{
              background: "linear-gradient(180deg, #ffffff 0%, #e8f5e9 100%)",
              boxShadow: 1,
            }}
          >
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Sent Today
              </Typography>
              <Typography variant="h4" color="success.main">
                {stats.sentToday}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={4}>
          <Card
            sx={{
              background: "linear-gradient(180deg, #ffffff 0%, #ffebee 100%)",
              boxShadow: 1,
            }}
          >
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Urgent Alerts
              </Typography>
              <Typography variant="h4" color="error.main">
                {stats.urgent}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Action Button */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          size="large"
          startIcon={<SendIcon />}
          onClick={() => setOpenSendDialog(true)}
          sx={{
            background: "linear-gradient(45deg, #007AFF 30%, #5856D6 90%)",
          }}
        >
          Send New Notification
        </Button>
      </Box>

      {/* Notifications List */}
      <Paper>
        <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)}>
          <Tab label="All Notifications" />
          <Tab label={`General (${notifications.filter(n => n.type === 'general').length})`} />
          <Tab label={`Assignments (${notifications.filter(n => n.type === 'assignment').length})`} />
          <Tab label={`CAT Reminders (${notifications.filter(n => n.type === 'cat').length})`} />
          <Tab label={`Urgent (${notifications.filter(n => n.type === 'urgent').length})`} />
        </Tabs>
        <Divider />
        <List sx={{ maxHeight: 600, overflow: "auto" }}>
          {notifications
            .filter((n) => {
              if (activeTab === 0) return true;
              const types = ["all", "general", "assignment", "cat", "urgent"];
              return n.type === types[activeTab];
            })
            .map((notification, index) => (
              <React.Fragment key={notification.id}>
                <ListItem
                  alignItems="flex-start"
                  sx={{
                    backgroundColor: index % 2 === 0 ? "rgba(0,0,0,0.02)" : "transparent",
                    "&:hover": { backgroundColor: "rgba(0,0,0,0.04)" },
                  }}
                >
                  <ListItemIcon sx={{ minWidth: 40 }}>
                    {getNotificationIcon(notification.type)}
                  </ListItemIcon>
                  <ListItemText
                    primary={
                      <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                        <Typography variant="subtitle1" component="span">
                          {notification.title}
                        </Typography>
                        <Chip
                          label={notification.type}
                          size="small"
                          color={getNotificationColor(notification.type)}
                          variant="outlined"
                        />
                      </Box>
                    }
                    secondary={
                      <>
                        <Typography variant="body2" component="span">
                          {notification.message}
                        </Typography>
                        <Box sx={{ mt: 1, display: "flex", gap: 2 }}>
                          <Box sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
                            <AccessTimeIcon fontSize="small" color="action" />
                            <Typography variant="caption" color="text.secondary">
                              {new Date(
                                notification.createdAt?.toDate?.() || notification.createdAt
                              ).toLocaleString()}
                            </Typography>
                          </Box>
                          <Typography variant="caption" color="text.secondary">
                            Sent to {notification.recipientCount || "all"} student(s)
                          </Typography>
                        </Box>
                      </>
                    }
                  />
                  <IconButton
                    edge="end"
                    onClick={() => handleDeleteNotification(notification.id)}
                  >
                    <DeleteIcon />
                  </IconButton>
                </ListItem>
                {index < notifications.length - 1 && <Divider />}
              </React.Fragment>
            ))}
          {notifications.filter((n) => {
            if (activeTab === 0) return true;
            const types = ["all", "general", "assignment", "cat", "urgent"];
            return n.type === types[activeTab];
          }).length === 0 && (
            <Box sx={{ py: 8, textAlign: "center" }}>
              <NotificationsIcon sx={{ fontSize: 64, color: "text.secondary", opacity: 0.3 }} />
              <Typography variant="h6" color="text.secondary" sx={{ mt: 2 }}>
                No notifications yet
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Click "Send New Notification" to get started
              </Typography>
            </Box>
          )}
        </List>
      </Paper>

      {/* Send Notification Dialog */}
      <Dialog
        open={openSendDialog}
        onClose={() => setOpenSendDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
            <SendIcon color="primary" />
            Send New Notification
          </Box>
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Notification Title"
                  value={notificationForm.title}
                  onChange={(e) =>
                    setNotificationForm({ ...notificationForm, title: e.target.value })
                  }
                  placeholder="e.g., Assignment Due Tomorrow"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Message"
                  multiline
                  rows={4}
                  value={notificationForm.message}
                  onChange={(e) =>
                    setNotificationForm({ ...notificationForm, message: e.target.value })
                  }
                  placeholder="Enter your notification message..."
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth>
                  <InputLabel>Type</InputLabel>
                  <Select
                    value={notificationForm.type}
                    label="Type"
                    onChange={(e) =>
                      setNotificationForm({ ...notificationForm, type: e.target.value })
                    }
                  >
                    <MenuItem value="general">General</MenuItem>
                    <MenuItem value="assignment">Assignment</MenuItem>
                    <MenuItem value="cat">CAT Reminder</MenuItem>
                    <MenuItem value="urgent">Urgent</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Select Students</InputLabel>
                  <Select
                    label="Select Students"
                    multiple
                    value={notificationForm.selectedStudents}
                    onChange={(e) =>
                      setNotificationForm({
                        ...notificationForm,
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
                    helperText="Leave empty to send to all students"
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
          <Button onClick={() => setOpenSendDialog(false)}>Cancel</Button>
          <Button
            onClick={handleSendNotification}
            variant="contained"
            disabled={!notificationForm.title || !notificationForm.message}
            startIcon={<SendIcon />}
          >
            Send Notification
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default NotificationsPage;
