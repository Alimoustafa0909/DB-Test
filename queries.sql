
-- QUERIES

-- 1=Top 5 Students by GPA in the most recent semester
SELECT 
    Students.id,
    Students.name,
    Semesters.name,
    AVG(Enrollments.grade) AS gpa
FROM Enrollments
JOIN Students ON Enrollments.student_id = Students.id
JOIN Semesters ON Enrollments.semester_id = Semesters.id
WHERE Enrollments.semester_id = (SELECT MAX(id) FROM Semesters)
GROUP BY Students.id, Semesters.id
ORDER BY gpa DESC
LIMIT 5;


-- 2=> Courses with no enrollments in a given semester
SELECT c.course_id, c.course_name
FROM Courses c
WHERE NOT EXISTS (
    SELECT 1 FROM Enrollments e
    WHERE e.course_id = c.course_id AND e.semester_id = 1
);

-- 3=> Average grade per course across all semesters
SELECT c.course_id, c.course_name, AVG(e.grade) AS avg_grade
FROM Enrollments e
JOIN Courses c ON e.course_id = c.course_id
GROUP BY c.course_id;

-- 4=> Instructors teaching more than 3 courses in a single semester
SELECT instructor_id, semester_id, COUNT(DISTINCT course_id) AS course_count
FROM Course_Instructors
GROUP BY instructor_id, semester_id
HAVING course_count > 3;

-- 5=> All courses a particular student is enrolled in, ordered by semester
SELECT s.student_id, s.student_name, c.course_name, sem.name AS semester
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
JOIN Semesters sem ON e.semester_id = sem.semester_id
WHERE s.student_id = 1
ORDER BY sem.semester_id;

-- 6=> Department statistics: avg class size
SELECT d.dept_id, d.dept_name, 
       COUNT(e.student_id) / NULLIF(COUNT(DISTINCT c.course_id), 0) AS avg_class_size
FROM Departments d
JOIN Courses c ON c.dept_id = d.dept_id
JOIN Enrollments e ON e.course_id = c.course_id
GROUP BY d.dept_id;

-- 7=> Students at risk (GPA < 2.0 in any semester)
SELECT s.student_id, s.student_name
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
GROUP BY s.student_id, e.semester_id
HAVING AVG(e.grade) < 2.0;

-- 8=>> Students who took all CS courses
SELECT s.student_id, s.student_name
FROM Students s
WHERE NOT EXISTS (
  SELECT course_id FROM Courses c
  JOIN Departments d ON c.dept_id = d.dept_id
  WHERE d.dept_name = 'Computer Science'
  AND NOT EXISTS (
    SELECT 1 FROM Enrollments e 
    WHERE e.student_id = s.student_id AND e.course_id = c.course_id
  )
);

-- 9-> Rank students within department by GPA
SELECT s.student_id, s.student_name, d.dept_name,
       RANK() OVER (PARTITION BY d.dept_id ORDER BY AVG(e.grade) DESC) AS dept_rank
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Departments d ON s.major_dept_id = d.dept_id
GROUP BY s.student_id;

-- 10=> Drop semester’s enrollments if empty
SET @sem_id = 3; -- Change this as needed

DELETE FROM Enrollments WHERE semester_id = @sem_id;

DELETE FROM Semesters
WHERE semester_id = @sem_id
AND NOT EXISTS (
  SELECT 1 FROM Enrollments WHERE semester_id = @sem_id
);
