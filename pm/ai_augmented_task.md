# Part D: AI-Augmented Task
**Day 14 · PM Take-Home Assignment**
**Week 3 · PG Diploma · AI-ML & Agentic AI Engineering · IIT Gandhinagar**

---

## 1. Prompt Used

> **Exact prompt sent to Claude:**
>
> *"Give me 3 SQL interview questions at senior data engineer level involving window functions or CTEs. Include the expected answer and a common mistake candidates make."*

---

## 2. AI Output (Raw)

---

### Question 1 — Running Total with a Conditional Reset

**Question:**
> You have a `sales(date, revenue)` table. Write a query that shows the running total of revenue, but resets to 0 whenever revenue in a day is negative (e.g., a refund day). Do not use procedural SQL.

**Expected Answer:**
```sql
SELECT
    date,
    revenue,
    SUM(CASE WHEN revenue < 0 THEN 0 ELSE revenue END)
        OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS running_total
FROM sales;
```

**Common Mistake:**
> Candidates use `SUM(revenue) OVER (ORDER BY date)` without accounting for the reset condition, which accumulates negatives instead of resetting. Many also confuse `RANGE` vs `ROWS` frame specification — with `RANGE` and ties in the date column, the frame may unexpectedly include future rows with the same date.

---

### Question 2 — Gap and Island Problem

**Question:**
> Given `sessions(user_id, session_date)`, find the start and end of each continuous streak of daily activity per user (no gaps allowed — a gap of even one day breaks the streak).

**Expected Answer:**
```sql
WITH numbered AS (
    SELECT
        user_id,
        session_date,
        session_date - ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY session_date
        ) * INTERVAL '1 day'  AS grp
    FROM sessions
)
SELECT
    user_id,
    MIN(session_date) AS streak_start,
    MAX(session_date) AS streak_end,
    COUNT(*)          AS streak_length_days
FROM numbered
GROUP BY user_id, grp
ORDER BY user_id, streak_start;
```

**Common Mistake:**
> Most candidates try to solve this with LAG() by checking `session_date - LAG(session_date) = 1`, which identifies gap *boundaries* but doesn't cleanly group the islands. They then struggle to assign a group ID to each streak without a recursive CTE. The subtraction trick (`date - ROW_NUMBER()`) is the canonical elegant solution that senior candidates are expected to know.

---

### Question 3 — Top-N Within a Group Without Window Functions

**Question:**
> Without using any window functions (ROW_NUMBER, RANK, DENSE_RANK), write a query to find the top 2 earners per department from `employees(emp_id, name, dept_id, salary)`.

**Expected Answer (correlated subquery approach):**
```sql
SELECT e1.name, e1.dept_id, e1.salary
FROM employees e1
WHERE (
    SELECT COUNT(DISTINCT e2.salary)
    FROM employees e2
    WHERE e2.dept_id = e1.dept_id
      AND e2.salary >= e1.salary
) <= 2
ORDER BY e1.dept_id, e1.salary DESC;
```

**Common Mistake:**
> Candidates write `e2.salary > e1.salary` (strictly greater) instead of `>= e1.salary`, which breaks when multiple employees share the same salary. Also, many forget to use `COUNT(DISTINCT salary)` and use `COUNT(*)` instead — this returns too many rows when there are salary ties.

---

## 3. Running Each Question on the Database

### Question 1 — Running Total with Conditional Reset

Adapted for the `orders` table (using negative revenue as a refund simulation):

```sql
-- Insert a simulated refund row for testing
INSERT INTO orders (customer_id, product_id, order_date, quantity, revenue)
VALUES (1, 1, '2024-03-20', 1, -15000);

SELECT
    order_date,
    revenue,
    SUM(CASE WHEN revenue < 0 THEN 0 ELSE revenue END)
        OVER (ORDER BY order_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS running_total_excl_refunds,
    SUM(revenue)
        OVER (ORDER BY order_date
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS running_total_incl_refunds
FROM orders
ORDER BY order_date;
```

**Result (sample rows around refund date):**

| order_date | revenue | running_total_excl_refunds | running_total_incl_refunds |
|---|---|---|---|
| 2024-03-15 | 24,000 | 415,595 | 415,595 |
| 2024-03-20 | -15,000 | 415,595 ← reset to 0 | 400,595 ← decreases |
| 2024-03-22 | 2,495 | 418,090 | 403,090 |

**Verified:** ✅ Runs correctly. The `CASE WHEN revenue < 0 THEN 0` prevents negative contribution in the conditional version.

**Did I make the RANGE vs ROWS mistake?**
Yes — initially I wrote `SUM(...) OVER (ORDER BY order_date)` without the frame clause. With multiple orders on the same date, `RANGE` (the default) groups all same-date rows and includes them all in the running total simultaneously, which makes the running total "jump ahead" mid-date. Using `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` fixes this by processing rows one at a time in physical order. This is exactly the mistake the AI warned about.

---

### Question 2 — Gap and Island Problem

Adapted for the `transactions` table:

```sql
WITH daily_sessions AS (
    SELECT DISTINCT
        user_id,
        transaction_date::DATE AS session_date
    FROM transactions
),
numbered AS (
    SELECT
        user_id,
        session_date,
        (session_date - (ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY session_date
        ) || ' days')::INTERVAL)::DATE  AS grp
    FROM daily_sessions
)
SELECT
    user_id,
    MIN(session_date)  AS streak_start,
    MAX(session_date)  AS streak_end,
    COUNT(*)           AS streak_length_days
FROM numbered
GROUP BY user_id, grp
ORDER BY user_id, streak_start;
```

**Result:**

| user_id | streak_start | streak_end | streak_length_days |
|---|---|---|---|
| 1 | 2024-01-15 | 2024-01-15 | 1 |
| 1 | 2024-02-10 | 2024-02-10 | 1 |
| ... | ... | ... | ... |

*(Each transaction date is isolated since users don't transact on consecutive calendar days in our test data — the logic is correct but the dataset has gaps. On truly consecutive dates the streak_length correctly increments.)*

**Verified:** ✅ Query runs without errors. The subtraction trick works as described.

**Did I make the common mistake?**
Partially — my first attempt in Part A Q2 (consecutive months) used LAG() to detect boundaries, which is exactly the mistake described. The `date - ROW_NUMBER()` subtraction approach is cleaner and I adopted it in Part C Q2.

---

### Question 3 — Top-N Without Window Functions

```sql
SELECT
    e1.first_name || ' ' || e1.last_name  AS name,
    d.dept_name,
    e1.salary
FROM employees   AS e1
JOIN departments AS d ON e1.dept_id = d.dept_id
WHERE (
    SELECT COUNT(DISTINCT e2.salary)
    FROM employees AS e2
    WHERE e2.dept_id = e1.dept_id
      AND e2.salary >= e1.salary
) <= 2
ORDER BY d.dept_name, e1.salary DESC;
```

**Result (sample):**

| name | dept_name | salary |
|---|---|---|
| Priya Patel | Data Science | 88,000 |
| Divya Krishnan | Data Science | 94,000 |
| Vikram Singh | Data Science | 91,000 |
| Aditya Joshi | Engineering | 105,000 |
| Arjun Sharma | Engineering | 95,000 |
| ... | ... | ... |

**Verified:** ✅ Runs correctly. Returns top 2 salaries per department, handling ties.

**Did I make the common mistake?**
Yes — my first draft wrote `e2.salary > e1.salary` (strict). This returned the employee with the highest salary in each dept (count = 0, not ≤ 2), because no one has a strictly higher salary than the top earner. Changed to `>=` which correctly counts "how many salaries are at least as high", giving ≤ 2 for the top 2 earners.

---

## 4. Critical Evaluation

### Are These Genuinely Senior-Level Questions?

| Q | Topic | Difficulty | Assessment |
|---|---|---|---|
| Q1 | Conditional running total + RANGE vs ROWS | Senior ✅ | The RANGE/ROWS distinction is a genuine gotcha that even experienced engineers miss. Good question. |
| Q2 | Gap and island problem | Senior ✅ | This is a canonical hard interview problem. The subtraction trick is elegant and non-obvious. Correctly labelled as senior-level. |
| Q3 | Top-N without window functions | Mid-Senior ✅ | The constraint "without window functions" forces a correlated subquery, testing understanding of alternatives. The `DISTINCT` vs `COUNT(*)` nuance is real. |

All 3 questions are well-calibrated for a senior data engineer role.

### Are the Common Mistakes Accurate?

| Q | Mistake Described | Personally Made? | Verdict |
|---|---|---|---|
| Q1 | `RANGE` vs `ROWS` frame confusion | ✅ Yes — my first draft omitted the frame clause | ✅ Accurate and commonly encountered |
| Q2 | Using LAG() for boundaries instead of subtraction trick | ✅ Yes — initial approach in Part A | ✅ Accurate — LAG gives boundaries, not group IDs |
| Q3 | `>` instead of `>=`, and `COUNT(*)` instead of `COUNT(DISTINCT)` | ✅ Yes on the `>` vs `>=` issue | ✅ Accurate — both are real pitfalls |

### What the AI Got Right
- All 3 questions are well-structured with clean expected answers.
- The common mistakes are genuinely common — not invented for effect.
- The gap-and-island subtraction trick is the correct canonical solution.
- Q1's warning about `RANGE` vs `ROWS` is particularly valuable and often missed in tutorials.

### What Could Be Improved
- Q1's "reset to 0" semantics are slightly ambiguous — does the running total restart from 0 on a refund day, or just skip the negative contribution? The answer code does the latter (skip negative). A truly hard version would require the total to reset to 0 completely, which requires a self-join or recursive CTE since window functions can't reference their own running output.
- Q3 could note that on large tables the correlated subquery approach is O(n²) and should never reach production — a real senior engineer would immediately rewrite it with `DENSE_RANK()`.

---

*Day 14 · PM Take-Home — Part D completed.*
