-- Create tables for classes, students and enrollment
CREATE TABLE customers (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    state       TEXT
);
CREATE TABLE state (
    id          SERIAL PRIMARY KEY,
    name        TEXT
);
CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    price       NUMERIC,
    category    TEXT
);
CREATE TABLE categories (
    id          SERIAL PRIMARY KEY,
    name        TEXT,
    description TEXT
);
CREATE TABLE sales (
    product     INTEGER REFERENCES products (id) NOT NULL,
    customer    INTEGER REFERENCES customers (id) NOT NULL,
    price       NUMERIC,
    quantity    NUMERIC
);

-- 1 show the total sales for each customer
SELECT customer.customer_id, customer.customer_name, SUM(sale.quantity) AS quantitysold, SUM(sale.price*sale.quantity) AS total_value
FROM sales.customer customer, sales.sale sale
WHERE customer.customer_id = sale.customer_id
GROUP BY customer.customer_id, customer_name


-- 2 show the total sales for each state
SELECT state1.state_id, state1.state_name, SUM(sale.quantity) AS quantity, SUM(sale.price*sale.quantity) AS total_value
FROM (sales.sale sale JOIN sales.customer customer ON sale.customer_id = customer.customer_id)
      JOIN sales.state state1 ON customer.state_id = state1.state_id 
GROUP BY state1.state_id


-- 3 show the total sales for each product, for a given customer_id=num
SELECT product.product_id, product.product_name, SUM(sale.quantity) AS quantity, SUM(sale.price*sale.quantity) AS total_value
FROM (sales.product product JOIN sales.sale sale ON product.product_id=sale.product_id)
      JOIN sales.customer ON customer.customer_id = sale.customer_id 
WHERE customer.customer_name = 'David'
GROUP BY product.product_id, product.product_name
ORDER BY total_value


-- 4 show the total sales for each product and customer
SELECT product.product_id, product.product_name, customer.customer_id, customer.customer_name, SUM(sale.quantity) AS quantity, SUM(sale.price*sale.quantity) AS total_value
FROM (sales.product product JOIN sales.sale sale ON product.product_id=sale.product_id)
      JOIN sales.customer ON customer.customer_id = sale.customer_id 
GROUP BY product.product_id, customer.customer_id
ORDER BY total_value


-- 5 show the total sales for each product category and state
SELECT category.category_id, category.category_name, state1.state_id, state1.state_name, SUM(sale.quantity) AS quantity, SUM(sale.price*sale.quantity) AS total_value
FROM sales.state state1
    JOIN sales.customer customer
        ON state1.state_id = customer.state_id
    JOIN sales.sale sale
        ON customer.customer_id = sale.customer_id
    JOIN sales.product product
        ON sale.product_id = sale.product_id
    JOIN sales.category category
        ON product.category_id = category.category_id
GROUP BY state1.state_id, category.category_id


-- 6 top product, top customer
WITH top_category_customer AS
(SELECT cat.category_id, cat.category_name, c.customer_id, c.customer_name
FROM sales.category cat, sales.customer c
WHERE cat.category_id IN (SELECT top_cat.category_id
                          FROM sales.category top_cat, sales.product top_p, sales.sale top_ps
                          WHERE top_cat.category_id = top_p.category_id AND top_p.product_id = top_ps.product_id
                          GROUP BY top_cat.category_id
                          ORDER BY sum(top_ps.quantity * top_ps.price) DESC LIMIT 20)
  AND c.customer_id IN (SELECT top_c.customer_id
                        FROM sales.customer top_c, sales.sale top_cs
                        WHERE top_c.customer_id = top_cs.customer_id
                        GROUP BY top_c.customer_id
                        ORDER BY sum(top_cs.quantity * top_cs.price) DESC LIMIT 20)
                        )
SELECT t.category_id, t.category_name, t.customer_id, t.customer_name, COALESCE(SUM(s.quantity),0) quantity_sold, COALESCE(SUM(s.quantity * s.price), 0) dollar_value
FROM (sales.sale s JOIN sales.product p ON s.product_id = p.product_id) RIGHT OUTER JOIN top_category_customer t
 ON p.category_id = t.category_id AND s.customer_id = t.customer_id
GROUP BY t.category_id, t.category_name, t.customer_id, t.customer_name
ORDER BY t.category_id, t.customer_id
