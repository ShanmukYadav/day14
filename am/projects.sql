-- =============================================================
-- projects.sql
-- Part B: Projects Table — 3-Table JOINs
-- Day 14 · AM Take-Home Assignment
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- DDL: projects table
-- ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS projects CASCADE;

CREATE TABLE projects (
    project_id    SERIAL PRIMARY KEY,
    project_name  VARCHAR(100)    NOT NULL,
    lead_emp_id   INT             REFERENCES employees(emp_id),
    budget        NUMERIC(12, 2),
    start_date    DATE,
    end_date      DATE
);

-- ─────────────────────────────────────────────────────────────
-- INSERT: 5 projects
-- ─────────────────────────────────────────────────────────────
INSERT INTO projects (project_name, lead_emp_id, budget, start_date, end_date) VALUES
    ('AI Recommendation Engine',   5,  850000.00, '2024-01-15', '2024-09-30'),
    ('Customer Churn Predictor',   2,  420000.00, '2024-03-01', '2024-12-31'),
    ('ERP System Migration',       1, 1200000.00, '2023-11-01', '2025-03-31'),
    ('Brand Campaign Analytics',   4,  310000.00, '2024-06-01', '2024-11-30'),
    ('Fraud Detection Pipeline',  18,  680000.00, '2024-02-10', '2024-10-15');

-- ─────────────────────────────────────────────────────────────
-- Query B1: 3-table JOIN
--   employee name · department budget · project budget
-- ─────────────────────────────────────────────────────────────
SELECT
    e.first_name || ' ' || e.last_name  AS lead_employee,
    d.dept_name,
    d.budget                             AS dept_budget,
    p.project_name,
    p.budget                             AS project_budget,
    p.start_date,
    p.end_date
FROM projects    AS p
JOIN employees   AS e ON p.lead_emp_id = e.emp_id
JOIN departments AS d ON e.dept_id     = d.dept_id
ORDER BY p.budget DESC;

-- ─────────────────────────────────────────────────────────────
-- Query B2: departments where total project budget > dept budget
-- ─────────────────────────────────────────────────────────────
SELECT
    d.dept_name,
    d.budget                          AS dept_budget,
    SUM(p.budget)                     AS total_project_budget,
    ROUND(SUM(p.budget) - d.budget, 2) AS over_budget_by
FROM departments AS d
JOIN employees   AS e ON e.dept_id     = d.dept_id
JOIN projects    AS p ON p.lead_emp_id = e.emp_id
GROUP BY d.dept_name, d.budget
HAVING SUM(p.budget) > d.budget
ORDER BY over_budget_by DESC;
