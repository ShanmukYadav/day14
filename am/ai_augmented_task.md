# Part D: AI-Augmented Task
**Day 14 · AM Take-Home Assignment**
**Week 3 · PG Diploma · AI-ML & Agentic AI · IIT Gandhinagar**

---

## 1. Prompt Used

> **Exact prompt sent to Claude:**
>
> *"Generate 5 medium-difficulty SQL interview questions for a data engineer role, with answers. Include one about JOINs, one about NULL handling, and one about performance."*

---

## 2. AI Output (Raw)

Below are the 5 questions returned by the AI, pasted verbatim:

---

**Q1 (JOINs) — Explain the difference between LEFT JOIN and INNER JOIN with an example.**

> Answer: An INNER JOIN returns only rows where the join condition matches in both tables. A LEFT JOIN returns all rows from the left table, with NULL for columns from the right table when there's no match.
>
> ```sql
> SELECT e.name, d.dept_name
> FROM employees e
> LEFT JOIN departments d ON e.dept_id = d.dept_id;
> ```

---

**Q2 (NULL handling) — How do you find all employees whose manager_id is NULL, and how does COALESCE help?**

> Answer: Use `WHERE manager_id IS NULL` — never `WHERE manager_id = NULL` (NULL is not equal to anything, including itself). COALESCE returns the first non-NULL value in a list.
>
> ```sql
> SELECT name, COALESCE(manager_id::text, 'No Manager') AS manager
> FROM employees
> WHERE manager_id IS NULL;
> ```

---

**Q3 (Performance) — How would you optimize a slow query that does a full table scan on a 10M-row table?**

> Answer: Add an index on the filtered/joined column. Use EXPLAIN ANALYZE to identify the bottleneck. Avoid SELECT *, use column pruning. Avoid functions on indexed columns in WHERE (e.g., `WHERE LOWER(name) = 'alice'` disables the index — use a functional index instead).

---

**Q4 (Aggregation) — Write a query to find the department with the second-highest average salary.**

> Answer:
>
> ```sql
> SELECT dept_name, avg_salary
> FROM (
>     SELECT d.dept_name, AVG(e.salary) AS avg_salary,
>            RANK() OVER (ORDER BY AVG(e.salary) DESC) AS rnk
>     FROM employees e
>     JOIN departments d ON e.dept_id = d.dept_id
>     GROUP BY d.dept_name
> ) ranked
> WHERE rnk = 2;
> ```

---

**Q5 (Data integrity) — What is the difference between DELETE, TRUNCATE, and DROP?**

> Answer:
> - `DELETE` removes rows matching a WHERE clause, logs each deletion, can be rolled back.
> - `TRUNCATE` removes all rows instantly, minimal logging, faster but cannot use WHERE.
> - `DROP` removes the entire table including structure, irreversible without backup.

---

## 3. Running Each Query on the Database

All queries were run against the `employees` and `departments` tables defined in `sql_queries.sql`.

### Q1 — LEFT JOIN vs INNER JOIN

```sql
-- INNER JOIN (only matched rows)
SELECT e.first_name || ' ' || e.last_name AS name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
-- Result: 20 rows (all employees have a dept_id in this dataset)

-- LEFT JOIN (all employees, NULLs where no dept match)
SELECT e.first_name || ' ' || e.last_name AS name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Result: also 20 rows here (no unmatched employees), but would differ
-- if some employees had NULL dept_id or a dept_id not in departments.
```

**Verified:** ✅ Both queries run correctly. Output matches expectation.

---

### Q2 — NULL handling with COALESCE

```sql
SELECT
    first_name || ' ' || last_name            AS name,
    COALESCE(manager_id::TEXT, 'No Manager')  AS manager
FROM employees
WHERE manager_id IS NULL;
```

**Result:**

| name | manager |
|---|---|
| Arjun Sharma | No Manager |
| Priya Patel | No Manager |
| Sneha Reddy | No Manager |
| Ananya Iyer | No Manager |
| Deepak Menon | No Manager |
| Aditya Joshi | No Manager |

**Verified:** ✅ Runs correctly. COALESCE correctly substitutes 'No Manager'.

---

### Q3 — Performance optimisation (EXPLAIN)

```sql
EXPLAIN SELECT * FROM employees WHERE dept_id = 2;
```

**Output (abbreviated):**
```
Seq Scan on employees  (cost=0.00..1.25 rows=7 width=...)
  Filter: (dept_id = 2)
```

**After adding index:**
```sql
CREATE INDEX idx_employees_dept_id ON employees(dept_id);
EXPLAIN SELECT * FROM employees WHERE dept_id = 2;
-- Now shows: Index Scan using idx_employees_dept_id
```

**Verified:** ✅ EXPLAIN confirms the optimisation. Index changes Seq Scan to Index Scan.

---

### Q4 — Second-highest avg salary department

```sql
SELECT dept_name, ROUND(avg_salary, 2) AS avg_salary
FROM (
    SELECT
        d.dept_name,
        AVG(e.salary) AS avg_salary,
        RANK() OVER (ORDER BY AVG(e.salary) DESC) AS rnk
    FROM employees   AS e
    JOIN departments AS d ON e.dept_id = d.dept_id
    GROUP BY d.dept_name
) ranked
WHERE rnk = 2;
```

**Result:**

| dept_name | avg_salary |
|---|---|
| Data Science | 83,600.00 |

**Verified:** ✅ Runs correctly. Note: this uses a window function (`RANK() OVER`) — technically an **advanced SQL** concept. For a "medium difficulty" question this leans toward hard. See evaluation below.

---

### Q5 — DELETE vs TRUNCATE vs DROP

This is conceptual. Verified with a demo:

```sql
-- Safe demo: create a temp table
CREATE TEMP TABLE demo (id INT, val TEXT);
INSERT INTO demo VALUES (1,'a'),(2,'b'),(3,'c');

DELETE FROM demo WHERE id = 1;    -- removes 1 row, rollback-able
SELECT * FROM demo;               -- 2 rows remain

TRUNCATE demo;                    -- removes all rows instantly
SELECT * FROM demo;               -- 0 rows

DROP TABLE demo;                  -- table no longer exists
```

**Verified:** ✅ All three commands behave as described.

---

## 4. Critical Evaluation

### Difficulty Assessment

| # | Topic | Actual Difficulty | Assessment |
|---|---|---|---|
| Q1 | JOINs | Easy–Medium | The concept is correct but the example is trivial. A better medium question would ask: *"Write a query that finds employees with no matching department, using a LEFT JOIN and IS NULL check."* |
| Q2 | NULL handling | Medium | ✅ Good question. Correctly highlights `= NULL` vs `IS NULL`. |
| Q3 | Performance | Medium | ✅ Answer is solid. Could be improved by mentioning partial indexes and the cost of over-indexing. |
| Q4 | Aggregation | Hard | ❌ Uses `RANK() OVER (...)` — a **window function** — which is advanced SQL, not medium difficulty. A true medium version would use a subquery with `LIMIT 1 OFFSET 1` or nested `MAX`. |
| Q5 | Data integrity | Easy | ❌ DELETE/TRUNCATE/DROP is a standard definition question, suitable for a junior role, not a data engineer interview. |

### What the AI Got Right
- Coverage is good: JOIN, NULL, performance, aggregation, integrity — all useful topics.
- Q2 and Q3 are well-calibrated and practically useful.
- Code in Q1 and Q4 is syntactically correct and runs without modification.

### What Needs Improvement

**Q4 improvement** — medium-difficulty version without window functions:
```sql
-- Find 2nd highest avg salary dept WITHOUT window functions
SELECT dept_name, ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING AVG(e.salary) < (
    SELECT MAX(avg_sal)
    FROM (
        SELECT AVG(salary) AS avg_sal
        FROM employees
        GROUP BY dept_id
    ) sub
)
ORDER BY avg_salary DESC
LIMIT 1;
```

**Q5 replacement** — genuinely medium difficulty:
> *"You have a 50M-row orders table with columns `order_id`, `customer_id`, `status`, `created_at`. Write a query to find customers who placed more than 3 orders in the last 30 days with status = 'completed', along with their order count. Explain your indexing strategy."*

### Are Answers Complete?
- Q3's performance answer is good but doesn't mention `EXPLAIN ANALYZE` vs `EXPLAIN`, or the impact of `VACUUM` and statistics freshness.
- Q4's answer uses window functions without explaining them — a candidate who doesn't know window functions couldn't learn from the answer alone.

### Overall Verdict
3 out of 5 questions are genuinely useful for a data engineer interview. Two were miscalibrated (one too hard, one too easy). After correction, the set is solid.

---

*Day 14 · AM Take-Home — Part D completed.*
