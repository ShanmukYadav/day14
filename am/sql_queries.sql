-- =============================================================
-- sql_queries.sql
-- Part A: 15 SQL Queries — SQL Foundations
-- Day 14 · AM Take-Home Assignment
-- Week 3 · PG Diploma · AI-ML & Agentic AI · IIT Gandhinagar
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- SCHEMA SETUP  (run this first to create & populate tables)
-- ─────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS projects   CASCADE;
DROP TABLE IF EXISTS employees  CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(50)     NOT NULL,
    location    VARCHAR(50),
    budget      NUMERIC(12, 2)
);

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50)     NOT NULL,
    last_name   VARCHAR(50)     NOT NULL,
    dept_id     INT             REFERENCES departments(dept_id),
    salary      NUMERIC(10, 2),
    hire_date   DATE,
    job_title   VARCHAR(50),
    manager_id  INT             REFERENCES employees(emp_id)
);

-- Departments
INSERT INTO departments (dept_name, location, budget) VALUES
    ('Engineering',  'Bengaluru',  5000000.00),
    ('Data Science', 'Hyderabad',  3500000.00),
    ('Marketing',    'Mumbai',     2000000.00),
    ('HR',           'Delhi',      1500000.00),
    ('Finance',      'Chennai',    2500000.00);

-- Employees (manager_id updated after insert)
INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date, job_title, manager_id) VALUES
    ('Arjun',    'Sharma',    1, 95000,  '2019-03-15', 'Senior Engineer',    NULL),
    ('Priya',    'Patel',     2, 88000,  '2020-07-01', 'Data Scientist',     NULL),
    ('Ravi',     'Kumar',     1, 72000,  '2021-01-10', 'Engineer',           1),
    ('Sneha',    'Reddy',     3, 65000,  '2020-11-20', 'Marketing Manager',  NULL),
    ('Vikram',   'Singh',     2, 91000,  '2018-06-05', 'ML Engineer',        2),
    ('Ananya',   'Iyer',      4, 55000,  '2022-03-01', 'HR Specialist',      NULL),
    ('Deepak',   'Menon',     5, 78000,  '2019-09-14', 'Financial Analyst',  NULL),
    ('Kavitha',  'Nair',      1, 82000,  '2020-02-28', 'Senior Engineer',    1),
    ('Rohan',    'Gupta',     2, 69000,  '2021-08-15', 'Data Analyst',       2),
    ('Lakshmi',  'Venkat',    3, 61000,  '2022-05-10', 'Marketing Analyst',  4),
    ('Aditya',   'Joshi',     1, 105000, '2017-11-30', 'Lead Engineer',      NULL),
    ('Meena',    'Pillai',    4, 52000,  '2023-01-20', 'HR Coordinator',     6),
    ('Suresh',   'Bhat',      5, 83000,  '2018-07-22', 'Senior Analyst',     7),
    ('Nalini',   'Das',       3, 58000,  '2021-12-05', 'Brand Specialist',   4),
    ('Kartik',   'Rao',       2, 76000,  '2020-04-18', 'Data Engineer',      2),
    ('Pooja',    'Shah',      1, 67000,  '2022-09-01', 'Engineer',           1),
    ('Manish',   'Tiwari',    5, 71000,  '2019-03-30', 'Analyst',            7),
    ('Divya',    'Krishnan',  2, 94000,  '2018-12-10', 'ML Engineer',        2),
    ('Sanjay',   'Mehta',     1, 88000,  '2020-06-15', 'Senior Engineer',    11),
    ('Rina',     'Chopra',    4, 60000,  '2021-04-25', 'HR Specialist',      6);


-- =============================================================
-- PART A: 15 QUERIES
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- Q1. SELECT with WHERE: all Engineering employees earning > 75000
-- ─────────────────────────────────────────────────────────────
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name  AS full_name,
    e.salary,
    e.job_title
FROM employees  AS e
JOIN departments AS d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'Engineering'
  AND e.salary > 75000
ORDER BY e.salary DESC;

-- ─────────────────────────────────────────────────────────────
-- Q2. ORDER BY + LIMIT: top 5 highest-paid employees
-- ─────────────────────────────────────────────────────────────
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name  AS full_name,
    d.dept_name,
    e.salary
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY e.salary DESC
LIMIT 5;

-- ─────────────────────────────────────────────────────────────
-- Q3. Aggregate: company-wide salary stats
-- ─────────────────────────────────────────────────────────────
SELECT
    COUNT(*)              AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary,
    MAX(salary)           AS max_salary,
    MIN(salary)           AS min_salary,
    SUM(salary)           AS total_payroll
FROM employees;

-- ─────────────────────────────────────────────────────────────
-- Q4. GROUP BY: headcount and avg salary per department
-- ─────────────────────────────────────────────────────────────
SELECT
    d.dept_name,
    COUNT(e.emp_id)               AS headcount,
    ROUND(AVG(e.salary), 2)       AS avg_salary,
    SUM(e.salary)                 AS total_salary
FROM departments AS d
LEFT JOIN employees AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY avg_salary DESC;

-- ─────────────────────────────────────────────────────────────
-- Q5. HAVING: departments with average salary > 75000
-- ─────────────────────────────────────────────────────────────
SELECT
    d.dept_name,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    COUNT(e.emp_id)          AS headcount
FROM departments AS d
JOIN employees   AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
HAVING AVG(e.salary) > 75000
ORDER BY avg_salary DESC;

-- ─────────────────────────────────────────────────────────────
-- Q6. INNER JOIN: employees with their department name
-- ─────────────────────────────────────────────────────────────
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name,
    d.location,
    e.salary
FROM employees   AS e
INNER JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.salary DESC;

-- ─────────────────────────────────────────────────────────────
-- Q7. LEFT JOIN: all departments, including those with no employees
-- ─────────────────────────────────────────────────────────────
SELECT
    d.dept_id,
    d.dept_name,
    d.location,
    COUNT(e.emp_id)  AS employee_count
FROM departments AS d
LEFT JOIN employees AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name, d.location
ORDER BY employee_count DESC;

-- ─────────────────────────────────────────────────────────────
-- Q8. Self JOIN: employees with their manager's name
-- ─────────────────────────────────────────────────────────────
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name        AS employee,
    e.job_title,
    m.first_name || ' ' || m.last_name        AS manager,
    m.job_title                               AS manager_title
FROM employees AS e
LEFT JOIN employees AS m ON e.manager_id = m.emp_id
ORDER BY manager NULLS LAST, e.emp_id;

-- ─────────────────────────────────────────────────────────────
-- Q9. WHERE with date filter: employees hired in 2020
-- ─────────────────────────────────────────────────────────────
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    e.hire_date,
    e.job_title,
    d.dept_name
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
WHERE e.hire_date BETWEEN '2020-01-01' AND '2020-12-31'
ORDER BY e.hire_date;

-- ─────────────────────────────────────────────────────────────
-- Q10. LIKE / pattern matching: employees with job title containing 'Engineer'
-- ─────────────────────────────────────────────────────────────
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    e.job_title,
    e.salary
FROM employees AS e
WHERE e.job_title ILIKE '%engineer%'
ORDER BY e.salary DESC;

-- ─────────────────────────────────────────────────────────────
-- Q11. IS NULL: employees without a manager (top-level)
-- ─────────────────────────────────────────────────────────────
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.job_title,
    d.dept_name
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
WHERE e.manager_id IS NULL
ORDER BY e.emp_id;

-- ─────────────────────────────────────────────────────────────
-- Q12. DISTINCT: unique job titles in the company
-- ─────────────────────────────────────────────────────────────
SELECT DISTINCT
    job_title
FROM employees
ORDER BY job_title;

-- ─────────────────────────────────────────────────────────────
-- Q13. CROSS JOIN: every (department, location) combination preview
--       (limited to 10 for sanity)
-- ─────────────────────────────────────────────────────────────
SELECT
    d1.dept_name  AS dept_a,
    d2.dept_name  AS dept_b
FROM departments AS d1
CROSS JOIN departments AS d2
WHERE d1.dept_id < d2.dept_id    -- avoid self-pairs and duplicates
ORDER BY d1.dept_id, d2.dept_id
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- Q14. GROUP BY + HAVING + ORDER BY chain:
--      departments where total payroll > 400,000, sorted by payroll
-- ─────────────────────────────────────────────────────────────
SELECT
    d.dept_name,
    COUNT(e.emp_id)         AS headcount,
    SUM(e.salary)           AS total_payroll,
    d.budget,
    ROUND(SUM(e.salary) / d.budget * 100, 2) AS payroll_to_budget_pct
FROM departments AS d
JOIN employees   AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_name, d.budget
HAVING SUM(e.salary) > 400000
ORDER BY total_payroll DESC;

-- ─────────────────────────────────────────────────────────────
-- Q15. Multi-table JOIN + alias: employee name, dept name,
--      department budget, personal salary as % of dept budget
-- ─────────────────────────────────────────────────────────────
SELECT
    e.first_name || ' ' || e.last_name       AS full_name,
    d.dept_name,
    e.salary,
    d.budget                                  AS dept_budget,
    ROUND(e.salary / d.budget * 100, 4)      AS salary_pct_of_budget
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY salary_pct_of_budget DESC;


-- =============================================================
-- EXPLAIN ANALYSIS (Q2, Q5, Q6)
-- =============================================================

-- EXPLAIN for Q2 (top 5 highest-paid)
EXPLAIN
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name,
    e.salary
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY e.salary DESC
LIMIT 5;
-- Insight: PostgreSQL uses a Hash Join between employees and departments,
-- then a Sort node on salary DESC, followed by a Limit node.
-- The sort is the most expensive step (O(n log n)). An index on
-- employees.salary would allow an Index Scan to skip the sort entirely.

-- EXPLAIN for Q5 (departments avg salary > 75000)
EXPLAIN
SELECT
    d.dept_name,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments AS d
JOIN employees   AS e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
HAVING AVG(e.salary) > 75000;
-- Insight: The plan shows a HashAggregate node for GROUP BY, fed by a
-- Hash Join. The HAVING filter is applied AFTER aggregation — confirming
-- that HAVING cannot use an index the way WHERE can. Moving a fixed
-- filter to WHERE (when logically valid) is always faster.

-- EXPLAIN for Q6 (INNER JOIN employees + departments)
EXPLAIN
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name AS full_name,
    d.dept_name
FROM employees   AS e
INNER JOIN departments AS d ON e.dept_id = d.dept_id;
-- Insight: PostgreSQL chooses a Hash Join — it builds a hash table from
-- the smaller 'departments' table, then probes it for each row in
-- 'employees'. This is O(n) on average, better than a Nested Loop
-- O(n*m) for large tables without an index on dept_id.
