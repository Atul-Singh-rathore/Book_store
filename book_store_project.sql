-- 1. Books Table
DROP TABLE IF EXISTS BOOKS,CUSTOMERS,ORDERS;
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(100) NOT NULL,
    genre VARCHAR(50),
    published_year INT,
    price DECIMAL(5, 2),
    stock_quantity INT,
    rating DECIMAL(3, 1),
    publisher VARCHAR(100)
);

-- 2. Customers Table

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(50),
    total_orders INT,
    total_spent_inr DECIMAL(10, 2),
    signup_year INT,
    status VARCHAR(10)
);



-- 3. Orders Table (Relational Fact Table)

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    book_id INT,
    order_date DATE,
    quantity INT,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);
SELECT * FROM books;
SELECT * FROM orders;
SELECT * FROM CUSTOMERS;

-- Customers data import
COPY customers(customer_id, full_name, email, phone, gender, age, city, total_orders, total_spent_inr, signup_year, status)
FROM'E:\customers_data.csv'
DELIMITER ','
CSV HEADER;


-- Books data import
COPY books(book_id, title, author, genre, published_year, price, stock_quantity, rating, publisher)
FROM 'E:\books_data (1).csv'
DELIMITER ','
CSV HEADER;
-- Orders data import
COPY orders(order_id, customer_id, book_id, order_date, quantity, total_amount)
FROM 'E:\orders_data.csv'
DELIMITER ','
CSV HEADER;

-- 1. Find all books priced above $30, ordered by highest price first
SELECT title, author, price, rating 
FROM books 
WHERE price > 30.00 
ORDER BY price DESC;

-- 2. Find all active customers from Mumbai
SELECT customer_id, full_name, email, city, status 
FROM customers 
WHERE city = 'Mumbai' AND status = 'Active';

-- 3. Calculate overall bookstore metrics (Total orders, books sold, and revenue)
SELECT 
    COUNT(order_id) AS total_orders,
    SUM(quantity) AS total_books_sold,
    SUM(total_amount) AS total_revenue,
    ROUND(CAST(AVG(total_amount) AS NUMERIC), 2) AS avg_order_value
FROM orders;

-- 4. Total revenue generated per book genre
SELECT 
    b.genre, 
    SUM(o.quantity) AS total_units_sold,
    SUM(o.total_amount) AS total_revenue
FROM orders o
JOIN books b ON o.book_id = b.book_id
GROUP BY b.genre
ORDER BY total_revenue DESC;

--5 Detailed view combining orders with customer names and book titles
SELECT 
    o.order_id,
    c.full_name AS customer_name,
    b.title AS book_title,
    o.quantity,
    o.total_amount,
    o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN books b ON o.book_id = b.book_id
LIMIT 10;

-- 6. Top 5 highest-spending customers using a CTE (Common Table Expression)
WITH customer_spending AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders_placed,
        SUM(total_amount) AS lifetime_spent
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.full_name,
    c.city,
    cs.total_orders_placed,
    cs.lifetime_spent
FROM customer_spending cs
JOIN customers c ON cs.customer_id = c.customer_id
ORDER BY cs.lifetime_spent DESC
LIMIT 5;

-- 7. Rank top 3 best-selling books within each genre using Window Functions (DENSE_RANK)
WITH genre_ranking AS (
    SELECT 
        b.genre,
        b.title,
        SUM(o.total_amount) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY b.genre ORDER BY SUM(o.total_amount) DESC) as rnk
    FROM orders o
    JOIN books b ON o.book_id = b.book_id
    GROUP BY b.genre, b.title
)
SELECT * 
FROM genre_ranking
WHERE rnk <= 3;