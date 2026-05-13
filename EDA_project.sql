/* =====================================================
   SALES & CUSTOMER ANALYTICS PROJECT
   =====================================================
   Project Type : Business Analytics / Data Analytics
   Database     : PostgreSQL
   Focus Areas  :
        - KPI Reporting
        - Customer Analytics
        - Product Analytics
        - Revenue Analysis
        - Time Intelligence
        - Customer Segmentation
        - RFM Analysis
        - Window Functions
        - Data Cleaning
===================================================== */


/* =====================================================
   1. DATA CLEANING & QUALITY CHECKS
===================================================== */

-- Check for NULL or empty order dates

SELECT *
FROM fact_sales
WHERE order_date IS NULL
   OR order_date = '';



-- Check for NULL customer keys

SELECT *
FROM fact_sales
WHERE customer_key IS NULL;



-- Check for duplicate order numbers

SELECT
    order_number,
    COUNT(*) AS duplicate_count
FROM fact_sales
GROUP BY order_number
HAVING COUNT(*) > 1;



-- Check for NULL product keys

SELECT *
FROM fact_sales
WHERE product_key IS NULL;



/* =====================================================
   2. BUSINESS OVERVIEW ANALYSIS
===================================================== */

-- Find the first and last order dates

SELECT
    MIN(NULLIF(order_date, '')::DATE) AS first_order_date,

    MAX(NULLIF(order_date, '')::DATE) AS last_order_date,

    AGE(
        MAX(NULLIF(order_date, '')::DATE),
        MIN(NULLIF(order_date, '')::DATE)
    ) AS business_operation_duration

FROM fact_sales;



-- Find the youngest and oldest customers

SELECT
    MIN(NULLIF(birthdate, '')::DATE) AS oldest_birthdate,

    AGE(
        CURRENT_DATE,
        MIN(NULLIF(birthdate, '')::DATE)
    ) AS oldest_customer_age,

    MAX(NULLIF(birthdate, '')::DATE) AS youngest_birthdate,

    AGE(
        CURRENT_DATE,
        MAX(NULLIF(birthdate, '')::DATE)
    ) AS youngest_customer_age

FROM dim_customers;



/* =====================================================
   3. KPI REPORTING
===================================================== */

-- Total Sales

SELECT
    SUM(sales_amount) AS total_sales
FROM fact_sales;



-- Total Quantity Sold

SELECT
    SUM(quantity) AS total_quantity_sold
FROM fact_sales;



-- Average Selling Price

SELECT
    ROUND(AVG(price), 2) AS avg_selling_price
FROM fact_sales;



-- Total Orders

SELECT
    COUNT(DISTINCT order_number) AS total_orders
FROM fact_sales;



-- Total Products

SELECT
    COUNT(product_key) AS total_products
FROM dim_products;



-- Total Customers

SELECT
    COUNT(customer_key) AS total_customers
FROM dim_customers;



-- Customers Who Placed Orders

SELECT
    COUNT(DISTINCT customer_key) AS active_customers
FROM fact_sales;



/* =====================================================
   4. MASTER KPI DASHBOARD
===================================================== */

SELECT
    'Total Sales' AS metric_name,
    SUM(sales_amount) AS metric_value
FROM fact_sales

UNION ALL

SELECT
    'Total Quantity',
    SUM(quantity)
FROM fact_sales

UNION ALL

SELECT
    'Average Price',
    ROUND(AVG(price), 2)
FROM fact_sales

UNION ALL

SELECT
    'Total Orders',
    COUNT(DISTINCT order_number)
FROM fact_sales

UNION ALL

SELECT
    'Total Products',
    COUNT(product_key)
FROM dim_products

UNION ALL

SELECT
    'Total Customers',
    COUNT(customer_key)
FROM dim_customers;



/* =====================================================
   5. CUSTOMER ANALYSIS
===================================================== */

-- Total customers by country

SELECT
    country,
    COUNT(DISTINCT customer_key) AS total_customers
FROM dim_customers
GROUP BY country
ORDER BY total_customers DESC;



-- Total customers by gender

SELECT
    gender,
    COUNT(DISTINCT customer_key) AS total_customers
FROM dim_customers
GROUP BY gender
ORDER BY total_customers DESC;



-- Distribution of sold items across countries

SELECT
    dc.country,
    SUM(fs.quantity) AS total_sold_items

FROM fact_sales fs

LEFT JOIN dim_customers dc
    ON fs.customer_key = dc.customer_key

GROUP BY dc.country
ORDER BY total_sold_items DESC;



/* =====================================================
   6. PRODUCT ANALYSIS
===================================================== */

-- Total products by category

SELECT
    category,
    COUNT(DISTINCT product_key) AS total_products
FROM dim_products
GROUP BY category
ORDER BY total_products DESC;



-- Average product cost in each category

SELECT
    category,
    ROUND(AVG(cost), 2) AS avg_product_cost
FROM dim_products
GROUP BY category
ORDER BY avg_product_cost DESC;



/* =====================================================
   7. REVENUE ANALYSIS
===================================================== */

-- Total revenue generated for each category

SELECT
    dp.category,
    SUM(fs.sales_amount) AS total_revenue

FROM fact_sales fs

LEFT JOIN dim_products dp
    ON fs.product_key = dp.product_key

GROUP BY dp.category
ORDER BY total_revenue DESC;



-- Total revenue generated by each customer

SELECT
    dc.customer_key,
    dc.first_name,
    dc.last_name,

    SUM(fs.sales_amount) AS total_revenue

FROM fact_sales fs

LEFT JOIN dim_customers dc
    ON fs.customer_key = dc.customer_key

GROUP BY
    dc.customer_key,
    dc.first_name,
    dc.last_name

ORDER BY total_revenue DESC;



/* =====================================================
   8. TOP & BOTTOM PERFORMERS
===================================================== */

-- Top 5 revenue-generating products

SELECT
    dp.product_name,

    SUM(fs.sales_amount) AS total_revenue

FROM fact_sales fs

LEFT JOIN dim_products dp
    ON fs.product_key = dp.product_key

GROUP BY dp.product_name
ORDER BY total_revenue DESC
LIMIT 5;



-- Bottom 5 products by revenue

SELECT
    dp.product_name,

    SUM(fs.sales_amount) AS total_revenue

FROM fact_sales fs

LEFT JOIN dim_products dp
    ON fs.product_key = dp.product_key

GROUP BY dp.product_name
ORDER BY total_revenue
LIMIT 5;



-- Top 10 customers by revenue

SELECT
    dc.customer_key,
    dc.first_name,
    dc.last_name,

    SUM(fs.sales_amount) AS total_revenue

FROM fact_sales fs

LEFT JOIN dim_customers dc
    ON fs.customer_key = dc.customer_key

GROUP BY
    dc.customer_key,
    dc.first_name,
    dc.last_name

ORDER BY total_revenue DESC
LIMIT 10;



-- Customers with the fewest orders

SELECT
    dc.customer_key,
    dc.first_name,
    dc.last_name,

    COUNT(DISTINCT fs.order_number) AS total_orders

FROM fact_sales fs

LEFT JOIN dim_customers dc
    ON fs.customer_key = dc.customer_key

GROUP BY
    dc.customer_key,
    dc.first_name,
    dc.last_name

ORDER BY total_orders
LIMIT 3;



/* =====================================================
   9. WINDOW FUNCTION ANALYSIS
===================================================== */

-- Top 5 products using ROW_NUMBER()

SELECT *
FROM (
    SELECT
        dp.product_name,

        SUM(fs.sales_amount) AS total_revenue,

        ROW_NUMBER() OVER (
            ORDER BY SUM(fs.sales_amount) DESC
        ) AS revenue_rank

    FROM fact_sales fs

    LEFT JOIN dim_products dp
        ON fs.product_key = dp.product_key

    GROUP BY dp.product_name

) ranked_products

WHERE revenue_rank <= 5;



/* =====================================================
   10. TIME INTELLIGENCE ANALYSIS
===================================================== */

-- Monthly sales trend

SELECT
    EXTRACT(YEAR FROM NULLIF(order_date, '')::DATE) AS order_year,

    EXTRACT(MONTH FROM NULLIF(order_date, '')::DATE) AS order_month,

    SUM(sales_amount) AS monthly_sales

FROM fact_sales

GROUP BY
    order_year,
    order_month

ORDER BY
    order_year,
    order_month;



-- Yearly sales trend

SELECT
    EXTRACT(YEAR FROM NULLIF(order_date, '')::DATE) AS order_year,

    SUM(sales_amount) AS yearly_sales

FROM fact_sales

GROUP BY order_year
ORDER BY order_year;



-- Quarterly sales trend

SELECT
    EXTRACT(YEAR FROM NULLIF(order_date, '')::DATE) AS order_year,

    EXTRACT(QUARTER FROM NULLIF(order_date, '')::DATE) AS quarter,

    SUM(sales_amount) AS quarterly_sales

FROM fact_sales

GROUP BY
    order_year,
    quarter

ORDER BY
    order_year,
    quarter;



/* =====================================================
   11. CUSTOMER SEGMENTATION
===================================================== */

WITH customer_spending AS (

    SELECT
        customer_key,

        SUM(sales_amount) AS total_spent

    FROM fact_sales

    GROUP BY customer_key
)

SELECT
    customer_key,

    total_spent,

    CASE
        WHEN total_spent >= 5000 THEN 'VIP Customer'

        WHEN total_spent >= 2000 THEN 'Regular Customer'

        ELSE 'Low-Value Customer'
    END AS customer_segment

FROM customer_spending

ORDER BY total_spent DESC;



/* =====================================================
   12. RFM ANALYSIS
   =====================================================
   R = Recency
   F = Frequency
   M = Monetary
===================================================== */

WITH rfm_base AS (

    SELECT
        customer_key,

        MAX(NULLIF(order_date, '')::DATE) AS last_order_date,

        COUNT(DISTINCT order_number) AS frequency,

        SUM(sales_amount) AS monetary_value

    FROM fact_sales

    GROUP BY customer_key
)

SELECT
    customer_key,

    CURRENT_DATE - last_order_date AS recency_days,

    frequency,

    monetary_value,

    CASE
        WHEN monetary_value >= 5000
             AND frequency >= 10
        THEN 'High Value Customer'

        WHEN monetary_value >= 2000
        THEN 'Medium Value Customer'

        ELSE 'Low Value Customer'
    END AS customer_type

FROM rfm_base

ORDER BY monetary_value DESC;



/* =====================================================
   13. ADVANCED CTE ANALYSIS
===================================================== */

WITH category_sales AS (

    SELECT
        dp.category,

        SUM(fs.sales_amount) AS total_sales

    FROM fact_sales fs

    LEFT JOIN dim_products dp
        ON fs.product_key = dp.product_key

    GROUP BY dp.category
)

SELECT
    category,
    total_sales,

    ROUND(
        total_sales * 100.0 /
        SUM(total_sales) OVER (),
        2
    ) AS sales_percentage

FROM category_sales

ORDER BY total_sales DESC;



/* =====================================================
   14. BUSINESS INSIGHTS
===================================================== */

-- Insight 1:
-- Categories with the highest revenue indicate
-- stronger market demand and customer preference.


-- Insight 2:
-- High-value customers contribute a large
-- percentage of total revenue.


-- Insight 3:
-- Monthly sales trends help identify
-- seasonality patterns and peak sales periods.


-- Insight 4:
-- RFM analysis helps businesses identify
-- loyal, inactive, and high-spending customers.


-- Insight 5:
-- Product-level analysis helps management
-- optimize inventory and marketing strategies.



/* =====================================================
   END OF PROJECT
===================================================== */