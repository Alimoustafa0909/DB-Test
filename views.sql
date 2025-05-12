-- Student Course Grades View
CREATE VIEW student_course_grades AS
SELECT 
    Students.id AS student_id, 
    Students.name AS student_name,
    Courses.id AS course_id,
    Courses.name AS course_name,
    Semesters.name AS semester_name,
    Enrollments.grade AS grade
FROM Enrollments
JOIN Students ON Enrollments.student_id = Students.id
JOIN Courses ON Enrollments.course_id = Courses.id
JOIN Semesters ON Enrollments.semester_id = Semesters.id;


-- Course Enrollment Count View
CREATE VIEW course_enrollment_count AS
SELECT 
    Courses.id AS course_id,
    Courses.name AS course_name,
    Semesters.name AS semester_name,
    COUNT(Enrollments.id) AS total_enrolled
FROM Enrollments
JOIN Courses ON Enrollments.course_id = Courses.id
JOIN Semesters ON Enrollments.semester_id = Semesters.id
GROUP BY Courses.id, Semesters.id;



--Department Load View
CREATE VIEW department_load AS
SELECT 
    Departments.id AS department_id,
    Departments.name AS department_name,
    COUNT(DISTINCT Courses.id) AS total_courses_offered,
    COUNT(Enrollments.student_id) AS total_students_enrolled,
    CASE 
        WHEN COUNT(DISTINCT Courses.id) = 0 THEN 0
        ELSE COUNT(Enrollments.student_id) / COUNT(DISTINCT Courses.id)
    END AS average_class_size
FROM Departments
LEFT JOIN Courses ON Courses.department_id = Departments.id
LEFT JOIN Enrollments ON Enrollments.course_id = Courses.id
GROUP BY Departments.id;



