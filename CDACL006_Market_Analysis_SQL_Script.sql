/*
================================================================================
Project Name      : Market Analysis (CDACL006)
Student Name      : Vignesh Krishnamurthy
Course            : CDA
Team ID           : PTID-CDA-OCT-26-11120
Database Target   : project_orders
================================================================================
*/
USE project_orders;

-- =============================================================================
-- PROBLEM QUERIES
-- =============================================================================
-- Q1: What are the top 10 aisles with the highest number of products?
/*
Logic: 
 *   1. Inner join 'aisles' and 'products' on 'aisle_id'.
 *   2. Aggregate product counts per aisle.
 *   3. Sort descending by count and limit output to top 10.
 */
SELECT a.aisle,count(*) as Num_of_products
FROM aisles a
JOIN products p 
ON a.aisle_id = p.aisle_id
WHERE a.aisle != "missing"
GROUP BY a.aisle_id,a.aisle
ORDER BY Num_of_products DESC
LIMIT 10;

-- Q2: How many unique departments are there in the dataset?
/*
Logic: 
 *   Aggregate distinct number of deparments
 */
SELECT COUNT(DISTINCT department)
FROM departments;

-- Q3: What is the distribution of products across departments?
-- Count products in each department and calculate their percentage share
SELECT 
	department,
	count(product_id) as Num_of_Products_per_department,
	(
	(count(product_id) * 100)/(SELECT count(*) FROM products)
	) as Percentage
FROM departments d
INNER JOIN products p
ON d.department_id = p.department_id
GROUP by d.department_id
ORDER BY Num_of_Products_per_department DESC;

-- Q4: What are the top 10 products with the highest reorder rates?
/*
1. Select Product name and Avg of reordered from Products table
2. Inner Join order_products_train table
3. Sort descending by number of reorders and limit by top 10
*/ 
SELECT	p.product_name,
		COUNT(o.order_id) AS total_orders,
		SUM(o.reordered) AS total_reorders,
        ROUND(AVG(o.reordered)*100,2) as reorder_rate
FROM products p
JOIN order_products_train o
ON p.product_id = o.product_id
GROUP BY p.product_name, p.product_id
HAVING count(o.reordered) >= 100
ORDER BY reorder_rate DESC
LIMIT 10;


-- Q5: How many unique users have placed orders in the dataset?
/*
Logic: 
 *   Aggregate distinct number of unique users
 */
SELECT COUNT(DISTINCT o.user_id)
FROM orders o 
JOIN order_products_train op
ON o.order_id = op.order_id;

-- Q6: What is the average number of days between orders for each user?
-- Calculate the average days between orders for every individual user.
SELECT user_id,avg(days_since_prior_order) as avg_days_between_order
FROM orders
GROUP BY user_id;

-- Q7: What are the peak hours of order placement during the day?
-- Group orders by hour of the day and sort by highest order count.
SELECT order_hour_of_day,count(order_id) as total_orders
FROM orders
GROUP BY order_hour_of_day
ORDER BY total_orders desc;

-- Q8: How does order volume vary by day of the week?
-- Convert day numbers (0-6) into day names and see which days have the most orders.
SELECT (CASE WHEN order_dow = 0 THEN 'SUN'
WHEN order_dow = 1 THEN 'MON'
WHEN order_dow = 2 THEN 'TUE'
WHEN order_dow = 3 THEN 'WED'
WHEN order_dow = 4 THEN 'THUR'
WHEN order_dow = 5 THEN 'FRI'
WHEN order_dow = 6 THEN 'SAT' END
) as Order_Day_Of_The_Week,
ROUND(count(order_id) *100/(SELECT count(*) FROM orders),2) as Weekly_Percentage,
count(order_id) as Order_volume
FROM orders
GROUP BY Order_Day_Of_The_Week
ORDER BY Order_volume DESC;

-- Q9: What are the top 10 most ordered products?
-- Count how many times each product was ordered and list the top 10.
SELECT 
    p.product_name AS Product,
    top_products.Num_Of_Orders,
    a.aisle AS Aisle
FROM (
    SELECT 
        product_id, 
        COUNT(order_id) AS Num_Of_Orders
    FROM order_products_train
    GROUP BY product_id
    ORDER BY Num_Of_Orders DESC
    LIMIT 10
) top_products
JOIN products p 
    ON top_products.product_id = p.product_id
JOIN aisles a 
    ON p.aisle_id = a.aisle_id
ORDER BY top_products.Num_Of_Orders DESC;

-- Q10: How many users have placed orders in each department?
-- Count the number of unique users who bought items from each department.
SELECT	d.department as Department,
		count(DISTINCT o.user_id) as No_of_users,
		ROUND(
			count(DISTINCT o.user_id) *100  /
			(SELECT count(distinct o1.user_id) 
			FROM orders o1
			JOIN order_products_train ot
            ON o1.order_id = ot.order_id),
            2) as Percentage
FROM orders o
JOIN order_products_train op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department_id
ORDER BY percentage desc

-- Q11: What is the average number of products per order?
-- Find how many items are in each order, then get the overall average basket size.
SELECT ROUND(avg(total_count),2) as avg_products_per_order
FROM (
SELECT order_id,count(product_id) as total_count
FROM order_products_train
GROUP BY order_id
ORDER BY count(product_id) desc) a;

-- Q12: What are the most reordered products in each department?
-- Find how many items are in each order, then get the overall average basket size.
SELECT	dept_info.department,
		prod_info.product_name,
		dept_info.maximum_reorder
FROM(
	-- Maximum reorders per department
	SELECT	department,
			department_id,
            max(total_reorders) as maximum_reorder
	FROM(
    -- Total reorders per product_id 
		SELECT	d.department,
				d.department_id,
                op.product_id as product_id,
                sum(op.reordered) as total_reorders
		FROM order_products_train op
		JOIN products p ON op.product_id = p.product_id
		JOIN departments d ON p.department_id = d.department_id  
		GROUP BY op.product_id,d.department_id
		) a
	GROUP BY department_id
	ORDER BY max(total_reorders) desc 
	) dept_info
JOIN 
	-- Total reorders per product_name
		(
		SELECT	p.product_name as product_name,
				p.department_id as department_id,
                sum(op.reordered) as total_reorders
		FROM order_products_train op
		JOIN products p ON op.product_id = p.product_id 
		GROUP BY op.product_id
		ORDER BY total_reorders desc
		) prod_info
        
-- Join both the queries using maximum orders and department_id
ON dept_info.maximum_reorder = prod_info.total_reorders 
AND dept_info.department_id = prod_info.department_id
ORDER BY dept_info.maximum_reorder DESC;

-- Q13: How many products have been reordered more than once?
-- Count how many items have more than 1 total reorder.
SELECT count(*) as products_reordered_gt_1
FROM(
SELECT	product_id
FROM order_products_train
GROUP BY product_id
HAVING sum(reordered)>1)a;


-- Q14: What is the average number of products added to the cart per order?
-- Take the highest cart number in each order to get cart size, then find the average.
SELECT ROUND(AVG(cart_size), 2) AS avg_products_added_to_cart
FROM (
    SELECT order_id, MAX(add_to_cart_order) AS cart_size
    FROM order_products_train
    GROUP BY order_id
) a;

-- Q15: How does the number of orders vary by hour of the day?
-- Show total orders placed during each hour of the day (0 to 23).
SELECT order_hour_of_day,count(order_id) as number_of_orders
FROM orders
GROUP BY order_hour_of_day;

-- Q16: What is the distribution of order sizes (number of products per order)?
-- Count how many orders had 1 item, 2 items, 3 items, etc., and show the percentage.
SELECT	(CASE WHEN order_size <= 4 THEN "1 - 4 Items"
			WHEN order_size <= 8 THEN "5 - 8 Items"
            WHEN order_size <= 14 THEN "9 - 14 Items"
            WHEN order_size <= 24 THEN "15 - 24 Items"
            ELSE "25+ Items" 
		END) as order_size_bins,
		count(order_id) as num_of_orders,
		ROUND(count(order_id)*100/(SELECT count(DISTINCT order_id) FROM order_products_train),2) as percent
FROM(
	SELECT	order_id,
			max(add_to_cart_order) as order_size
	FROM order_products_train
	GROUP BY order_id
	) a
GROUP BY order_size_bins
ORDER BY percent DESC;


-- Q17: What is the average reorder rate for products in each aisle?
-- Calculate the average reorder rate for every aisle and sort from highest to lowest.
SELECT	a.aisle,
		ROUND(AVG(op.reordered) * 100,2) as Avg_Reordered_Value,
        d.department
FROM order_products_train op
JOIN products p
ON op.product_id= p.product_id
JOIN aisles a
ON p.aisle_id = a.aisle_id
JOIN departments d
ON p.department_id = d.department_id
GROUP BY p.aisle_id,a.aisle,d.department_id
ORDER BY Avg_Reordered_Value DESC;

-- Q18: How does the average order size vary by day of the week?
-- Check the average number of items per order for each day of the week.
SELECT	(CASE	WHEN order_dow = 0 THEN 'SUN'
				WHEN order_dow = 1 THEN 'MON'
				WHEN order_dow = 2 THEN 'TUE'
				WHEN order_dow = 3 THEN 'WED'
				WHEN order_dow = 4 THEN 'THUR'
				WHEN order_dow = 5 THEN 'FRI'
				WHEN order_dow = 6 THEN 'SAT' END
		) as Order_Day_Of_The_Week,
		ROUND(avg(order_size),2) as avg_order_size
FROM orders o
JOIN(
		SELECT	order_id,
				count(product_id) as order_size
		FROM order_products_train
		GROUP by order_id
	)a
ON o.order_id = a.order_id
GROUP BY Order_Day_Of_The_Week
ORDER BY avg_order_size DESC;

-- Q19: What are the top 10 users with the highest number of orders?
-- List the top 10 customers who placed the most orders.
SELECT
    user_id,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(days_since_prior_order), 2) AS avg_days_between_orders
FROM orders
GROUP BY user_id
ORDER BY total_orders DESC,
         avg_days_between_orders ASC,
         user_id ASC
LIMIT 10;



-- Q20: How many products belong to each aisle and department?
-- Show the product count grouped by department and aisle name.
SELECT 
    d.department,
    a.aisle,
    COUNT(p.product_id) AS product_count
FROM products p
JOIN departments d 
    ON p.department_id = d.department_id
JOIN aisles a 
    ON p.aisle_id = a.aisle_id
GROUP BY 
    d.department, 
    a.aisle
ORDER BY 
    d.department, 
    product_count DESC;
    
