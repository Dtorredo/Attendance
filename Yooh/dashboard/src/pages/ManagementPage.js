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
  IconButton,
  Tooltip,
  Tabs,
  Tab,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  Chip,
  CircularProgress,
} from "@mui/material";
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  School as ClassIcon,
  Assignment as AssignmentIcon,
} from "@mui/icons-material";
import { useAuth } from "../context/AuthContext";

const ManagementPage = () => {
  const { userRole } = useAuth();
  const [activeTab, setActiveTab] = useState(0);
  const [classes, setClasses] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editDialogOpen, setOpenEditDialog] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);
  const [editType, setEditType] = useState(""); // 'class' or 'assignment'

  useEffect(() => {
    if (userRole === "lecturer") {
      loadData();
      // Listen for changes
      const unsubClasses = dataService.subscribeToAllData("classes", setClasses, "startDate");
      const unsubAssignments = dataService.subscribeToAllData("assignments", setAssignments, "dueDate");
      return () => {
        unsubClasses();
        unsubAssignments();
      };
    }
  }, [userRole]);

  const loadData = async () => {
    try {
      setLoading(true);
      const [cData, aData] = await Promise.all([
        dataService.getAllData("classes", "startDate"),
        dataService.getAllData("assignments", "dueDate"),
      ]);
      setClasses(cData);
      setAssignments(aData);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  // Grouping logic for the Lecturer's perspective
  const groupedClasses = useMemo(() => {
    const groups = {};
    classes.forEach((c) => {
      const key = `${c.title}-${c.startDate}-${c.endDate}`;
      if (!groups[key]) {
        groups[key] = { ...c, studentIds: [c.userId], docIds: [c.id] };
      } else {
        groups[key].studentIds.push(c.userId);
        groups[key].docIds.push(c.id);
      }
    });
    return Object.values(groups);
  }, [classes]);

  const groupedAssignments = useMemo(() => {
    const groups = {};
    assignments.forEach((a) => {
      const key = `${a.title}-${a.dueDate}`;
      if (!groups[key]) {
        groups[key] = { ...a, studentIds: [a.userId], docIds: [a.id], completedCount: a.isCompleted ? 1 : 0 };
      } else {
        groups[key].studentIds.push(a.userId);
        groups[key].docIds.push(a.id);
        if (a.isCompleted) groups[key].completedCount++;
      }
    });
    return Object.values(groups);
  }, [assignments]);

  const handleEditClick = (item, type) => {
    setSelectedItem({ ...item });
    setEditType(type);
    setOpenEditDialog(true);
  };

  const handleDelete = async (item, type) => {
    if (window.confirm(`Are you sure you want to delete this ${type} for ALL enrolled students?`)) {
      try {
        const promises = item.docIds.map((id) => 
          type === 'class' ? dataService.deleteClass(id) : dataService.deleteAssignment(id)
        );
        await Promise.all(promises);
      } catch (e) {
        alert("Failed to delete items");
      }
    }
  };

  const handleUpdate = async () => {
    try {
      const promises = selectedItem.docIds.map((id) => {
        const updates = editType === 'class' 
          ? { title: selectedItem.title, location: selectedItem.location, notes: selectedItem.notes }
          : { title: selectedItem.title, priority: selectedItem.priority, details: selectedItem.details };
        return editType === 'class' 
          ? dataService.updateClass(id, updates) 
          : dataService.updateAssignment(id, updates);
      });
      await Promise.all(promises);
      setOpenEditDialog(false);
    } catch (e) {
      alert("Failed to update items");
    }
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}><CircularProgress /></Box>;

  return (
    <Container sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" fontWeight="bold" gutterBottom>Academic Management</Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Update or remove academic materials for all enrolled students simultaneously.
      </Typography>

      <Paper sx={{ border: '1px solid #E5E5EA', boxShadow: 'none' }}>
        <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tab icon={<ClassIcon />} iconPosition="start" label={`Classes (${groupedClasses.length})`} />
          <Tab icon={<AssignmentIcon />} iconPosition="start" label={`Assignments (${groupedAssignments.length})`} />
        </Tabs>

        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={{ backgroundColor: '#F2F2F7' }}>
                <TableCell sx={{ fontWeight: 'bold' }}>Title</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>{activeTab === 0 ? 'Schedule / Location' : 'Due Date / Priority'}</TableCell>
                <TableCell align="center" sx={{ fontWeight: 'bold' }}>Enrolled</TableCell>
                <TableCell align="center" sx={{ fontWeight: 'bold' }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(activeTab === 0 ? groupedClasses : groupedAssignments).map((item, idx) => (
                <TableRow key={idx}>
                  <TableCell>
                    <Typography fontWeight="600">{item.title}</Typography>
                    {activeTab === 1 && (
                      <Typography variant="caption" color="text.secondary">
                        {item.completedCount} / {item.studentIds.length} Completed
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    {activeTab === 0 ? (
                      <>
                        <Typography variant="body2">{item.dayOfWeek}s at {new Date(item.startDate?.toDate?.() || item.startDate).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</Typography>
                        <Typography variant="caption" color="text.secondary">{item.location}</Typography>
                      </>
                    ) : (
                      <>
                        <Typography variant="body2">{new Date(item.dueDate?.toDate?.() || item.dueDate).toLocaleDateString()}</Typography>
                        <Chip label={item.priority} size="small" sx={{ height: 20, fontSize: '0.65rem', backgroundColor: '#F2F2F7', fontWeight: 700 }} />
                      </>
                    )}
                  </TableCell>
                  <TableCell align="center">
                    <Chip label={`${item.studentIds.length} Students`} size="small" variant="outlined" />
                  </TableCell>
                  <TableCell align="center">
                    <IconButton size="small" onClick={() => handleEditClick(item, activeTab === 0 ? 'class' : 'assignment')} sx={{ color: '#007AFF' }}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton size="small" color="error" onClick={() => handleDelete(item, activeTab === 0 ? 'class' : 'assignment')}>
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {/* Edit Dialog */}
      <Dialog open={editDialogOpen} onClose={() => setOpenEditDialog(false)} fullWidth maxWidth="sm">
        <DialogTitle>Edit {editType === 'class' ? 'Class' : 'Assignment'}</DialogTitle>
        <DialogContent sx={{ pt: 2 }}>
          <Grid container spacing={2} sx={{ mt: 0.5 }}>
            <Grid item xs={12}>
              <TextField 
                fullWidth label="Title" 
                value={selectedItem?.title || ''} 
                onChange={(e) => setSelectedItem({...selectedItem, title: e.target.value})} 
              />
            </Grid>
            {editType === 'class' ? (
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Location" 
                  value={selectedItem?.location || ''} 
                  onChange={(e) => setSelectedItem({...selectedItem, location: e.target.value})} 
                />
              </Grid>
            ) : (
              <Grid item xs={12}>
                <TextField 
                  fullWidth label="Details" 
                  multiline rows={3} 
                  value={selectedItem?.details || ''} 
                  onChange={(e) => setSelectedItem({...selectedItem, details: e.target.value})} 
                />
              </Grid>
            )}
          </Grid>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setOpenEditDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleUpdate} sx={{ backgroundColor: '#007AFF' }}>Save Changes</Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default ManagementPage;
