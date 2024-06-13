select * from information_schema.processlist as p where p.command = 'Binlog Dump'; 

CREATE DATABASE company;

USE company;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email, password) VALUES
('Bob', 'bob@example.com', 'password456'),
('Charlie', 'charlie@example.com', 'password789'),
('David', 'david@example.com', 'password321');
