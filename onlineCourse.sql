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


-- insert departments
INSERT INTO Departments (name) VALUES
('Computer Science'),
('Business Administration'),
('Mechanical Engineering'),
('Psychology'),
('Media & Design');

-- Insert instructors
INSERT INTO Instructors (name, email, phone, department_id, hire_date) VALUES
('Alice Johnson', 'alice@example.com', '1234567890', 1, '2022-01-15'),
('Bob Smith', 'bob@example.com', '2345678901', 1, '2021-03-10'),
('Carol Lee', 'carol@example.com', '3456789012', 2, '2023-05-01'),
('David Kim', 'david@example.com', '4567890123', 2, '2020-07-20'),
('Emily Clark', 'emily@example.com', '5678901234', 3, '2021-08-12'),
('Frank White', 'frank@example.com', '6789012345', 3, '2019-11-30'),
('Grace Brown', 'grace@example.com', '7890123456', 4, '2022-06-18'),
('Henry Green', 'henry@example.com', '8901234567', 4, '2023-02-25'),
('Ivy Black', 'ivy@example.com', '9012345678', 5, '2021-09-15'),
('Jake Wood', 'jake@example.com', '0123456789', 5, '2020-04-08');


-- Insert Students
INSERT INTO Students (name, email, date_of_birth, enroll_date, department_id) VALUES
('Peter Sloan', 'emilysavage@hotmail.com', '1999-07-08', '2023-05-19', 2),
('Alicia Baker', 'ryandustin@yahoo.com', '2005-07-26', '2023-05-24', 5),
('Keith Nguyen', 'jacobyang@hotmail.com', '2003-11-09', '2022-05-22', 4),
('Alex Taylor', 'danielleellison@yahoo.com', '2001-05-25', '2022-12-11', 3),
('Derrick Barr', 'mchang@schmidt-davis.info', '2004-10-26', '2024-03-07', 5),
('Lisa Stone', 'blakejohnson@gmail.com', '2006-04-22', '2023-03-06', 1),
('Sean Robinson', 'jordanpatrick@terry-mcdonald.com', '2005-08-06', '2025-04-10', 3),
('Kathleen Torres', 'patriciaterrell@gmail.com', '2007-03-21', '2023-03-06', 5),
('Joseph Ward', 'justin70@dixon.org', '1999-07-31', '2023-01-05', 4),
('Mark Freeman DVM', 'brian74@love.biz', '2003-04-05', '2025-03-06', 1),
('David Henry', 'myerssherri@smith.com', '2001-06-03', '2023-11-28', 4),
('Jose Romero', 'richardjackson@yahoo.com', '2005-06-23', '2024-12-29', 1),
('Robert Edwards', 'dhenderson@hotmail.com', '2000-05-30', '2023-11-13', 3),
('Dawn Choi', 'elizabeth48@hotmail.com', '2006-02-20', '2023-05-17', 3),
('Mr. Troy Mcconnell', 'sarahkline@gmail.com', '2005-04-05', '2023-09-16', 2),
('Erin Wallace', 'richardjones@sanchez.org', '2005-09-28', '2022-11-24', 5),
('John Austin', 'garymorgan@yahoo.com', '2002-11-09', '2023-01-08', 3),
('Jessica Flores MD', 'dominiqueandrews@gmail.com', '1999-07-25', '2023-04-06', 2),
('Chelsea Fowler', 'jacksmith@gmail.com', '2005-03-10', '2022-06-15', 5),
('Rodney Anderson', 'michael35@brown.biz', '1999-09-19', '2023-06-03', 3),
('Madison Alvarez', 'rmartin@hotmail.com', '2004-07-20', '2024-04-18', 5),
('Vickie Waters', 'acarpenter@smith.com', '2006-03-22', '2023-02-27', 5),
('Mr. Ryan Jones', 'emyers@hotmail.com', '2005-06-16', '2022-12-31', 5),
('Monica Phillips', 'mike18@brown.com', '2001-10-05', '2024-12-11', 1),
('Jeremy Barnett', 'fullerdawn@yahoo.com', '2000-08-26', '2024-06-09', 2),
('Randy Hendricks', 'stephaniepadilla@smith.com', '1999-12-24', '2024-06-24', 4),
('Joe Cole', 'perezcassandra@solomon.com', '2004-08-03', '2022-07-31', 2),
('Anthony Monroe', 'kellyjames@yahoo.com', '2000-06-30', '2024-08-22', 4),
('Jeremiah Hayden', 'lesliebowers@hotmail.com', '2006-01-09', '2023-06-14', 4),
('Katherine Lang', 'asmith@hotmail.com', '2004-06-30', '2023-10-11', 2),
('Andrew Palmer', 'paulahicks@hunter-rodriguez.info', '2001-11-01', '2022-10-21', 3),
('Jesus Tran', 'michael86@hotmail.com', '2003-08-04', '2023-10-14', 5),
('Sara Johnson', 'sroberson@holt.com', '2003-02-09', '2023-11-02', 3),
('Nicolas Martin', 'sarahmorales@yahoo.com', '2000-05-24', '2022-07-01', 2),
('Lisa Randolph', 'millerdavid@sweeney.com', '2002-05-09', '2022-07-30', 3),
('Katherine Holt', 'rmiller@hotmail.com', '2006-12-28', '2024-07-05', 4),
('Wesley Scott', 'bridget34@gmail.com', '2000-10-04', '2022-11-07', 5),
('Jack Caldwell', 'cwilkins@gmail.com', '2006-12-25', '2024-01-23', 5),
('Amber Mitchell', 'seanlowery@tyler.com', '2004-01-23', '2022-06-02', 5),
('Erik Skinner', 'tammy17@smith.org', '2007-02-23', '2023-04-06', 1),
('Michele Stewart', 'manningvictoria@franco.com', '2000-06-19', '2025-03-29', 5),
('Shirley Norton', 'atkinsonkatherine@case.net', '2003-07-25', '2025-02-03', 4),
('Jessica Diaz', 'gina75@villegas-gillespie.biz', '2001-09-26', '2025-05-09', 4),
('Melissa Lee', 'christine75@jensen.com', '2006-11-10', '2023-08-04', 3),
('Cameron Harper', 'piercedaniel@gmail.com', '2002-01-03', '2023-06-14', 5),
('Joshua Small', 'kenneth61@yahoo.com', '2000-10-08', '2022-10-17', 2),
('Kristi Stephens', 'jackkelley@gmail.com', '2006-03-27', '2023-07-05', 2),
('Nathan Brown', 'williamschwartz@hotmail.com', '2003-05-14', '2023-11-02', 5),
('Jodi Cross', 'mcdowellmelissa@luna-douglas.com', '2001-01-30', '2023-11-22', 4),
('Christopher Morris', 'rnielsen@smith.org', '1999-06-12', '2022-09-23', 5);


-- Insert Courses
INSERT INTO Courses (name, credit_hour, department_id, classroom_id) VALUES
('Intro to Programming', 3, 1, 1),
('Data Structures', 4, 1, 2),
('Marketing Basics', 3, 2, 3),
('Financial Accounting', 3, 2, 4),
('Thermodynamics', 3, 3, 5),
('Machine Design', 4, 3, 6),
('Cognitive Psychology', 3, 4, 7),
('Visual Design Basics', 3, 5, 8);


-- Insert Semesters
INSERT INTO Semesters (name) VALUES
('Spring'),
('Fall');

-- Insert Classrooms
INSERT INTO Classrooms (building, room_number, capacity) VALUES
('Science Hall', '101', 50),
('Engineering Block', '202', 60),
('Business Center', '303', 45),
('Psychology Wing', '404', 35),
('Design Studio', '505', 40),
('Main Building', 'G01', 80),
('Annex A', 'B12', 55),
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
