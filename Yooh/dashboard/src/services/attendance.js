// Mock attendance data service
export const getAttendance = async (lecturer_id) => {
  if (!lecturer_id) {
    return [];
  }

  // Simulate API delay
  await new Promise((resolve) => setTimeout(resolve, 500));

  // Mock attendance data
  const mockAttendanceData = [
    {
      _id: "student_1",
      first_name: "John",
      last_name: "Doe",
      attendancePercentage: "85.50",
    },
    {
      _id: "student_2",
      first_name: "Jane",
      last_name: "Smith",
      attendancePercentage: "92.30",
    },
    {
      _id: "student_3",
      first_name: "Mike",
      last_name: "Johnson",
      attendancePercentage: "78.90",
    },
    {
      _id: "student_4",
      first_name: "Sarah",
      last_name: "Wilson",
      attendancePercentage: "96.70",
    },
    {
      _id: "student_5",
      first_name: "David",
      last_name: "Brown",
      attendancePercentage: "82.40",
    },
  ];

  return mockAttendanceData;
};
