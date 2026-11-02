CREATE DATABASE Banking_System;
USE Banking_System;

CREATE TABLE branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    ifsc_code VARCHAR(20) UNIQUE,
    opened_date DATE
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender VARCHAR(20),
    dob DATE,
    occupation VARCHAR(50),
    email VARCHAR(150),
    phone VARCHAR(20) NULL ,
    city VARCHAR(50),
    state VARCHAR(50),
    join_date DATE
);

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    branch_id INT,
    account_type VARCHAR(50),
    balance DECIMAL(15,2) DEFAULT 0.00,
    open_date DATE,
    status VARCHAR(30),
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);

CREATE TABLE beneficiaries (
    beneficiary_id INT PRIMARY KEY,
    customer_id INT,
    beneficiary_name VARCHAR(100),
    beneficiary_account_number VARCHAR(50),
    beneficiary_bank VARCHAR(100),
    added_date DATE,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_date DATE,
    transaction_type VARCHAR(50),
    amount DECIMAL(15,2),
    mode VARCHAR(50),
    status VARCHAR(30),
    description VARCHAR(255),
    FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);

CREATE TABLE loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    branch_id INT,
    loan_type VARCHAR(50),
    loan_amount DECIMAL(15,2),
    interest_rate DECIMAL(5,2),
    tenure_months INT,
    issue_date DATE,
    status VARCHAR(30),
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
);

CREATE TABLE loan_payments (
    payment_id INT PRIMARY KEY,
    loan_id INT,
    payment_date DATE,
    amount_paid DECIMAL(15,2),
    payment_mode VARCHAR(50),
    status VARCHAR(30),
    FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
);

CREATE TABLE cards (
    card_id INT PRIMARY KEY,
    customer_id INT,
    account_id INT,
    card_type VARCHAR(50),
    issue_date DATE,
    expiry_date DATE,
    credit_limit DECIMAL(15,2) DEFAULT 0.00,
    status VARCHAR(30),
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    branch_id INT NULL,
    employee_name VARCHAR(100),
    designation VARCHAR(50),
    hire_date DATE,
    salary DECIMAL(15,2),
    manager_id INT NULL,
    FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id),
    FOREIGN KEY (manager_id)
        REFERENCES employees(employee_id)
);

-- Q1
SELECT city, COUNT(customer_id) AS No_of_Customer
FROM customers
GROUP BY city
ORDER BY No_of_Customer DESC;

-- Q2
SELECT account_type, SUM(balance) AS total_balance
FROM accounts
GROUP BY account_type;

-- Q3
SELECT b.branch_name,COUNT(b.branch_id) AS Accounts_count
FROM branches b
JOIN accounts a
ON a.branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name
HAVING Accounts_count > 15;

-- Q4
SELECT b.branch_name,COUNT(a.account_id) AS Accounts_count,SUM(a.balance) AS branch_total_bal
FROM branches b
LEFT JOIN accounts a
ON a.branch_id = b.branch_id
GROUP BY b.branch_name;

-- Q5
SELECT CONCAT(c.first_name,' ',c.last_name) AS customer_name, a.account_id
FROM customers c
LEFT JOIN accounts a
ON c.customer_id = a.customer_id
WHERE account_id IS NULL;

-- Q6
SELECT e.employee_name, e.designation,
m.employee_name AS manager_name
FROM employees e
LEFT JOIN employees m
ON e.manager_id = m.employee_id;

-- Q7
SELECT account_type, balance,
CASE
	WHEN balance < 10000 THEN "Low"
    WHEN balance BETWEEN 10000 AND 100000 THEN "Medium"
    ELSE "High"
END AS balance_band
FROM accounts ;

-- Q8
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer_name, 
SUM(t.amount) AS total_spent
FROM customers c
JOIN accounts a
ON c.customer_id = a.customer_id
JOIN transactions t
ON t.account_id = a.account_id
WHERE t.transaction_type NOT IN ('Deposit', 'Transfer')
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 1;

-- Q9
SELECT e.employee_name, e.salary, e.branch_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.branch_id = e.branch_id
);

-- Q10
WITH ranked AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.city,
        SUM(a.balance) AS total_balance,
        ROW_NUMBER() OVER (
            PARTITION BY c.city
            ORDER BY SUM(a.balance) DESC
        ) AS rnk
    FROM customers c
    JOIN accounts a
        ON c.customer_id = a.customer_id
    GROUP BY c.customer_id, c.city
)
SELECT *
FROM ranked
WHERE rnk <= 3;

-- Q11
SELECT
    transaction_month,
    total_amount,
    LAG(total_amount) OVER (ORDER BY transaction_month) AS previous_month_amount
FROM (
    SELECT
        DATE_FORMAT(transaction_date, '%Y-%m') AS transaction_month,
        SUM(amount) AS total_amount
    FROM transactions
    GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
) AS monthly_data;

-- Q12
CREATE VIEW customer_account_summary AS
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
COUNT(a.account_id) AS total_no_of_acc, 
COALESCE(SUM(a.balance),0) AS total_bal
FROM customers c
LEFT JOIN accounts a
ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

SELECT * FROM customer_account_summary;   

-- Q13
WITH RECURSIVE employee_hierarchy AS (
SELECT
employee_id, employee_name, designation, 
manager_id, 1 AS level
FROM employees
WHERE designation = 'Regional Head'

UNION ALL

SELECT e.employee_id, e.employee_name,
e.designation, e.manager_id,
eh.level + 1
FROM employees e
JOIN employee_hierarchy eh
ON e.manager_id = eh.employee_id
)
SELECT *
FROM employee_hierarchy
ORDER BY level, employee_id;

-- Q14
SELECT
    UPPER(TRIM(email)) AS normalized_email,
    COUNT(*) AS duplicate_count
FROM customers
WHERE email IS NOT NULL
GROUP BY UPPER(TRIM(email))
HAVING COUNT(*) > 1;

-- Q15
SELECT transaction_id, transaction_type, amount
FROM transactions
WHERE amount < 0;

-- Q16
EXPLAIN
SELECT *
FROM transactions
WHERE account_id = 101;

CREATE INDEX idx_account_id
ON transactions(account_id);

-- Q17
SELECT b.branch_id, b.branch_name,
COUNT(l.loan_id) AS overdue_defaulted_loans
FROM branches b
JOIN loans l
ON b.branch_id = l.branch_id
WHERE l.status IN ('Overdue','Defaulted')
GROUP BY b.branch_id, b.branch_name
ORDER BY overdue_defaulted_loans DESC;

-- Q18
START TRANSACTION;
-- Credit ₹5,000 to account 1002
UPDATE accounts
SET balance = balance + 5000
WHERE account_id = 1002;
-- Debit ₹5,000 to account 1002
UPDATE accounts
SET balance = balance - 5000
WHERE account_id = 1002;

COMMIT;

SELECT account_id, customer_id, balance
FROM accounts
WHERE account_id = 1002;

-- Q19
START TRANSACTION;
-- Make an earlier change
UPDATE accounts
SET balance = balance - 4000
WHERE account_id = 1003;

-- Create savepoint
SAVEPOINT before_transfer;

-- Perform transfer
UPDATE accounts
SET balance = balance + 5000
WHERE account_id = 1003;

-- Undo only the transfer
ROLLBACK TO SAVEPOINT before_transfer;

-- Save the earlier change
COMMIT;

SELECT account_id, customer_id, balance
FROM accounts
WHERE account_id = 1003;

