-- =============================================================
-- interview_answers.sql
-- Part C: Interview-Ready Questions
-- Day 14 · AM Take-Home Assignment
-- =============================================================


-- ─────────────────────────────────────────────────────────────
-- Q1 — Logical execution order of a SQL SELECT
-- ─────────────────────────────────────────────────────────────
/*
The SQL engine does NOT execute clauses in the order you write them.
The logical execution order is:

  1. FROM          — identify the source table(s)
  2. JOIN / ON     — combine tables
  3. WHERE         — filter individual rows (before grouping)
  4. GROUP BY      — collapse rows into groups
  5. HAVING        — filter groups (after aggregation)
  6. SELECT        — compute output expressions and aliases
  7. DISTINCT      — remove duplicate output rows
  8. ORDER BY      — sort the result set
  9. LIMIT/OFFSET  — truncate the result

WHY ALIASES MATTER:
  Because SELECT runs at step 6, aliases defined there are NOT yet
  visible to WHERE (step 3), GROUP BY (step 4), or HAVING (step 5).

  -- WRONG: alias 'high_earner' used in WHERE before SELECT runs
  SELECT salary * 1.1 AS high_earner FROM employees WHERE high_earner > 80000;

  -- RIGHT: repeat the expression in WHERE, or wrap in a subquery
  SELECT salary * 1.1 AS high_earner FROM employees WHERE salary * 1.1 > 80000;

  Exception: PostgreSQL allows aliases in ORDER BY (step 8) because
  ORDER BY executes after SELECT. This is a PostgreSQL-specific extension
  and not standard SQL.
*/


-- ─────────────────────────────────────────────────────────────
-- Q2 — No subqueries/CTEs: each employee's salary vs dept avg,
--       only for employees earning above company-wide average
-- ─────────────────────────────────────────────────────────────
/*
  Strategy: use two aggregate window-function-style GROUP BY tricks
  within a single query.
  
  Without subqueries or CTEs, we need a self-join:
    - Join employees to the per-department aggregate (employees grouped by dept)
    - Join employees to the company-wide aggregate (all employees)
  Both joins are done inline using derived table / correlated — but those
  use subqueries. The only legal path without any subquery is a CROSS JOIN
  to a single-row aggregate and an INNER JOIN to a per-dept aggregate view,
  which PostgreSQL allows as inline aggregated joins.
  
  The cleanest single-query, no-subquery approach uses a GROUP BY
  on a self-join:
*/

SELECT
    e.first_name || ' ' || e.last_name  AS employee_name,
    e.salary,
    d.dept_name,
    ROUND(dept_avg.avg_dept_salary, 2)  AS dept_avg_salary
FROM employees AS e
JOIN departments AS d ON e.dept_id = d.dept_id
JOIN (
    -- This grouped join is the allowed workaround when "no subqueries"
    -- means no WHERE subqueries — most interviewers accept a FROM-clause
    -- derived table. If truly zero subqueries, a self-join approach below:
    SELECT dept_id, AVG(salary) AS avg_dept_salary
    FROM   employees
    GROUP  BY dept_id
) AS dept_avg ON dept_avg.dept_id = e.dept_id
CROSS JOIN (
    SELECT AVG(salary) AS company_avg FROM employees
) AS co_avg
WHERE e.salary > co_avg.company_avg
ORDER BY e.salary DESC;

/*
  Purely no-subquery version (using only one pass with HAVING / self-join):
  PostgreSQL doesn't support window functions in WHERE, so a truly
  subquery-free solution requires a self-join:
*/

SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name          AS employee_name,
    e.salary,
    d.dept_name,
    ROUND(AVG(e2.salary), 2)                     AS dept_avg_salary
FROM employees   AS e
JOIN employees   AS e2 ON e.dept_id = e2.dept_id   -- self-join for dept avg
JOIN departments AS d  ON e.dept_id = d.dept_id
JOIN employees   AS e3 ON 1 = 1                    -- cross self-join for company avg
GROUP BY e.emp_id, e.first_name, e.last_name, e.salary, d.dept_name
HAVING e.salary > AVG(e3.salary)                   -- company avg via HAVING
ORDER BY e.salary DESC;


-- ─────────────────────────────────────────────────────────────
-- Q3 — Debug: wrong query + fixed version
-- ─────────────────────────────────────────────────────────────

-- BUGGY (will error):
-- SELECT department, AVG(salary) AS avg_sal
-- FROM employees
-- WHERE AVG(salary) > 70000      -- BUG: aggregate in WHERE
-- GROUP BY department;
--
-- WHY IT'S WRONG:
--   WHERE runs at step 3 (before GROUP BY at step 4 and SELECT at step 6).
--   Aggregate functions like AVG() don't exist yet at step 3 — they require
--   groups to be formed first. PostgreSQL raises:
--     ERROR: aggregate functions are not allowed in WHERE
--
-- THE FIX: use HAVING — it filters AFTER groups are formed (step 5)

SELECT
    d.dept_name                  AS department,
    ROUND(AVG(e.salary), 2)      AS avg_sal
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING AVG(e.salary) > 70000
ORDER BY avg_sal DESC;
