-- =============================================================
-- interview_answers.sql
-- Part C: Interview-Ready Questions
-- Day 14 · PM Take-Home Assignment
-- Week 3 · PG Diploma · AI-ML & Agentic AI · IIT Gandhinagar
-- =============================================================


-- ─────────────────────────────────────────────────────────────
-- Q1 — RANK() vs DENSE_RANK(): explanation + demo
-- ─────────────────────────────────────────────────────────────
/*
Both RANK() and DENSE_RANK() assign ranks to rows within a partition,
but they differ in how they handle TIES:

  RANK():
    • Tied rows get the SAME rank.
    • The NEXT rank SKIPS numbers equal to the number of ties.
    • Example: positions 1, 1, 3, 4, 4, 6   ← position 2 and 5 are skipped.

  DENSE_RANK():
    • Tied rows get the SAME rank.
    • The NEXT rank is ALWAYS consecutive — no gaps.
    • Example: positions 1, 1, 2, 3, 3, 4   ← no gaps.

WHEN DOES IT MATTER IN BUSINESS?

  TOP-N reports:
    Scenario: "Show the top 3 highest-paid employees per department."
    If two employees tie at the highest salary:
      RANK()       → positions 1, 1, 3   (only 1 gets position 2, so you
                      may return 2 rows labelled 1, then skip to 3 → confusing)
      DENSE_RANK() → positions 1, 1, 2   (the next distinct salary is rank 2;
                      "top 3" cleanly includes positions 1, 2, 3)

  Pagination:
    RANK() gaps cause off-by-one errors in paginated result sets.
    DENSE_RANK() is safer when downstream code expects consecutive rank numbers.

  Competition/leaderboards:
    Olympic scoring uses RANK() deliberately — a tie for gold means no silver.
    Sales performance dashboards typically use DENSE_RANK() to avoid
    confusing gaps: if two reps tie for 1st, the next rep is "2nd", not "3rd".

RULE OF THUMB:
  Use RANK()       when gaps are meaningful (competition, percentile buckets).
  Use DENSE_RANK() when you want clean consecutive ranks without gaps (most reporting).
  Use ROW_NUMBER() when you need uniqueness even among ties (deduplication, pagination).
*/

-- Live demo on employees table
SELECT
    e.first_name || ' ' || e.last_name  AS employee,
    d.dept_name,
    e.salary,
    RANK()       OVER (PARTITION BY d.dept_name ORDER BY e.salary DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY d.dept_name ORDER BY e.salary DESC) AS dense_rnk,
    ROW_NUMBER() OVER (PARTITION BY d.dept_name ORDER BY e.salary DESC) AS row_num
FROM employees   AS e
JOIN departments AS d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.salary DESC;


-- ─────────────────────────────────────────────────────────────
-- Q2 — Users who purchased in 3+ consecutive months
-- ─────────────────────────────────────────────────────────────
/*
APPROACH:
  1. Deduplicate to one row per (user, month) — a user who buys
     twice in March still only counts as "March".
  2. Use LAG() to look at the previous month for that user.
  3. Check if current month = previous month + 1 month exactly.
  4. Use a running count of consecutive months: reset to 1 when
     the streak breaks, increment when it continues.
  5. Flag users where the max streak reached >= 3.

The streak reset trick:
  consecutive = CASE WHEN curr_month = prev_month + 1 month THEN prev_consecutive + 1
                     ELSE 1 END
  But window functions can't reference their own output, so we use
  a second CTE pass (streak_calc) or a self-join on row numbers.

  Cleanest approach: use ROW_NUMBER subtraction.
    month_number - ROW_NUMBER() OVER (PARTITION BY user ORDER BY month)
    is CONSTANT for a streak, because both increment together.
    Different streaks produce different constants → GROUP BY that constant.
*/

WITH monthly_purchases AS (
    -- Step 1: deduplicate to one row per (user, month)
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', transaction_date)::DATE  AS purchase_month
    FROM transactions
),
numbered AS (
    -- Step 2: assign a row number per user ordered by month
    SELECT
        user_id,
        purchase_month,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY purchase_month
        )  AS rn
),
streak_groups AS (
    -- Step 3: (purchase_month - rn months) is constant within a consecutive run
    -- Cast rn to interval for subtraction
    SELECT
        user_id,
        purchase_month,
        (purchase_month - (rn || ' months')::INTERVAL)::DATE AS streak_id
    FROM numbered
),
streak_lengths AS (
    -- Step 4: count how many months each streak contains per user
    SELECT
        user_id,
        streak_id,
        COUNT(*)        AS streak_length,
        MIN(purchase_month) AS streak_start,
        MAX(purchase_month) AS streak_end
    FROM streak_groups
    GROUP BY user_id, streak_id
)
SELECT DISTINCT
    user_id,
    MAX(streak_length)  AS max_consecutive_months,
    MIN(streak_start)   AS earliest_streak_start,
    MAX(streak_end)     AS latest_streak_end
FROM streak_lengths
WHERE streak_length >= 3
GROUP BY user_id
ORDER BY user_id;


-- ─────────────────────────────────────────────────────────────
-- Q3 — Optimise correlated subquery → window function
-- ─────────────────────────────────────────────────────────────
/*
ORIGINAL (correlated subquery — O(n²)):

  SELECT name, salary
  FROM employees e1
  WHERE salary > (
      SELECT AVG(salary)
      FROM employees e2
      WHERE e2.department = e1.department
  );

WHY IT IS SLOW:
  The subquery runs ONCE PER ROW in the outer query.
  For a table with N employees, PostgreSQL executes the AVG()
  subquery N times, each scanning rows with the same dept_id.
  Time complexity is O(n²) in the worst case.

  EXPLAIN shows this as a "Correlated SubPlan" node — a nested loop
  where the inner plan re-executes for every outer row.
  On 1M employees this is catastrophically slow.

WINDOW FUNCTION REWRITE (O(n) — single pass):
  AVG() OVER (PARTITION BY dept_id) computes the department average
  ONCE for all rows in each partition, during a single table scan.
  The result is then attached to every row — no repeated scans.

  EXPLAIN shows this as a WindowAgg node — one sequential scan,
  one aggregation pass, no nested loops.
*/

-- ORIGINAL (slow — runs a subquery for every row):
-- SELECT name, salary
-- FROM employees e1
-- WHERE salary > (SELECT AVG(salary) FROM employees e2
--                 WHERE e2.department = e1.department);

-- OPTIMISED — single-pass window function:
SELECT
    e.first_name || ' ' || e.last_name  AS employee_name,
    d.dept_name,
    e.salary,
    ROUND(dept_avg.avg_dept_salary, 2)  AS dept_avg_salary
FROM employees AS e
JOIN departments AS d ON e.dept_id = d.dept_id
JOIN (
    -- Pre-compute dept averages once (one scan, O(n))
    SELECT dept_id, AVG(salary) AS avg_dept_salary
    FROM   employees
    GROUP  BY dept_id
) AS dept_avg ON dept_avg.dept_id = e.dept_id
WHERE e.salary > dept_avg.avg_dept_salary
ORDER BY d.dept_name, e.salary DESC;

-- WINDOW FUNCTION VERSION (most idiomatic):
SELECT employee_name, dept_name, salary, dept_avg_salary
FROM (
    SELECT
        e.first_name || ' ' || e.last_name     AS employee_name,
        d.dept_name,
        e.salary,
        ROUND(
            AVG(e.salary) OVER (PARTITION BY e.dept_id)
        , 2)                                    AS dept_avg_salary
    FROM employees   AS e
    JOIN departments AS d ON e.dept_id = d.dept_id
) sub
WHERE salary > dept_avg_salary
ORDER BY dept_name, salary DESC;

/*
EXPLAIN comparison (run both with EXPLAIN ANALYZE on a large table):

  Correlated subquery:
    → Seq Scan on employees (outer)
      → SubPlan: Aggregate (inner) — executed N times
    Estimated cost scales as O(n²)

  Window function / pre-aggregated JOIN:
    → Hash Join
      → Seq Scan on employees
      → HashAggregate (dept averages, computed once)
    → WindowAgg
    Estimated cost scales as O(n)

  On 1M rows: correlated subquery may take minutes; window function
  completes in seconds because the table is read only twice (or once
  for the pure window version) instead of N+1 times.
*/
