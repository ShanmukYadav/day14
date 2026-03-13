# Day 14 · PM Take-Home — SQL Advanced
### Subqueries · Window Functions · CTEs · Recursive CTEs

> **Week 3 · PG Diploma · AI-ML & Agentic AI Engineering · IIT Gandhinagar**
> **Submission:** GitHub commit → link via LMS
> **Due:** Day 16 · 09:15 AM

---

## 📁 Project Structure

```
sql_advanced/
├── sql_advanced_queries.sql   # Part A — 5 core queries (window fns, CTEs, subqueries)
├── recursive_cte.sql          # Part B — recursive CTEs: 1–100 series + date spine
├── interview_answers.sql      # Part C — RANK vs DENSE_RANK, consecutive months, optimise
├── ai_augmented_task.md       # Part D — 3 AI questions, verified, self-assessed
└── README.md
```

> **Prerequisite:** Run `sql_queries.sql` from the AM session first — it creates the `employees` and `departments` tables used in Parts A and C.

---

## ▶️ How to Run

```bash
psql -U postgres -d your_database

\i ../sql_foundations/sql_queries.sql   -- AM schema (employees, departments)
\i sql_advanced_queries.sql             -- creates orders, customers, products, transactions + Part A
\i recursive_cte.sql                    -- Part B
\i interview_answers.sql                -- Part C
```

---

## 📝 Part A — `sql_advanced_queries.sql` (40%)

### A1 — Running Total: Cumulative Revenue per Category by Date

**Technique:** `SUM() OVER (PARTITION BY category ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`

Key detail: `ROWS` frame is used explicitly instead of the default `RANGE`. With `RANGE`, ties on `order_date` within the same category would be aggregated together rather than accumulated row-by-row — producing an incorrect "jump" in the running total. `ROWS` processes each physical row in order.

---

### A2 — Top-3 Customers by Revenue per City

**Technique:** Two-CTE approach — aggregate total revenue per customer first, then `ROW_NUMBER() OVER (PARTITION BY city ORDER BY total_revenue DESC)`, filter `WHERE rn <= 3`.

Why `ROW_NUMBER()` instead of `RANK()`? If two customers tie for 3rd in a city, `RANK()` would return both (positions 3, 3) plus a gap, giving 4 rows for that city. `ROW_NUMBER()` guarantees exactly 3 rows per city, which is typically what "Top-3" reports require.

---

### A3 — Month-over-Month Revenue Change % with LAG + Flagging

**Technique:**
1. `DATE_TRUNC('month', order_date)` aggregates to monthly buckets.
2. `LAG(monthly_revenue) OVER (ORDER BY month)` fetches the prior month's revenue.
3. `(current - prev) / NULLIF(prev, 0) * 100` computes percentage — `NULLIF` prevents division-by-zero on the first row.
4. `CASE WHEN mom_pct_change < -5 THEN '⚠ DROP > 5%'` flags problem months.

---

### A4 — Multi-CTE: Departments Where ALL Employees Earn Above Company Average

**Technique:** Two CTEs:
- `company_avg`: single scalar AVG across all employees.
- `dept_minimums`: `MIN(salary)` per department — if even the lowest earner in a dept beats the company average, then every employee does.

`CROSS JOIN company_avg` attaches the scalar to every dept row for comparison in `WHERE`.

---

### A5 — 2nd Highest Salary per Department (No Window Functions)

**Technique:** Correlated subquery — for each employee `e1`, count `DISTINCT` salaries in the same department that are strictly greater. Exactly 1 higher salary = 2nd highest.

```sql
WHERE (
    SELECT COUNT(DISTINCT e2.salary)
    FROM employees e2
    WHERE e2.dept_id = e1.dept_id AND e2.salary > e1.salary
) = 1
```

`COUNT(DISTINCT salary)` handles salary ties — without `DISTINCT`, two people tied at the top would give count = 2 instead of 1, incorrectly skipping the second distinct salary level.

---

## 📝 Part B — `recursive_cte.sql` (30%)

### B1 — Generate 1 to 100 (Recursive CTE)

```sql
WITH RECURSIVE nums AS (
    SELECT 1 AS n           -- anchor
    UNION ALL
    SELECT n + 1 FROM nums
    WHERE n < 100           -- termination guard
)
SELECT n FROM nums ORDER BY n;
```

**How it works:** The anchor produces row `{1}`. Each recursive step reads the current result and appends `n+1`. PostgreSQL iterates until the `WHERE n < 100` guard stops it. Without the guard: infinite loop — PostgreSQL enforces `max_recursion_depth` (default 100) as a safety net.

---

### B2 — Fill Missing Dates in a Sparse Time Series

**The real-world problem:** Any day with no orders is absent from the `orders` table. A dashboard plotting daily revenue would show gaps instead of zero — breaking rolling averages, time-series models, and visual charts.

**Solution — date spine + LEFT JOIN:**
```
date_range CTE    → every calendar date from min to max order_date (recursive)
daily_revenue CTE → actual revenue per date (from orders)
Final query       → LEFT JOIN date_range → daily_revenue, COALESCE(revenue, 0)
```

### B3 — Sparse Time Series per Category (Bonus)

Extends B2 with a `CROSS JOIN categories` to build a full `(date × category)` grid. This is the foundation of most BI/ETL pipelines — a complete grid ensures every dimension combination appears in aggregations.

---

## 📝 Part C — `interview_answers.sql` (20%)

### Q1 — RANK() vs DENSE_RANK()

| | `RANK()` | `DENSE_RANK()` | `ROW_NUMBER()` |
|---|---|---|---|
| Ties | Same rank | Same rank | Always unique |
| After tie | Skips numbers | No gap | Always +1 |
| Example (3 tied at 1st) | 1, 1, 1, 4 | 1, 1, 1, 2 | 1, 2, 3, 4 |
| Use case | Competitions | Reporting / Top-N | Deduplication / Pagination |

**Business rule:** Use `DENSE_RANK()` for "Top-N per group" reports. Use `RANK()` when gaps are semantically meaningful (e.g., "no one earned silver because two tied for gold").

### Q2 — Users with 3+ Consecutive Monthly Purchases

**The key insight — ROW_NUMBER subtraction trick:**
```
month_number (chronological) - ROW_NUMBER (per user)
```
Both increment together during a streak, so their difference is **constant** within each consecutive run. Different streaks produce different constants → `GROUP BY` that constant to isolate each island. Count rows per island = streak length.

### Q3 — Correlated Subquery → Window Function Optimisation

| | Correlated Subquery | Window Function |
|---|---|---|
| Complexity | O(n²) — subquery re-runs per outer row | O(n) — single pass with partition aggregation |
| EXPLAIN node | `SubPlan` (nested loop) | `WindowAgg` |
| 1M rows | Minutes | Seconds |
| Readability | Verbose | Concise |

**Why O(n²)?** For N employees, the `AVG()` subquery executes N times, each scanning dept rows. With no index on `dept_id` that's O(n) per subquery call × N calls = O(n²).

**Window function fix:** `AVG(salary) OVER (PARTITION BY dept_id)` computes all department averages in one pass and attaches results to every row — no repeated scans.

---

## 📝 Part D — `ai_augmented_task.md` (10%)

See [`ai_augmented_task.md`](./ai_augmented_task.md) for the full prompt, raw AI output, verified runs, and honest self-assessment.

**3 AI questions generated:**

| # | Topic | Difficulty | Verified |
|---|---|---|---|
| Q1 | Conditional running total + RANGE vs ROWS frame | Senior ✅ | ✅ Ran on orders table |
| Q2 | Gap and island problem (streak detection) | Senior ✅ | ✅ Ran on transactions table |
| Q3 | Top-N without window functions (correlated subquery) | Mid-Senior ✅ | ✅ Ran on employees table |

**Common mistakes — personally made:**
- Q1: Omitted `ROWS` frame clause on first draft → `RANGE` caused same-date aggregation bug ✅
- Q2: Used LAG() for boundary detection initially → adopted subtraction trick ✅
- Q3: Wrote `>` instead of `>=` on first attempt → returned wrong rows ✅

---

## 🧠 Key Concepts Covered

- **Window functions:** `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `SUM() OVER`, `AVG() OVER`, `LAG()`, `LEAD()`
- **Frame clauses:** `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` vs `RANGE`
- **CTEs:** single-step, multi-step, chained CTEs
- **Recursive CTEs:** anchor + recursive member, termination guard, date spine generation
- **Subqueries:** scalar, `IN`, correlated (with `EXISTS` and `COUNT`)
- **Gap and island:** ROW_NUMBER subtraction trick for consecutive streak detection
- **Performance:** correlated subquery O(n²) vs window function O(n); EXPLAIN plan reading
- **Date spine:** `CROSS JOIN` to fill sparse time series with zero values

---

*Assignment completed · Day 14 · PM Session*
