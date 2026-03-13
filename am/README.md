# Day 14 · AM Take-Home — SQL Foundations
### PostgreSQL · SELECT · WHERE · JOINs · Aggregations

> **Week 3 · PG Diploma · AI-ML & Agentic AI Engineering · IIT Gandhinagar**
> **Submission:** GitHub commit → link via LMS
> **Due:** Day 16 · 09:15 AM

---

## 📁 Project Structure

```
sql_foundations/
├── sql_queries.sql            # Part A — 15 SQL queries + EXPLAIN analysis
├── projects.sql               # Part B — projects table DDL + 3-table JOINs
├── interview_answers.sql      # Part C — Q1/Q2/Q3 answered in SQL
├── sql_pandas_comparison.py   # Part A — Pandas equivalents for all 15 queries
├── ai_augmented_task.md       # Part D — AI questions, verified runs, evaluation
└── README.md
```

---

## ▶️ How to Run

### SQL (PostgreSQL)

```bash
# Start postgres and connect
psql -U postgres -d your_database

# Run in order:
\i sql_queries.sql       -- creates tables, inserts data, runs all 15 queries
\i projects.sql          -- creates projects table, runs 3-table JOINs
\i interview_answers.sql -- runs Part C queries
```

### Python (Pandas equivalents)

```bash
pip install pandas numpy
python sql_pandas_comparison.py
```

---

## 📝 Part A — `sql_queries.sql` + `sql_pandas_comparison.py` (40%)

### Schema

**`departments`** — `dept_id`, `dept_name`, `location`, `budget` — 5 rows

**`employees`** — `emp_id`, `first_name`, `last_name`, `dept_id`, `salary`, `hire_date`, `job_title`, `manager_id` — 20 rows

### 15 Queries

| # | Topic | SQL Feature |
|---|---|---|
| Q1 | Engineering employees earning > 75,000 | `WHERE` with multiple conditions |
| Q2 | Top 5 highest-paid employees | `ORDER BY … DESC LIMIT` |
| Q3 | Company-wide salary stats | `COUNT`, `AVG`, `MAX`, `MIN`, `SUM` |
| Q4 | Headcount and avg salary per department | `GROUP BY` |
| Q5 | Departments with avg salary > 75,000 | `HAVING` |
| Q6 | Employees with department info | `INNER JOIN` |
| Q7 | All departments including empty | `LEFT JOIN` |
| Q8 | Employees with their manager's name | Self `JOIN` |
| Q9 | Employees hired in 2020 | `BETWEEN` with dates |
| Q10 | Job titles containing 'Engineer' | `ILIKE` pattern match |
| Q11 | Top-level employees (no manager) | `IS NULL` |
| Q12 | Unique job titles | `DISTINCT` |
| Q13 | All department pairs | `CROSS JOIN` |
| Q14 | Departments with total payroll > 400,000 | `GROUP BY` + `HAVING` + computed column |
| Q15 | Salary as % of department budget | Multi-table `JOIN` + arithmetic |

### EXPLAIN Insights

| Query | Key Insight |
|---|---|
| **Q2** (Top 5 by salary) | Hash Join + Sort + Limit. An index on `employees.salary` would enable Index Scan, skipping the O(n log n) sort entirely. |
| **Q5** (HAVING avg > 75000) | HashAggregate runs before the HAVING filter — confirms HAVING cannot use an index. Pre-filtering with WHERE (when valid) is always faster. |
| **Q6** (INNER JOIN) | PostgreSQL picks a Hash Join — builds hash table on the smaller `departments` table, probes with `employees`. O(n) average vs O(n·m) Nested Loop. |

### SQL vs Pandas — Key Differences

| SQL Concept | Pandas Equivalent |
|---|---|
| `WHERE` | `.query()` or boolean mask `.loc[df.col > val]` |
| `GROUP BY` | `.groupby().agg()` |
| `HAVING` | `.groupby().agg().query()` (filter after aggregation) |
| `INNER JOIN` | `.merge(df2, on='key', how='inner')` |
| `LEFT JOIN` | `.merge(df2, on='key', how='left')` |
| `ORDER BY … LIMIT` | `.sort_values().head()` |
| `DISTINCT` | `.drop_duplicates()` or `.unique()` |
| `IS NULL` | `.isna()` |
| `ILIKE '%x%'` | `.str.contains('x', case=False, na=False)` |
| `CROSS JOIN` | `pd.merge(df1.assign(k=1), df2.assign(k=1), on='k')` |

---

## 📝 Part B — `projects.sql` (30%)

### Projects Table

```sql
CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    lead_emp_id  INT REFERENCES employees(emp_id),
    budget       NUMERIC(12,2),
    start_date   DATE,
    end_date     DATE
);
```

5 projects inserted: AI Recommendation Engine, Customer Churn Predictor, ERP System Migration, Brand Campaign Analytics, Fraud Detection Pipeline.

### Queries

**B1 — 3-table JOIN:** `projects ⟶ employees ⟶ departments` showing lead employee name, department budget, and project budget side-by-side.

**B2 — Over-budget departments:** departments where the total budget of all projects led by their employees exceeds the department's own budget — using `GROUP BY` + `HAVING SUM(p.budget) > d.budget`.

---

## 📝 Part C — `interview_answers.sql` (20%)

### Q1 — SQL Logical Execution Order

```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
```

Key implication: aliases defined in `SELECT` (step 6) are **not visible** to `WHERE` (step 3), `GROUP BY` (step 4), or `HAVING` (step 5). Only `ORDER BY` can use them (PostgreSQL extension).

### Q2 — Salary vs dept average, no subqueries

Uses a self-join on `employees` twice — once to compute the per-department average and once for the company-wide average — grouped with `HAVING` to filter employees above the company mean.

### Q3 — Debug: aggregate in WHERE

**Bug:** `WHERE AVG(salary) > 70000` — aggregate functions are illegal in `WHERE` because WHERE runs before GROUP BY. PostgreSQL raises `ERROR: aggregate functions are not allowed in WHERE`.

**Fix:** Replace `WHERE` with `HAVING` — it runs after GROUP BY and can filter on aggregate results.

---

## 📝 Part D — `ai_augmented_task.md` (10%)

See [`ai_augmented_task.md`](./ai_augmented_task.md) for the full prompt, raw AI output, verified query results, and evaluation.

**Summary of evaluation:**

| Q | Topic | Verdict |
|---|---|---|
| Q1 | JOINs | ✅ Correct, but example too simple — improved |
| Q2 | NULL handling | ✅ Well-calibrated, runs correctly |
| Q3 | Performance | ✅ Solid answer, verified with EXPLAIN |
| Q4 | Aggregation | ❌ Uses window functions — too hard for "medium". Rewritten without. |
| Q5 | Data integrity | ❌ DELETE/TRUNCATE/DROP is too basic. Replaced with a real DE scenario. |

---

## 🧠 Key Concepts Covered

- **DDL** — `CREATE TABLE`, `REFERENCES`, `SERIAL`, `CASCADE`
- **DML** — `INSERT INTO`, `SELECT`, `WHERE`, `ORDER BY`, `LIMIT`
- **Aggregates** — `COUNT`, `SUM`, `AVG`, `MAX`, `MIN`
- **Grouping** — `GROUP BY`, `HAVING` (vs WHERE)
- **JOINs** — `INNER`, `LEFT`, `SELF`, `CROSS`
- **NULL handling** — `IS NULL`, `IS NOT NULL`, `COALESCE`
- **Pattern matching** — `LIKE`, `ILIKE`
- **Aliases** — column and table aliases, interaction with execution order
- **EXPLAIN** — reading query plans, Hash Join vs Nested Loop vs Index Scan
- **SQL ↔ Pandas** — equivalent operations for all 15 query types

---

*Assignment completed · Day 14 · AM Session*
