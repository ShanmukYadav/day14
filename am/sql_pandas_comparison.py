"""
sql_pandas_comparison.py
Part A: SQL vs Pandas Equivalents for all 15 queries
Day 14 · AM Take-Home Assignment
Week 3 · PG Diploma · AI-ML & Agentic AI · IIT Gandhinagar

Each section shows:
  - The SQL query (as a comment)
  - The equivalent Pandas operation
  - Both should produce the same result
"""

import pandas as pd
import numpy as np

# ─────────────────────────────────────────────────────────────
# Build the same in-memory dataset
# ─────────────────────────────────────────────────────────────

departments = pd.DataFrame({
    "dept_id":   [1, 2, 3, 4, 5],
    "dept_name": ["Engineering", "Data Science", "Marketing", "HR", "Finance"],
    "location":  ["Bengaluru", "Hyderabad", "Mumbai", "Delhi", "Chennai"],
    "budget":    [5000000, 3500000, 2000000, 1500000, 2500000],
})

employees = pd.DataFrame({
    "emp_id":     list(range(1, 21)),
    "first_name": ["Arjun","Priya","Ravi","Sneha","Vikram","Ananya","Deepak",
                   "Kavitha","Rohan","Lakshmi","Aditya","Meena","Suresh",
                   "Nalini","Kartik","Pooja","Manish","Divya","Sanjay","Rina"],
    "last_name":  ["Sharma","Patel","Kumar","Reddy","Singh","Iyer","Menon",
                   "Nair","Gupta","Venkat","Joshi","Pillai","Bhat",
                   "Das","Rao","Shah","Tiwari","Krishnan","Mehta","Chopra"],
    "dept_id":    [1,2,1,3,2,4,5,1,2,3,1,4,5,3,2,1,5,2,1,4],
    "salary":     [95000,88000,72000,65000,91000,55000,78000,82000,69000,
                   61000,105000,52000,83000,58000,76000,67000,71000,94000,88000,60000],
    "hire_date":  pd.to_datetime([
                   "2019-03-15","2020-07-01","2021-01-10","2020-11-20","2018-06-05",
                   "2022-03-01","2019-09-14","2020-02-28","2021-08-15","2022-05-10",
                   "2017-11-30","2023-01-20","2018-07-22","2021-12-05","2020-04-18",
                   "2022-09-01","2019-03-30","2018-12-10","2020-06-15","2021-04-25"]),
    "job_title":  ["Senior Engineer","Data Scientist","Engineer","Marketing Manager",
                   "ML Engineer","HR Specialist","Financial Analyst","Senior Engineer",
                   "Data Analyst","Marketing Analyst","Lead Engineer","HR Coordinator",
                   "Senior Analyst","Brand Specialist","Data Engineer","Engineer",
                   "Analyst","ML Engineer","Senior Engineer","HR Specialist"],
    "manager_id": [None,None,1,None,2,None,None,1,2,4,None,6,7,4,2,1,7,2,11,6],
})

# merge helper
emp_dept = employees.merge(departments, on="dept_id")


# ════════════════════════════════════════════════════════════
# Q1 — Engineering employees earning > 75000
# SQL:
#   SELECT e.emp_id, first_name||' '||last_name AS full_name, salary, job_title
#   FROM employees e JOIN departments d ON e.dept_id=d.dept_id
#   WHERE d.dept_name='Engineering' AND e.salary > 75000
#   ORDER BY salary DESC;
# ════════════════════════════════════════════════════════════
q1 = (
    emp_dept
    .query("dept_name == 'Engineering' and salary > 75000")
    [["emp_id","first_name","last_name","salary","job_title"]]
    .assign(full_name=lambda df: df.first_name + " " + df.last_name)
    .sort_values("salary", ascending=False)
    [["emp_id","full_name","salary","job_title"]]
    .reset_index(drop=True)
)
print("Q1 — Engineering employees earning > 75000"); print(q1, "\n")


# ════════════════════════════════════════════════════════════
# Q2 — Top 5 highest-paid employees
# SQL:
#   SELECT emp_id, full_name, dept_name, salary
#   FROM employees JOIN departments ... ORDER BY salary DESC LIMIT 5;
# ════════════════════════════════════════════════════════════
q2 = (
    emp_dept
    .assign(full_name=lambda df: df.first_name + " " + df.last_name)
    .sort_values("salary", ascending=False)
    .head(5)
    [["emp_id","full_name","dept_name","salary"]]
    .reset_index(drop=True)
)
print("Q2 — Top 5 highest-paid"); print(q2, "\n")


# ════════════════════════════════════════════════════════════
# Q3 — Company-wide salary stats
# SQL: SELECT COUNT(*), AVG(salary), MAX(salary), MIN(salary), SUM(salary)
# ════════════════════════════════════════════════════════════
q3 = employees["salary"].agg(
    total_employees="count",
    avg_salary="mean",
    max_salary="max",
    min_salary="min",
    total_payroll="sum",
).rename({"avg_salary": "avg_salary"}).to_frame().T.round(2)
print("Q3 — Company-wide salary stats"); print(q3, "\n")


# ════════════════════════════════════════════════════════════
# Q4 — Headcount and avg salary per department
# SQL: SELECT dept_name, COUNT(*), AVG(salary), SUM(salary)
#      FROM ... GROUP BY dept_name ORDER BY avg_salary DESC;
# ════════════════════════════════════════════════════════════
q4 = (
    emp_dept
    .groupby("dept_name")["salary"]
    .agg(headcount="count", avg_salary="mean", total_salary="sum")
    .round(2)
    .sort_values("avg_salary", ascending=False)
    .reset_index()
)
print("Q4 — Headcount & avg salary per dept"); print(q4, "\n")


# ════════════════════════════════════════════════════════════
# Q5 — Departments with avg salary > 75000  (HAVING equivalent)
# SQL: ... GROUP BY dept_name HAVING AVG(salary) > 75000;
# ════════════════════════════════════════════════════════════
q5 = (
    emp_dept
    .groupby("dept_name")["salary"]
    .agg(avg_salary="mean", headcount="count")
    .round(2)
    .query("avg_salary > 75000")
    .sort_values("avg_salary", ascending=False)
    .reset_index()
)
print("Q5 — Depts with avg salary > 75000"); print(q5, "\n")


# ════════════════════════════════════════════════════════════
# Q6 — INNER JOIN: employees with dept name & location
# SQL: SELECT emp_id, full_name, dept_name, location, salary FROM ... INNER JOIN ...
# ════════════════════════════════════════════════════════════
q6 = (
    emp_dept
    .assign(full_name=lambda df: df.first_name + " " + df.last_name)
    [["emp_id","full_name","dept_name","location","salary"]]
    .sort_values(["dept_name","salary"], ascending=[True,False])
    .reset_index(drop=True)
)
print("Q6 — INNER JOIN employees + depts"); print(q6.head(5), "...\n")


# ════════════════════════════════════════════════════════════
# Q7 — LEFT JOIN: all depts including those with no employees
# SQL: SELECT dept_id, dept_name, location, COUNT(emp_id) FROM ... LEFT JOIN ...
# ════════════════════════════════════════════════════════════
q7 = (
    departments
    .merge(employees[["dept_id","emp_id"]], on="dept_id", how="left")
    .groupby(["dept_id","dept_name","location"])["emp_id"]
    .count()
    .rename("employee_count")
    .reset_index()
    .sort_values("employee_count", ascending=False)
)
print("Q7 — LEFT JOIN dept headcount"); print(q7, "\n")


# ════════════════════════════════════════════════════════════
# Q8 — Self JOIN: employees with their manager
# SQL: SELECT e.*, m.first_name||' '||m.last_name AS manager FROM employees e
#      LEFT JOIN employees m ON e.manager_id = m.emp_id;
# ════════════════════════════════════════════════════════════
mgr = employees[["emp_id","first_name","last_name","job_title"]].rename(
    columns={"emp_id":"manager_id","first_name":"mgr_first","last_name":"mgr_last","job_title":"manager_title"}
)
q8 = (
    employees
    .merge(mgr, on="manager_id", how="left")
    .assign(
        employee=lambda df: df.first_name + " " + df.last_name,
        manager=lambda df: (df.mgr_first + " " + df.mgr_last).where(df.mgr_first.notna())
    )
    [["emp_id","employee","job_title","manager","manager_title"]]
    .sort_values("manager", na_position="last")
    .reset_index(drop=True)
)
print("Q8 — Self JOIN employees + managers"); print(q8.head(8), "\n")


# ════════════════════════════════════════════════════════════
# Q9 — Employees hired in 2020
# SQL: WHERE hire_date BETWEEN '2020-01-01' AND '2020-12-31';
# ════════════════════════════════════════════════════════════
q9 = (
    emp_dept
    .assign(full_name=lambda df: df.first_name + " " + df.last_name)
    .loc[lambda df: df.hire_date.dt.year == 2020]
    [["full_name","hire_date","job_title","dept_name"]]
    .sort_values("hire_date")
    .reset_index(drop=True)
)
print("Q9 — Employees hired in 2020"); print(q9, "\n")


# ════════════════════════════════════════════════════════════
# Q10 — Job titles containing 'Engineer' (ILIKE)
# SQL: WHERE job_title ILIKE '%engineer%'
# ════════════════════════════════════════════════════════════
q10 = (
    employees
    .assign(full_name=lambda df: df.first_name + " " + df.last_name)
    .loc[lambda df: df.job_title.str.contains("engineer", case=False, na=False)]
    [["full_name","job_title","salary"]]
    .sort_values("salary", ascending=False)
    .reset_index(drop=True)
)
print("Q10 — Engineers"); print(q10, "\n")


# ════════════════════════════════════════════════════════════
# Q11 — IS NULL: top-level employees (no manager)
# SQL: WHERE manager_id IS NULL
# ════════════════════════════════════════════════════════════
q11 = (
    emp_dept
    .assign(full_name=lambda df: df.first_name + " " + df.last_name)
    .loc[lambda df: df.manager_id.isna()]
    [["emp_id","full_name","job_title","dept_name"]]
    .sort_values("emp_id")
    .reset_index(drop=True)
)
print("Q11 — Top-level employees (manager_id IS NULL)"); print(q11, "\n")


# ════════════════════════════════════════════════════════════
# Q12 — DISTINCT job titles
# SQL: SELECT DISTINCT job_title FROM employees ORDER BY job_title;
# ════════════════════════════════════════════════════════════
q12 = (
    pd.Series(employees["job_title"].unique(), name="job_title")
    .sort_values()
    .reset_index(drop=True)
)
print("Q12 — Distinct job titles"); print(q12, "\n")


# ════════════════════════════════════════════════════════════
# Q13 — CROSS JOIN pairs of departments
# SQL: SELECT d1.dept_name, d2.dept_name FROM departments d1
#      CROSS JOIN departments d2 WHERE d1.dept_id < d2.dept_id LIMIT 10;
# ════════════════════════════════════════════════════════════
dept_names = departments["dept_name"].tolist()
q13 = pd.DataFrame(
    [(a, b) for i, a in enumerate(dept_names)
              for b in dept_names[i+1:]],
    columns=["dept_a","dept_b"]
).head(10)
print("Q13 — CROSS JOIN dept pairs"); print(q13, "\n")


# ════════════════════════════════════════════════════════════
# Q14 — Depts with total payroll > 400,000 + payroll/budget %
# SQL: GROUP BY dept_name HAVING SUM(salary) > 400000
# ════════════════════════════════════════════════════════════
q14 = (
    emp_dept
    .groupby(["dept_name","budget"])
    .agg(headcount=("emp_id","count"), total_payroll=("salary","sum"))
    .reset_index()
    .query("total_payroll > 400000")
    .assign(payroll_to_budget_pct=lambda df: (df.total_payroll / df.budget * 100).round(2))
    .sort_values("total_payroll", ascending=False)
    .reset_index(drop=True)
)
print("Q14 — Depts total payroll > 400000"); print(q14, "\n")


# ════════════════════════════════════════════════════════════
# Q15 — Employee salary as % of dept budget
# SQL: SELECT full_name, dept_name, salary, budget, salary/budget*100 pct
# ════════════════════════════════════════════════════════════
q15 = (
    emp_dept
    .assign(
        full_name=lambda df: df.first_name + " " + df.last_name,
        salary_pct_of_budget=lambda df: (df.salary / df.budget * 100).round(4)
    )
    [["full_name","dept_name","salary","budget","salary_pct_of_budget"]]
    .sort_values("salary_pct_of_budget", ascending=False)
    .reset_index(drop=True)
)
print("Q15 — Salary as % of dept budget"); print(q15.head(5), "\n")

print("=" * 60)
print("✅ All 15 SQL ↔ Pandas equivalents complete!")
