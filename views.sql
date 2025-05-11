-- View 1: Student Course Grades
CREATE VIEW student_course_grades AS
SELECT 
    s.id AS student_id,
    s.name AS student_name,
    c.id AS course_id,
    c.name AS course_name,
    sem.name AS semester_name,
    e.grade
FROM Enrollments e
JOIN Students s ON e.student_id = s.id
JOIN Courses c ON e.course_id = c.id
JOIN Semesters sem ON e.semester_id = sem.id;


-- View 2: Course Enrollment Count
CREATE VIEW course_enrollment_count AS
SELECT 
    c.id AS course_id,
    c.name AS course_name,
    sem.name AS semester_name,
    COUNT(e.id) AS total_enrolled
FROM Enrollments e
JOIN Courses c ON e.course_id = c.id
JOIN Semesters sem ON e.semester_id = sem.id
GROUP BY c.id, sem.id;


-- View 3: Department Load
CREATE VIEW department_load AS
SELECT 
    d.id AS department_id,
    d.name AS department_name,
    sem.name AS semester_name,
    COUNT(DISTINCT c.id) AS total_courses_offered,
    COUNT(e.student_id) AS total_students_enrolled
FROM Departments d
LEFT JOIN Courses c ON c.department_id = d.id
LEFT JOIN Enrollments e ON e.course_id = c.id
LEFT JOIN Semesters sem ON e.semester_id = sem.id
GROUP BY d.id, sem.id;
