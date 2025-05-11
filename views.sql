
CREATE VIEW Student_Course_Grades AS
SELECT s.student_id, s.student_name, c.course_id, c.course_name, sem.name AS semester, e.grade
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
JOIN Semesters sem ON e.semester_id = sem.semester_id;

CREATE VIEW Course_Enrollment_Count AS
SELECT c.course_id, c.course_name, sem.name AS semester, COUNT(*) AS total_enrolled
FROM Enrollments e
JOIN Courses c ON e.course_id = c.course_id
JOIN Semesters sem ON e.semester_id = sem.semester_id
GROUP BY c.course_id, sem.semester_id;

CREATE VIEW Department_Load AS
SELECT d.dept_id, d.dept_name, sem.name AS semester,
       COUNT(DISTINCT c.course_id) AS total_courses_offered,
       COUNT(e.student_id) AS total_students_enrolled
FROM Departments d
LEFT JOIN Courses c ON c.dept_id = d.dept_id
LEFT JOIN Enrollments e ON e.course_id = c.course_id
LEFT JOIN Semesters sem ON e.semester_id = sem.semester_id
GROUP BY d.dept_id, sem.semester_id;
