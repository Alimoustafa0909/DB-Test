-- departments table
CREATE TABLE Departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- instructors table 
CREATE TABLE Instructors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    department_id INT,
    hire_date DATE,
    FOREIGN KEY (department_id) REFERENCES Departments(id)
);

-- students table 
CREATE TABLE Students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(40) NOT NULL UNIQUE,
    date_of_birth DATE,
    enroll_date DATE NOT NULL,
    department_id INT, -- the department the student is gonna study on it in
    FOREIGN KEY (department_id) REFERENCES Departments(id)
);

-- courses table
CREATE TABLE Courses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    credit_hour INT NOT NULL, -- number of credit hours for the course
    department_id INT,
    classroom_id INT,
    FOREIGN KEY (department_id) REFERENCES Departments(id),
    FOREIGN KEY (classroom_id) REFERENCES Classrooms(id)
);

-- semesters table 
CREATE TABLE Semesters (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE
);

-- classrooms table
CREATE TABLE Classrooms (
    id INT PRIMARY KEY AUTO_INCREMENT,
    building VARCHAR(50) NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    capacity INT NOT NULL
);

-- enrollments table to link students with courses in a specific semester
CREATE TABLE Enrollments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT,
    course_id INT,
    semester_id INT,
    grade DECIMAL(3,2),
    FOREIGN KEY (student_id) REFERENCES Students(id),
    FOREIGN KEY (course_id) REFERENCES Courses(id),
    FOREIGN KEY (semester_id) REFERENCES Semesters(id)
);


