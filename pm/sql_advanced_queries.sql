-- =============================================================
-- sql_advanced_queries.sql
-- Part A: Subqueries, Window Functions & CTEs
-- Day 14 · PM Take-Home Assignment
-- Week 3 · PG Diploma · AI-ML & Agentic AI · IIT Gandhinagar
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- SCHEMA SETUP
-- Run this once to create and populate the tables.
-- ─────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS orders     CASCADE;
DROP TABLE IF EXISTS customers  CASCADE;
DROP TABLE IF EXISTS products   CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;

-- Re-use employees + departments from AM session (sql_queries.sql).
-- If running standalone, uncomment and run the AM schema first.

-- Products
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category      VARCHAR(50)  NOT NULL,
    unit_price    NUMERIC(10,2)
);

-- Customers
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city          VARCHAR(50)  NOT NULL,
    email         VARCHAR(100)
);

-- Orders (revenue fact table)
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT          REFERENCES customers(customer_id),
    product_id    INT          REFERENCES products(product_id),
    order_date    DATE         NOT NULL,
    quantity      INT          NOT NULL,
    revenue       NUMERIC(12,2) NOT NULL
);

-- Transactions (for Part C Q2 — consecutive months)
CREATE TABLE transactions (
    user_id          INT,
    transaction_date DATE,
    amount           NUMERIC(10,2)
);

-- ── Products ──────────────────────────────────────────────────
INSERT INTO products (product_name, category, unit_price) VALUES
    ('Laptop Pro 15',        'Electronics',   85000),
    ('Wireless Headphones',  'Electronics',   12000),
    ('Python Programming',   'Books',            599),
    ('Data Science Handbook','Books',            799),
    ('Office Chair Ergo',    'Furniture',      18000),
    ('Standing Desk',        'Furniture',      35000),
    ('Smartwatch X2',        'Electronics',   22000),
    ('SQL Mastery Guide',    'Books',            499),
    ('Monitor 4K 27"',       'Electronics',   42000),
    ('Bookshelf Oak',        'Furniture',      12500);

-- ── Customers ─────────────────────────────────────────────────
INSERT INTO customers (customer_name, city, email) VALUES
    ('Rahul Sharma',    'Mumbai',    'rahul@example.com'),
    ('Priya Patel',     'Delhi',     'priya@example.com'),
    ('Arjun Nair',      'Mumbai',    'arjun@example.com'),
    ('Sneha Reddy',     'Hyderabad', 'sneha@example.com'),
    ('Vikram Singh',    'Delhi',     'vikram@example.com'),
    ('Ananya Iyer',     'Bengaluru', 'ananya@example.com'),
    ('Deepak Menon',    'Mumbai',    'deepak@example.com'),
    ('Kavitha Das',     'Hyderabad', 'kavitha@example.com'),
    ('Rohan Gupta',     'Bengaluru', 'rohan@example.com'),
    ('Lakshmi Venkat',  'Delhi',     'lakshmi@example.com'),
    ('Aditya Joshi',    'Mumbai',    'aditya@example.com'),
    ('Meena Pillai',    'Bengaluru', 'meena@example.com');

-- ── Orders (spanning Jan–Jun 2024, some months sparse) ────────
INSERT INTO orders (customer_id, product_id, order_date, quantity, revenue) VALUES
    (1,  1, '2024-01-05',  1,  85000),
    (2,  3, '2024-01-12',  2,   1198),
    (3,  7, '2024-01-20',  1,  22000),
    (4,  2, '2024-01-28',  1,  12000),
    (5,  9, '2024-02-03',  1,  42000),
    (6,  5, '2024-02-10',  2,  36000),
    (7,  1, '2024-02-14',  1,  85000),
    (8,  4, '2024-02-22',  3,   2397),
    (1,  9, '2024-03-01',  1,  42000),
    (2,  6, '2024-03-08',  1,  35000),
    (3,  2, '2024-03-15',  2,  24000),
    (9,  8, '2024-03-22',  5,   2495),
    (10, 1, '2024-03-28',  1,  85000),
    (11, 7, '2024-04-05',  1,  22000),
    (4,  5, '2024-04-12',  1,  18000),
    (5,  3, '2024-04-18',  4,   2396),
    (6,  9, '2024-04-25',  1,  42000),
    (12, 6, '2024-04-30',  1,  35000),
    (7,  2, '2024-05-06',  3,  36000),
    (8,  1, '2024-05-14',  1,  85000),
    -- Gap in May for Electronics to make the series sparse
    (9,  4, '2024-05-20',  2,   1598),
    (10, 8, '2024-05-27',  3,   1497),
    (1,  6, '2024-06-02',  1,  35000),
    (2,  1, '2024-06-10',  1,  85000),
    (3,  9, '2024-06-18',  2,  84000),
    (11, 3, '2024-06-24',  3,   1797),
    (4,  7, '2024-06-28',  1,  22000),
    -- Extra high-revenue rows for top-N per city
    (1,  1, '2024-03-10',  2, 170000),   -- Rahul Mumbai big order
    (7,  9, '2024-05-01',  3, 126000),   -- Deepak Mumbai
    (11, 6, '2024-02-20',  2,  70000),   -- Aditya Mumbai
    (5,  1, '2024-04-08',  1,  85000),   -- Vikram Delhi
    (10, 9, '2024-06-05',  1,  42000),   -- Lakshmi Delhi
    (2,  7, '2024-01-15',  2,  44000),   -- Priya Delhi
    (6,  1, '2024-05-22',  1,  85000),   -- Ananya Bengaluru
    (9,  9, '2024-03-05',  2,  84000),   -- Rohan Bengaluru
    (12, 1, '2024-06-15',  1,  85000);   -- Meena Bengaluru

-- ── Transactions (for Part C Q2) ─────────────────────────────
INSERT INTO transactions (user_id, transaction_date, amount) VALUES
    -- User 1: buys every month Jan–Jun → qualifies
    (1, '2024-01-15', 1200), (1, '2024-02-10', 800),  (1, '2024-03-22', 950),
    (1, '2024-04-05', 600),  (1, '2024-05-18', 1100), (1, '2024-06-30', 750),
    -- User 2: buys Jan, Feb, Apr → not 3 consecutive
    (2, '2024-01-20', 500),  (2, '2024-02-14', 700),  (2, '2024-04-10', 300),
    -- User 3: buys Mar, Apr, May → qualifies
    (3, '2024-03-01', 900),  (3, '2024-04-15', 1500), (3, '2024-05-28', 400),
    -- User 4: single purchase
    (4, '2024-02-28', 200),
    -- User 5: Feb, Mar, Apr, May → qualifies
    (5, '2024-02-08', 300),  (5, '2024-03-19', 850),
    (5, '2024-04-22', 670),  (5, '2024-05-11', 920);


-- =============================================================
-- PART A: 5 QUERIES
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- A1. Running total: cumulative revenue per category by date
-- ─────────────────────────────────────────────────────────────
--
-- Window function: SUM() OVER with PARTITION BY category,
-- ORDER BY order_date, and the default frame (RANGE UNBOUNDED
-- PRECEDING) gives a true running total within each partition.
-- ─────────────────────────────────────────────────────────────
SELECT
    p.category,
    o.order_date,
    o.revenue,
    SUM(o.revenue) OVER (
        PARTITION BY p.category
        ORDER BY o.order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )  AS cumulative_revenue
FROM orders   AS o
JOIN products AS p ON o.product_id = p.product_id
ORDER BY p.category, o.order_date;


-- ─────────────────────────────────────────────────────────────
-- A2. Top-3 customers by total revenue per city (ROW_NUMBER)
-- ─────────────────────────────────────────────────────────────
--
-- CTE first aggregates total revenue per customer, then
-- ROW_NUMBER() partitions by city and ranks by revenue.
-- Outer query filters to rn <= 3.
-- ─────────────────────────────────────────────────────────────
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.city,
        SUM(o.revenue) AS total_revenue
    FROM customers AS c
    JOIN orders    AS o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.city
),
ranked AS (
    SELECT
        city,
        customer_name,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY total_revenue DESC
        ) AS rn
    FROM customer_revenue
)
SELECT
    city,
    rn              AS rank_in_city,
    customer_name,
    total_revenue
FROM ranked
WHERE rn <= 3
ORDER BY city, rn;


-- ─────────────────────────────────────────────────────────────
-- A3. Month-over-month revenue change % using LAG
--     Flag months with < −5% change
-- ─────────────────────────────────────────────────────────────
--
-- Step 1 (monthly_rev CTE): aggregate revenue by month.
-- Step 2 (mom CTE): LAG() fetches previous month's revenue.
-- Step 3: compute % change, flag when < -5%.
-- NULLIF prevents division-by-zero on the first month row.
-- ─────────────────────────────────────────────────────────────
WITH monthly_rev AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE  AS month,
        SUM(revenue)                            AS monthly_revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
),
mom AS (
    SELECT
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (ORDER BY month)  AS prev_revenue,
        ROUND(
            (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
            / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0) * 100
        , 2)  AS mom_pct_change
    FROM monthly_rev
)
SELECT
    month,
    monthly_revenue,
    prev_revenue,
    mom_pct_change,
    CASE
        WHEN mom_pct_change < -5 THEN '⚠ DROP > 5%'
        ELSE '✓ OK'
    END  AS flag
FROM mom
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- A4. Multi-CTE: departments where ALL employees earn above
--     the company average salary
-- ─────────────────────────────────────────────────────────────
--
-- CTE 1 (company_avg): single scalar — the overall avg salary.
-- CTE 2 (dept_minimums): min salary per dept (the weakest link).
-- If a dept's minimum salary > company average,
-- then every employee in that dept earns above average.
-- ─────────────────────────────────────────────────────────────
WITH company_avg AS (
    SELECT AVG(salary) AS avg_sal
    FROM employees
),
dept_minimums AS (
    SELECT
        d.dept_name,
        MIN(e.salary)   AS min_salary,
        COUNT(e.emp_id) AS headcount
    FROM employees   AS e
    JOIN departments AS d ON e.dept_id = d.dept_id
    GROUP BY d.dept_name
)
SELECT
    dm.dept_name,
    dm.min_salary,
    dm.headcount,
    ROUND(ca.avg_sal, 2)  AS company_avg_salary,
    'All above avg'        AS status
FROM dept_minimums  AS dm
CROSS JOIN company_avg AS ca
WHERE dm.min_salary > ca.avg_sal
ORDER BY dm.min_salary DESC;
-- NOTE: With this dataset (company avg = 75,500), every dept has at least
-- one employee below avg → query correctly returns 0 rows.
-- This is the RIGHT answer, not a bug. To test: raise a junior employee's
-- salary in a small dept above 75,500 and re-run.


-- ─────────────────────────────────────────────────────────────
-- A5. Correlated subquery: 2nd highest salary per department
--     WITHOUT window functions
-- ─────────────────────────────────────────────────────────────
--
-- For each employee e1, the correlated subquery counts how many
-- DISTINCT salaries are strictly greater than e1.salary within
-- the same department. If exactly 1 salary is higher, then
-- e1 has the 2nd highest salary in that department.
--
-- Why exactly 1? If 0 → e1 is the highest. If 2+ → e1 is 3rd or lower.
-- Using DISTINCT handles ties correctly.
-- ─────────────────────────────────────────────────────────────
SELECT
    e1.emp_id,
    e1.first_name || ' ' || e1.last_name  AS employee,
    d.dept_name,
    e1.salary                              AS second_highest_salary
FROM employees   AS e1
JOIN departments AS d ON e1.dept_id = d.dept_id
WHERE (
    SELECT COUNT(DISTINCT e2.salary)
    FROM employees AS e2
    WHERE e2.dept_id = e1.dept_id
      AND e2.salary > e1.salary
) = 1
ORDER BY d.dept_name, e1.salary DESC;
