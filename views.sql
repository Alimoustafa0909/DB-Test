-- View 1: Student Course Grades
CREATE VIEW student_course_grades AS
SELECT 
    Students.id,
    Students.name,
    Courses.id,
    Courses.name,
    Semesters.name,
    Enrollments.grade
FROM Enrollments
JOIN Students ON Enrollments.student_id = Students.id
JOIN Courses ON Enrollments.course_id = Courses.id
JOIN Semesters ON Enrollments.semester_id = Semesters.id;

-- View 2: Course Enrollment Count
CREATE VIEW course_enrollment_count AS
SELECT 
    Courses.id,
    Courses.name,
    Semesters.name,
    COUNT(Enrollments.id)
FROM Enrollments
JOIN Courses ON Enrollments.course_id = Courses.id
JOIN Semesters ON Enrollments.semester_id = Semesters.id
GROUP BY Courses.id, Semesters.id;


-- View 3: Department Load
CREATE VIEW department_load AS
SELECT 
    Departments.id,
    Departments.name,
    Semesters.name,
    COUNT(DISTINCT Courses.id),
    COUNT(Enrollments.student_id)
FROM Departments
LEFT JOIN Courses ON Courses.department_id = Departments.id
LEFT JOIN Enrollments ON Enrollments.course_id = Courses.id
LEFT JOIN Semesters ON Enrollments.semester_id = Semesters.id
GROUP BY Departments.id, Semesters.id;

