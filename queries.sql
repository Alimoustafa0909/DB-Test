
-- QUERIES

-- 1=Top 5 Students by GPA in the most recent semester
SELECT student_id, student_name, course_name semester_name, AVG(grade)
FROM student_course_grades
WHERE semester_name = 'Spring'
GROUP BY student_id, semester_name
ORDER BY AVG(grade) DESC
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
SELECT student_id, student_name, course_name, semester_name
FROM student_course_grades
WHERE student_id = 1
ORDER BY semester_name;

-- 6=> Department statistics: avg class size
SELECT department_id, department_name, semester_name, average_class_size
FROM department_load;


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
