-- =============================================================
-- recursive_cte.sql
-- Part B: Recursive CTEs
-- Day 14 · PM Take-Home Assignment
-- Week 3 · PG Diploma · AI-ML & Agentic AI · IIT Gandhinagar
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- B1. Generate a number series 1–100 with a recursive CTE
--     No hard-coded values — only the seed (1) and stop (100).
-- ─────────────────────────────────────────────────────────────
--
-- HOW IT WORKS:
--   • Anchor member  : SELECT 1 AS n          → produces the first row
--   • Recursive member: SELECT n + 1 FROM nums → adds one each iteration
--   • UNION ALL combines anchor + each recursion level
--   • WHERE n < 100 is the termination guard (without it = infinite loop)
--   • PostgreSQL requires the RECURSIVE keyword on the WITH clause
-- ─────────────────────────────────────────────────────────────
WITH RECURSIVE nums AS (
    -- Anchor: starting value
    SELECT 1 AS n

    UNION ALL

    -- Recursive step: increment by 1 each iteration
    SELECT n + 1
    FROM   nums
    WHERE  n < 100          -- termination condition
)
SELECT n
FROM   nums
ORDER  BY n;


-- ─────────────────────────────────────────────────────────────
-- B2. Fill missing dates in a sparse time series
--     Dates with no orders appear with revenue = 0
-- ─────────────────────────────────────────────────────────────
--
-- REAL DE INTERVIEW PROBLEM — common in reporting pipelines:
-- a product's sales table has gaps on days with no orders.
-- Dashboards need every date to appear (with 0) for correct
-- time-series charts and rolling averages.
--
-- APPROACH:
--   CTE 1 (date_range):   recursive CTE generates every calendar
--                          date from min(order_date) to max(order_date)
--   CTE 2 (daily_revenue): aggregate actual revenue per date
--   Final query:           LEFT JOIN date_range → daily_revenue,
--                          COALESCE(revenue, 0) fills the gaps
-- ─────────────────────────────────────────────────────────────
WITH RECURSIVE date_range AS (
    -- Anchor: earliest order date in the dataset
    SELECT MIN(order_date) AS dt
    FROM   orders

    UNION ALL

    -- Recursive step: advance one day at a time
    SELECT dt + INTERVAL '1 day'
    FROM   date_range
    WHERE  dt < (SELECT MAX(order_date) FROM orders)  -- stop at last order
),
daily_revenue AS (
    SELECT
        order_date,
        SUM(revenue) AS total_revenue
    FROM orders
    GROUP BY order_date
)
SELECT
    dr.dt                                            AS order_date,
    COALESCE(drev.total_revenue, 0)                  AS revenue,
    CASE WHEN drev.total_revenue IS NULL
         THEN 'NO ORDERS'
         ELSE 'HAS ORDERS'
    END                                              AS day_status
FROM date_range   AS dr
LEFT JOIN daily_revenue AS drev ON dr.dt = drev.order_date
ORDER BY dr.dt;


-- ─────────────────────────────────────────────────────────────
-- B3. Bonus: sparse time series per CATEGORY
--     Every category appears on every date, 0 when no orders
-- ─────────────────────────────────────────────────────────────
--
-- Cross the date spine with the list of categories to get
-- a complete (date × category) grid, then left-join actuals.
-- This is the backbone of most BI/reporting ETL pipelines.
-- ─────────────────────────────────────────────────────────────
WITH RECURSIVE date_range AS (
    SELECT MIN(order_date) AS dt FROM orders
    UNION ALL
    SELECT dt + INTERVAL '1 day'
    FROM   date_range
    WHERE  dt < (SELECT MAX(order_date) FROM orders)
),
categories AS (
    SELECT DISTINCT category FROM products
),
date_category_grid AS (
    -- Every (date, category) combination — the full grid
    SELECT dr.dt, c.category
    FROM   date_range AS dr
    CROSS JOIN categories AS c
),
daily_cat_revenue AS (
    SELECT
        o.order_date,
        p.category,
        SUM(o.revenue) AS revenue
    FROM orders   AS o
    JOIN products AS p ON o.product_id = p.product_id
    GROUP BY o.order_date, p.category
)
SELECT
    g.dt          AS order_date,
    g.category,
    COALESCE(dcr.revenue, 0) AS revenue
FROM date_category_grid  AS g
LEFT JOIN daily_cat_revenue AS dcr
    ON g.dt = dcr.order_date AND g.category = dcr.category
ORDER BY g.category, g.dt;
