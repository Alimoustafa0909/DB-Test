-- ============================
-- SCHEMA: CREATE TABLES
-- ============================

CREATE TABLE Departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Instructors (
    instructor_id INT PRIMARY KEY AUTO_INCREMENT,
    instructor_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    dept_id INT,
    hire_date DATE,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
);

CREATE TABLE Students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    dob DATE,
    enroll_date DATE NOT NULL,
    major_dept_id INT,
    FOREIGN KEY (major_dept_id) REFERENCES Departments(dept_id)
);

CREATE TABLE Courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id)
);

CREATE TABLE Semesters (
    semester_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Classrooms (
    classroom_id INT PRIMARY KEY AUTO_INCREMENT,
    building VARCHAR(100) NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    capacity INT NOT NULL
);

CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    semester_id INT,
    grade DECIMAL(3,2),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id),
    FOREIGN KEY (semester_id) REFERENCES Semesters(semester_id)
);

CREATE TABLE Course_Classroom (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT,
    classroom_id INT,
    semester_id INT,
    FOREIGN KEY (course_id) REFERENCES Courses(course_id),
    FOREIGN KEY (classroom_id) REFERENCES Classrooms(classroom_id),
    FOREIGN KEY (semester_id) REFERENCES Semesters(semester_id)
);

CREATE TABLE Course_Instructors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT,
    instructor_id INT,
    semester_id INT,
    FOREIGN KEY (course_id) REFERENCES Courses(course_id),
    FOREIGN KEY (instructor_id) REFERENCES Instructors(instructor_id),
    FOREIGN KEY (semester_id) REFERENCES Semesters(semester_id)
);

-- ============================
-- VIEWS
-- ============================

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

-- ============================
-- QUERIES
-- ============================

-- 1. Top 5 Students by GPA in the most recent semester
SELECT e.student_id, s.student_name, sem.name AS semester, 
       AVG(e.grade) AS gpa
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Semesters sem ON e.semester_id = sem.semester_id
WHERE sem.name = (SELECT name FROM Semesters ORDER BY semester_id DESC LIMIT 1)
GROUP BY e.student_id, sem.semester_id
ORDER BY gpa DESC
LIMIT 5;

-- 2. Courses with no enrollments in a given semester
SELECT c.course_id, c.course_name
FROM Courses c
WHERE NOT EXISTS (
    SELECT 1 FROM Enrollments e
    WHERE e.course_id = c.course_id AND e.semester_id = 1
);

-- 3. Average grade per course across all semesters
SELECT c.course_id, c.course_name, AVG(e.grade) AS avg_grade
FROM Enrollments e
JOIN Courses c ON e.course_id = c.course_id
GROUP BY c.course_id;

-- 4. Instructors teaching more than 3 courses in a single semester
SELECT instructor_id, semester_id, COUNT(DISTINCT course_id) AS course_count
FROM Course_Instructors
GROUP BY instructor_id, semester_id
HAVING course_count > 3;

-- 5. All courses a particular student is enrolled in, ordered by semester
SELECT s.student_id, s.student_name, c.course_name, sem.name AS semester
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id
JOIN Semesters sem ON e.semester_id = sem.semester_id
WHERE s.student_id = 1
ORDER BY sem.semester_id;

-- 6. Department statistics: avg class size
SELECT d.dept_id, d.dept_name, 
       COUNT(e.student_id) / NULLIF(COUNT(DISTINCT c.course_id), 0) AS avg_class_size
FROM Departments d
JOIN Courses c ON c.dept_id = d.dept_id
JOIN Enrollments e ON e.course_id = c.course_id
GROUP BY d.dept_id;

-- 7. Students at risk (GPA < 2.0 in any semester)
SELECT s.student_id, s.student_name
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
GROUP BY s.student_id, e.semester_id
HAVING AVG(e.grade) < 2.0;

-- 8. Students who took all CS courses
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

-- 9. Rank students within department by GPA
SELECT s.student_id, s.student_name, d.dept_name,
       RANK() OVER (PARTITION BY d.dept_id ORDER BY AVG(e.grade) DESC) AS dept_rank
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Departments d ON s.major_dept_id = d.dept_id
GROUP BY s.student_id;

-- 10. Drop semester’s enrollments if empty
SET @sem_id = 3; -- Change this as needed

DELETE FROM Enrollments WHERE semester_id = @sem_id;

DELETE FROM Semesters
WHERE semester_id = @sem_id
AND NOT EXISTS (
  SELECT 1 FROM Enrollments WHERE semester_id = @sem_id
);

-- ============================
-- SAMPLE DATA
-- ============================

-- Insert Departments
INSERT INTO Departments (dept_name) VALUES
('Computer Science'),
('Business Administration'),
('Mechanical Engineering'),
('Psychology'),
('Design & Media');

-- Insert Instructors
INSERT INTO Instructors (instructor_name, email, phone, dept_id, hire_date) VALUES
('Alice Johnson', 'alice.johnson@example.com', '123-456-7890', 1, '2019-08-01'),
('Bob Smith', 'bob.smith@example.com', '234-567-8901', 1, '2020-01-15'),
('Carol Lee', 'carol.lee@example.com', '345-678-9012', 2, '2021-05-10'),
('David Kim', 'david.kim@example.com', '456-789-0123', 2, '2020-09-25'),
('Emily Clark', 'emily.clark@example.com', '567-890-1234', 3, '2022-02-18'),
('Frank White', 'frank.white@example.com', '678-901-2345', 3, '2018-07-07'),
('Grace Brown', 'grace.brown@example.com', '789-012-3456', 4, '2023-03-05'),
('Henry Green', 'henry.green@example.com', '890-123-4567', 4, '2021-11-22'),
('Ivy Black', 'ivy.black@example.com', '901-234-5678', 5, '2017-06-30'),
('Jake Wood', 'jake.wood@example.com', '012-345-6789', 5, '2019-10-13');

-- Insert Students
INSERT INTO Students (student_name, email, dob, enroll_date, major_dept_id) VALUES
('Liam Mason', 'liam.mason@example.com', '2001-04-10', '2022-09-01', 1),
('Emma Smith', 'emma.smith@example.com', '2000-07-22', '2021-09-01', 2),
('Noah Johnson', 'noah.johnson@example.com', '2002-01-15', '2023-01-10', 1),
('Olivia Brown', 'olivia.brown@example.com', '1999-12-05', '2020-09-01', 3),
('William Lee', 'william.lee@example.com', '2001-06-30', '2022-09-01', 3),
('Ava Garcia', 'ava.garcia@example.com', '2003-02-14', '2023-09-01', 4),
('James Martinez', 'james.martinez@example.com', '2002-09-18', '2021-01-15', 4),
('Sophia Davis', 'sophia.davis@example.com', '2000-10-01', '2020-09-01', 5),
('Benjamin Miller', 'benjamin.miller@example.com', '2002-11-20', '2022-01-01', 5),
('Isabella Wilson', 'isabella.wilson@example.com', '2001-05-12', '2022-09-01', 1);
-- Repeat pattern to reach 50 students if needed

-- Insert Courses
INSERT INTO Courses (course_name, credits, dept_id) VALUES
('Intro to Programming', 3, 1),
('Data Structures', 4, 1),
('Marketing Principles', 3, 2),
('Financial Accounting', 3, 2),
('Thermodynamics', 3, 3),
('Machine Design', 4, 3),
('Cognitive Psychology', 3, 4),
('Visual Design Basics', 3, 5);

-- Insert Semesters
INSERT INTO Semesters (name) VALUES
('Spring 2025'),
('Fall 2025');

-- Insert Classrooms
INSERT INTO Classrooms (building, room_number, capacity) VALUES
('Science Hall', '101', 60),
('Business Center', '205', 45),
('Engineering Block', '302', 70),
('Psychology Wing', '104', 35),
('Design Studio', '210', 40),
('Main Building', '001', 80),
('Annex A', 'B12', 50),
('Library Hall', '3F', 65);

-- Insert Enrollments (sample, repeat for 200 total)
INSERT INTO Enrollments (student_id, course_id, semester_id, grade) VALUES
(1, 1, 1, 3.6),
(2, 2, 1, 3.2),
(3, 1, 1, 2.9),
(4, 5, 1, 2.4),
(5, 6, 1, 3.0),
(6, 7, 1, 3.8),
(7, 8, 1, 2.7),
(8, 3, 1, 3.1),
(9, 4, 1, 3.4),
(10, 2, 1, 2.5),
(1, 2, 2, 3.0),
(2, 3, 2, 2.2),
(3, 4, 2, 3.7),
(4, 1, 2, 2.9),
(5, 5, 2, 3.2),
(6, 6, 2, 2.8),
(7, 7, 2, 2.1),
(8, 8, 2, 3.9),
(9, 1, 2, 2.6),
(10, 2, 2, 3.3);
-- Repeat more for total 200 enrollments as needed
