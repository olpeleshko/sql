/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT *,
DENSE_RANK() OVER (PARTITION BY  customer_id ORDER BY market_date) as customer_visit
FROM customer_purchases

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */
SELECT * FROM (
	SELECT *,
	DENSE_RANK() OVER (PARTITION BY  customer_id ORDER BY market_date DESC) as customer_visit
	FROM customer_purchases) 
WHERE customer_visit = 1


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */
SELECT *, COUNT(*) OVER (PARTITION BY customer_id, product_id) AS customer_product_purchase_count FROM customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

-- 'Pep - Organic'
-- INSTR(product_name, '-') -> 5
-- LENGTH(product_name) -> 13
SELECT 
product_name, 
LTRIM(RTRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1, LENGTH(product_name) - INSTR(product_name, '-')))) AS description
FROM product


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
WITH daily_sales AS (
	SELECT  market_date, sum(quantity * cost_to_customer_per_qty ) AS sales_amount FROM customer_purchases GROUP BY market_date
),
daily_sales_ranked AS (
	SELECT *, RANK() OVER (ORDER BY sales_amount DESC) AS sales_rank FROM daily_sales
)
SELECT * FROM daily_sales_ranked WHERE sales_rank = 1
UNION
SELECT * FROM daily_sales_ranked WHERE sales_rank = (SELECT max(sales_rank) from daily_sales_ranked)


/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

WITH vendor_inventory_combined AS (
	SELECT  product_id, vendor_id, original_price FROM vendor_inventory GROUP BY product_id, vendor_id, original_price
),
vendor_inventory_to_customers AS
	(SELECT *, original_price * 5 as sales_for_customer FROM vendor_inventory_combined CROSS JOIN customer)
SELECT vendor.vendor_name, product.product_name, sum(sales_for_customer) AS total_sales FROM vendor_inventory_to_customers 
	INNER JOIN product ON vendor_inventory_to_customers.product_id = product.product_id
 	INNER JOIN vendor ON vendor_inventory_to_customers. vendor_id = vendor.vendor_id
 	GROUP BY vendor_inventory_to_customers.product_id, vendor_inventory_to_customers.vendor_id;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
CREATE TABLE product_units (
	product_id int(11) NOT NULL,
	product_name varchar(45) DEFAULT NULL,
	product_size varchar(45) DEFAULT NULL,
	product_category_id int(11) NOT NULL,
	product_qty_type varchar(45) DEFAULT NULL,
	snapshot_timestamp datetime	
);

INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
SELECT product_id, product_name, product_size, product_category_id, product_qty_type, CURRENT_TIMESTAMP FROM product;


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
INSERT INTO product_units VALUES (10, 'Eggs', '1 dozen', 6, 'unit', CURRENT_TIMESTAMP)


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units WHERE product_id = 10 and snapshot_timestamp = (SELECT min(snapshot_timestamp) from product_units WHERE product_id = 10)


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

WITH quantities_per_product_ranked AS (
	SELECT product_id, quantity, RANK() OVER (PARTITION BY product_id ORDER BY market_date DESC) as market_date_rank FROM vendor_inventory
),
last_quantity_per_product AS (
	SELECT product_id, quantity FROM quantities_per_product_ranked WHERE market_date_rank = 1
),
last_quantity_per_product_all_products AS  (
	SELECT product.product_id, COALESCE(quantity, 0) as quantity FROM product LEFT OUTER JOIN last_quantity_per_product ON product.product_id = last_quantity_per_product.product_id
)
UPDATE product_units set current_quantity = (SELECT quantity FROM last_quantity_per_product_all_products WHERE product_units.product_id = last_quantity_per_product_all_products.product_id)


