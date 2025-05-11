
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
SELECT Courses.id, Courses.name
FROM Courses
WHERE NOT EXISTS (
    SELECT 1 FROM Enrollments
    WHERE Enrollments.course_id = Courses.id
      AND Enrollments.semester_id = "Spring"  -- Replace 1 with the semester you are checking
);

-- 3=> Average grade per course across all semesters
SELECT Courses.id, Courses.name, AVG(Enrollments.grade) AS average_grade
FROM Enrollments
JOIN Courses ON Enrollments.course_id = Courses.id
GROUP BY Courses.id;


-- 4=> Instructors teaching more than 3 courses in a single semester
SELECT Courses.id, Courses.name, AVG(Enrollments.grade) AS average_grade
FROM Enrollments
JOIN Courses ON Enrollments.course_id = Courses.id
GROUP BY Courses.id;


-- 5=> All courses a particular student is enrolled in, ordered by semester
SELECT Students.id, Students.name, Courses.name, Semesters.name
FROM Enrollments
JOIN Students ON Enrollments.student_id = Students.id
JOIN Courses ON Enrollments.course_id = Courses.id
JOIN Semesters ON Enrollments.semester_id = Semesters.id
WHERE Students.id = 1  -- Change 1 to the student ID you want to check
ORDER BY Semesters.id;

-- 6=> Department statistics: avg class size
SELECT Departments.id, Departments.name, 
       COUNT(Enrollments.student_id) / NULLIF(COUNT(DISTINCT Courses.id), 0) AS average_class_size
FROM Departments
JOIN Courses ON Courses.department_id = Departments.id
JOIN Enrollments ON Enrollments.course_id = Courses.id
GROUP BY Departments.id;


-- 7=> Students at risk (GPA < 2.0 in any semester)
SELECT Students.id, Students.name
FROM Enrollments
JOIN Students ON Enrollments.student_id = Students.id
GROUP BY Students.id, Enrollments.semester_id
HAVING AVG(Enrollments.grade) < 2.0;

-- 8=>> Students who took all CS courses
SELECT Students.id, Students.name
FROM Students
WHERE NOT EXISTS (
    SELECT Courses.id 
    FROM Courses
    JOIN Departments ON Courses.department_id = Departments.id
    WHERE Departments.name = 'Computer Science'
    AND NOT EXISTS (
        SELECT Enrollments.id 
        FROM Enrollments 
        WHERE Enrollments.student_id = Students.id 
        AND Enrollments.course_id = Courses.id
    )
);

-- 9-> Rank students within department by GPA
SELECT Students.id, Students.name, Departments.name, 
       RANK() OVER (PARTITION BY Departments.id ORDER BY AVG(Enrollments.grade) DESC) AS department_rank
FROM Students
JOIN Enrollments ON Students.id = Enrollments.student_id
JOIN Departments ON Students.department_id = Departments.id
GROUP BY Students.id, Departments.id;

-- 10=> Drop semester’s enrollments if empty
SET @semester_id = 3;  -- Change to the semester you want to delete

DELETE FROM Enrollments
WHERE semester_id = @semester_id;

DELETE FROM Semesters
WHERE id = @semester_id
AND NOT EXISTS (
    SELECT 1 FROM Enrollments WHERE semester_id = @semester_id
);
