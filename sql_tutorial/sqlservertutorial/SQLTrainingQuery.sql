
--======================================================================1. Diagnose Memory Usage====================================================================================
-------Check SQL Server Memory Usage
SELECT 
    [total_physical_memory_kb] / 1024 AS Total_Physical_Memory_MB,
    [available_physical_memory_kb] / 1024 AS Available_Physical_Memory_MB,
    [total_page_file_kb] / 1024 AS Total_Page_File_MB,
    [available_page_file_kb] / 1024 AS Available_Page_File_MB,
    [system_memory_state_desc] AS Memory_State
FROM sys.dm_os_sys_memory;

------Check Resource Pool Memory
SELECT 
    pool_id, 
    name, 
    max_memory_kb / 1024 AS Max_Memory_MB,
    used_memory_kb / 1024 AS Used_Memory_MB
FROM sys.dm_resource_governor_resource_pools;

----Check Running Queries
SELECT 
    r.session_id, 
    r.request_id, 
    r.cpu_time, 
	r.command,
    --r.memory_usage, 
    r.total_elapsed_time, 
    t.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
--WHERE r.memory_usage > 0;


--Identify queries or processes consuming high memory.
SELECT 
    [session_id],
    [memory_usage] * 8 / 1024 AS Memory_MB,
    [status],
    [login_name]
FROM sys.dm_exec_sessions
WHERE memory_usage > 0;
---Terminate problematic sessions:
DECLARE @session_id INT;
SET @session_id = 53; -- Replace 53 with the actual session ID
EXEC('KILL ' + @session_id);



--===========================================================2. Resolve Resource Constraints==================================================================================================
--A. Increase SQL Server Memory Allocation.Check Current Memory Settings:
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

--Increase Memory Allocation
EXEC sp_configure 'max server memory (MB)', 4096; -- Example: 8 GB
RECONFIGURE;


--Optimize tempdb Usage.
USE master;
GO
ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, SIZE = 500MB);
ALTER DATABASE tempdb MODIFY FILE (NAME = templog, SIZE = 500MB);
DBCC SHRINKDATABASE (tempdb);


--================================================3. Adjust SQL Server Resource Governor=============================================================================================
ALTER RESOURCE POOL [default]
WITH (MAX_MEMORY_PERCENT = 80); -- Allow up to 80% of system memory
ALTER RESOURCE GOVERNOR RECONFIGURE;

--==================================================4. Monitor System Resources======================================================================================================
--Use Task Manager or Performance Monitor on Windows to monitor SQL Server's memory usage.
--Look for processes consuming excessive memory.


--======================================================5. Clean Up TempDB===========================================================================================================
--1.Check its size
USE tempdb;
GO
EXEC sp_spaceused;


--2.Shrink tempdb
DBCC SHRINKDATABASE (tempdb);

--3. Check tempdb File Sizes and Usage.Run the following query to identify the current size and free space in the tempdb files:
USE tempdb;
GO
SELECT
    name AS FileName,
    size / 128 AS TotalSize_MB,
    size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0 AS FreeSpace_MB,
    physical_name AS FilePath
FROM sys.database_files;

--Shrink a specific file
DBCC SHRINKFILE (1, 500); -- Replace 1 with the appropriate file ID





--======================================================6. Restart SQL Server (Last Resort)==========================================================================================
--======================================================□ SQL Server Management Studio (SSMS):SQL Server Basics======================================================================--
--Author:SHIVAM GUPTA
--Create_Date: DECEMBER 01 2023
--Descriptions:
--Name:
--===================================================================================================================================================================================--
/* 
Section 0.1 Sample database
• https://www.sqlservertutorial.net/sql-server-sample-database/
*/




/* 
Section 0.2 Loading Sample database
• https://www.sqlservertutorial.net/load-sample-database/
*/




/* 
   
Section 1. Querying data
•SELECT – show you how to query data against a single table.
*/
--1.1.1) SQL Server SELECT – retrieve some columns of a table example------------------------------------------------------------------------------------------------------------------

select * from sys.databases;--show all databases

use BikeStores --use 'BikeStores' database
go 

SELECT
    first_name,
    last_name
FROM
    sales.customers;
--1.1.2) SQL Server SELECT – retrieve all columns from a table example-----------------------------------------------------------------------------------------------------------------
SELECT
    *
FROM
    sales.customers




/*
Section 2. Sorting data
• ORDER BY – sort the result set based on values in a specified list of columns
*/
--2.1.1) Sort a result set by one column in ascending order-----------------------------------------------------------------------------------------------------------------------------
SELECT
	first_name,
	last_name
FROM
	sales.customers
ORDER BY
	first_name
--2.1.2) Sort a result set by multiple columns---------------------------------------------------------------------------------------------------------------------------------------
SELECT
    city,
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    city,
    first_name;
--2.1.3) Sort a result set by multiple columns and different orders------------------------------------------------------------------------------------------------------------------
SELECT
    city,
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    city DESC,
    first_name ASC;
--2.1.4) Sort a result set by a column that is not in the select list----------------------------------------------------------------------------------------------------------------
SELECT
    city,
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    state;
--2.1.5) Sort a result set by an expression--------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    LEN(first_name) DESC;
--2.1.6) Sort by ordinal positions of columns-----------------------------------------------------------------------------------------------------------------------------------------
SELECT
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    1,
    2;





/*
Section 3. Limiting rows
• OFFSET FETCH – limit the number of rows returned by a query.
• SELECT TOP – limit the number of rows or percentage of rows returned in a query’s result set.
*/
--3.1.1)To skip the first 10 products and return the rest, you use the OFFSET clause as shown in the following statement-----------------------------------------------------------------
SELECT
    product_name,
    list_price
FROM
    production.products
ORDER BY
    list_price,
    product_name 
OFFSET 10 ROWS;
--3.1.2)To skip the first 10 products and select the next 10 products, you use both OFFSET and FETCH clauses as follows:----------------------------------------------------------------
SELECT
    product_name,
    list_price
FROM
    production.products
ORDER BY
    list_price,
    product_name 
OFFSET 10 ROWS 
FETCH NEXT 10 ROWS ONLY;
--3.1.3)To get the top 10 most expensive products you use both OFFSET and FETCH clauses:--------------------------------------------------------------------------------------------------
SELECT
    product_name,
    list_price
FROM
    production.products
ORDER BY
    list_price DESC,
    product_name 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
--3.2.1) Using TOP with a constant value(same as 3.1.3)--------------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 10
    product_name, 
    list_price
FROM
    production.products
ORDER BY 
    list_price DESC;
--3.2.2) Using TOP to return a percentage of rows-------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 1 PERCENT
    product_name, 
    list_price
FROM
    production.products
ORDER BY 
    list_price DESC;
--3.2.3) Using TOP WITH TIES to include rows that match the values in the last row-----------------------------------------------------------------------------------------------------
SELECT TOP 3 WITH TIES
    product_name, 
    list_price
FROM
    production.products
ORDER BY 
    list_price DESC;





/*
Section 4. Filtering data
• DISTINCT  – select distinct values in one or more columns of a table.
• WHERE – filter rows in the output of a query based on one or more conditions.
• AND – combine two Boolean expressions and return true if all expressions are true.
• OR–  combine two Boolean expressions and return true if either of conditions is true.
• IN – check whether a value matches any value in a list or a subquery.
• BETWEEN – test if a value is between a range of values.
• LIKE  –  check if a character string matches a specified pattern.
• Column & table aliases – show you how to use column aliases to change the heading of the query output and table alias to improve the readability of a query.
*/
--4.1.1) DISTINCT one column example--------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    city
FROM
    sales.customers
ORDER BY
    city;
--4.1.2) DISTINCT multiple columns example--------------------------------------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    city,
    state
FROM
    sales.customers
ORDER BY
     city,
     state
--4.1.3) DISTINCT with null values example-----------------------------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    phone
FROM
    sales.customers
ORDER BY
    phone;
--4.2.1) Finding rows by using a simple equality-----------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_id,
    product_name,
    category_id,
    model_year,
    list_price
FROM
    production.products
WHERE
    category_id = 1
ORDER BY
    list_price DESC;
--4.2.2) Finding rows by using a comparison operator-------------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_id,
    product_name,
    category_id,
    model_year,
    list_price
FROM
    production.products
WHERE
    list_price > 300 AND model_year = 2018
ORDER BY
    list_price DESC;
--4.2.3) Finding rows that have a value in a list of values---------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_id,
    product_name,
    category_id,
    model_year,
    list_price
FROM
    production.products
WHERE
    list_price IN (299.99, 369.99, 489.99)
ORDER BY
    list_price DESC;
--4.2.4) Finding rows whose values contain a string--------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_id,
    product_name,
    category_id,
    model_year,
    list_price
FROM
    production.products
WHERE
    product_name LIKE '%Cruiser%'
ORDER BY
    list_price;
--4.2.5)The following statement finds the customers who do not have phone numbers recorded in the  customers table:------------------------------------------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name,
    phone
FROM
    sales.customers
WHERE
    phone = NULL
ORDER BY
    first_name,
    last_name;
--4.2.6)To test whether a value is NULL or not, you always use the IS NULL operator.---------------------------------------------------------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name,
    phone
FROM
    sales.customers
WHERE
    phone IS NULL
ORDER BY
    first_name,
    last_name;
--4.3.1) Using AND operator example-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    *
FROM
    production.products
WHERE
    category_id = 1
AND list_price > 400
ORDER BY
    list_price DESC;
--4.3.2) Using multiple AND operators example------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    *
FROM
    production.products
WHERE
    category_id = 1
AND list_price > 400
AND brand_id = 1
ORDER BY
    list_price DESC;
--4.3.3) Using the AND operator with other logical operators----------------------------------------------------------------------------------------------------------------------------------
SELECT
    *
FROM
    production.products
WHERE
    brand_id = 1
OR brand_id = 2
AND list_price > 1000
ORDER BY
    brand_id DESC;
--4.3.4)To get the product whose brand id is one or two and list price is larger than 1,000, you use parentheses as follows:---------------------------------------------------------------------------------------
SELECT
    *
FROM
    production.products
WHERE
    (brand_id = 1 OR brand_id = 2)
AND list_price > 1000
ORDER BY
    brand_id;
--4.4.1) Using OR operator example---------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    list_price
FROM
    production.products
WHERE
    list_price < 200
OR list_price > 6000
ORDER BY
    list_price;
--4.4.2) Using multiple OR operators example----------------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    brand_id
FROM
    production.products
WHERE
    brand_id = 1
OR brand_id = 2
OR brand_id = 4
ORDER BY
    brand_id DESC;
--4.4.3)You can replace multiple OR operators by the IN operator as shown in the following query:-----------------------------------------------------------------------------------
SELECT
    product_name,
    brand_id
FROM
    production.products
WHERE
    brand_id IN (1, 2, 3)
ORDER BY
    brand_id DESC;
--4.4.4) Using OR operator with AND operator example-------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    product_name, 
    brand_id, 
    list_price
FROM 
    production.products
WHERE 
    brand_id = 1
      OR brand_id = 2
      AND list_price > 500
ORDER BY 
    brand_id DESC, 
    list_price;
--4.4.5)To find the products whose brand id is 1 or 2 and list price is greater than 500, you use the parentheses as shown in the following query:-----------------------------------------------------------
SELECT
    product_name,
    brand_id,
    list_price
FROM
    production.products
WHERE
    (brand_id = 1 OR brand_id = 2)
     AND list_price > 500
ORDER BY
    brand_id;
--4.5.1)To find the products whose list prices are not one of the prices above, you use the NOT IN operator as shown in the following query:------------------------------------------------------
SELECT
    product_name,
    list_price
FROM
    production.products
WHERE
    list_price NOT IN (89.99, 109.99, 159.99)
ORDER BY
    list_price;
--4.5.2) Using SQL Server IN operator with a subquery example------------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    list_price
FROM
    production.products
WHERE
    product_id IN (
        SELECT
            product_id
        FROM
            production.stocks
        WHERE
            store_id = 1 AND quantity >= 30
    )
ORDER BY
    product_name;
--4.6.1)To get the products whose list prices are not in the range of 149.99 and 199.99, you use the NOT BETWEEN operator as follows:------------------------------------------------------------
SELECT
    product_id,
    product_name,
    list_price
FROM
    production.products
WHERE
    list_price NOT BETWEEN 149.99 AND 199.99
ORDER BY
    list_price;
--4.7.1)The following example returns the customers whose last name ends with the string er:-------------------------------------------------------------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name
FROM
    sales.customers
WHERE
    last_name LIKE '%er'
ORDER BY
    first_name;
--4.7.2)The underscore represents a single character. For example, the following statement returns the customers where the second character is the letter u:
SELECT
    customer_id,
    first_name,
    last_name
FROM
    sales.customers
WHERE
    last_name LIKE '_u%'
ORDER BY
    first_name; 
--4.7.3)For example, the following query returns the customers where the first character in the last name is Y or Z:------------------------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name
FROM
    sales.customers
WHERE
    last_name LIKE '[YZ]%'
ORDER BY
    last_name;
--4.7.4)For example, the following query finds the customers where the first character in the last name is the letter in the range A through C:-----------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name
FROM
    sales.customers
WHERE
    last_name LIKE '[A-C]%'
ORDER BY
    first_name;
---4.7.5)For example, the following query returns the customers where the first character in the last name is not the letter in the range A through X:-----------------------------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name
FROM
    sales.customers
WHERE
    last_name LIKE '[^A-X]%'
ORDER BY
    last_name;
--4.7.6)The following example uses the NOT LIKE operator to find customers where the first character in the first name is not the letter A:----------------------------------------------------
SELECT
    customer_id,
    first_name,
    last_name
FROM
    sales.customers
WHERE
    first_name NOT LIKE 'A%'
ORDER BY
    first_name;
--4.7.7)SQL Server LIKE with ESCAPE example--------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE TABLE 
--            sales.feedbacks 
--           (
--            feedback_id INT IDENTITY(1, 1) PRIMARY KEY, 
--            comment  VARCHAR(255) NOT NULL
--           );
--INSERT INTO 
--           sales.feedbacks(comment)
--VALUES
--      ('Can you give me 30% discount?'),
--      ('May I get me 30USD off?'),
--      ('Is this having 20% discount today?');
SELECT 
   feedback_id, 
   comment
FROM 
   sales.feedbacks
WHERE 
   comment LIKE '%30!%%' ESCAPE '!';
--4.8.1)Note that if the column alias contains spaces, you need to enclose it in quotation marks as shown in the following example:------------------------------------------------------------
SELECT
    first_name + ' ' + last_name AS full_name
FROM
    sales.customers
ORDER BY
    first_name;
--4.8.2)When you assign a column an alias, you can use either the column name or the column alias in the ORDER BY clause as shown in the following example:---------------------------------------------------
SELECT
    category_name 'Product Category'
FROM
    production.categories
ORDER BY
    category_name;  


SELECT
    category_name 'Product Category'
FROM
    production.categories
ORDER BY
    'Product Category';
--4.8.3)Table aliases-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    sales.customers.customer_id,
    first_name,
    last_name,
    order_id
FROM
    sales.customers
INNER JOIN sales.orders ON sales.orders.customer_id = sales.customers.customer_id;





/*
Section 5. Joining tables
• Joins – give you a brief overview of joins types in SQL Server including inner join, left join, right join and full outer join.
• INNER JOIN – select rows from a table that have matching rows in another table.
• LEFT JOIN – return all rows from the left table and matching rows from the right table. In case the right table does not have the matching rows, use null values for the column values from the right table.
• RIGHT JOIN – learn a reversed version of the left join.
• FULL OUTER JOIN – return matching rows from both left and right tables, and rows from each side if no matching rows exist.
• CROSS JOIN – join multiple unrelated tables and create Cartesian products of rows in the joined tables.
• Self join – show you how to use the self-join to query hierarchical data and compare rows within the same table.
*/
--5.1.1)Joins – give you a brief overview of joins types in SQL Server including inner join, left join, right join and full outer join.
--GO
--CREATE SCHEMA 
--             hr;


--GO
--CREATE TABLE 
--            hr.candidates
--			(
--             id INT PRIMARY KEY IDENTITY,
--             fullname VARCHAR(100) NOT NULL
--            );
--GO
--CREATE TABLE 
--            hr.employees
--			(
--             id INT PRIMARY KEY IDENTITY,
--             fullname VARCHAR(100) NOT NULL
--            );


--INSERT INTO 
--    hr.candidates(fullname)
--VALUES
--    ('John Doe'),
--    ('Lily Bush'),
--    ('Peter Drucker'),
--    ('Jane Doe');


--INSERT INTO 
--    hr.employees(fullname)
--VALUES
--    ('John Doe'),
--    ('Jane Doe'),
--    ('Michael Scott'),
--    ('Jack Sparrow');
--5.2.1)the INNER JOIN clause(for combining two tables) as follows:----------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    category_name,
    list_price
FROM
    production.products p
INNER JOIN production.categories c ON c.category_id = p.category_id
ORDER BY
    product_name DESC;
--5.2.2)The following statement uses two INNER JOIN clauses to query data from the three tables:-----------------------------------------------------------------------------------------
SELECT
    product_name,
    category_name,
    brand_name,
    list_price
FROM
    production.products p
INNER JOIN production.categories c ON c.category_id = p.category_id
INNER JOIN production.brands b ON b.brand_id = p.brand_id
ORDER BY
    product_name DESC;
--5.3.1)The following query finds the products that belong to order id 100(left_join example):-----------------------------------------------------------------------------------------------------------------S
SELECT
    p.product_id,
    product_name,
    order_id
FROM
    production.products p
LEFT JOIN sales.order_items o ON o.product_id = p.product_id
ORDER BY
    order_id;
--5.3.2)SQL Server LEFT JOIN: conditions in ON vs. WHERE clause------------------------------------------------------------------------------------------------------------------------
SELECT
    p.product_id,
    product_name,
    order_id
FROM
    production.products p
LEFT JOIN sales.order_items o ON o.product_id = p.product_id
WHERE 
    order_id = 100
ORDER BY
    order_id;


SELECT
    p.product_id,
    product_name,
    order_id
FROM
    production.products p
LEFT JOIN sales.order_items o ON o.product_id = p.product_id AND o.order_id = 100
ORDER BY
    order_id DESC;
--5.4.1)The following statement returns all order_id from the sales.order_items and product name from the production.products table:--------------------------------------------------------
SELECT
    product_name,
    order_id
FROM
    sales.order_items o
RIGHT JOIN production.products p ON o.product_id = p.product_id
ORDER BY
    order_id;
--5.4.2)To get the products that do not have any sales, you add a WHERE clause to the above query to filter out the products that have sales:---------------------------------------
SELECT
    product_name,
    order_id
FROM
    sales.order_items o
RIGHT JOIN production.products p ON o.product_id = p.product_id
WHERE 
    order_id IS NULL
ORDER BY
      product_name
--5.5.1)To get the products that have sales & do not have sales:------------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    order_id
FROM
    sales.order_items o
FULL OUTER JOIN production.products p ON o.product_id = p.product_id
ORDER BY
      order_id
--5.5.2)To get the products that have sales & sales that do not have products:-----------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    order_id
FROM
    sales.order_items o
FULL OUTER JOIN production.products p ON o.product_id = p.product_id
WHERE o.product_id IS NULL OR p.product_id IS NULL
ORDER BY
      order_id
--5.5.3)To get the sales that have products & do not have products:--------------------------------------------------------------------------------------------------------------------------------
SELECT
    product_name,
    order_id
FROM
    production.products p 
FULL OUTER JOIN sales.order_items o ON o.product_id = p.product_id
ORDER BY
      order_id
--5.6.1)SQL Server CROSS JOIN examples-The following statement returns the combinations of all products and stores. The result set can be used for stocktaking procedure during the month-end and year-end closings:-------------------------
 SELECT
    product_id,
    product_name,
    store_id,
    0 AS quantity
FROM
    production.products
CROSS JOIN sales.stores
ORDER BY
    product_name,
    store_id;
--5.7.1)Using self join to query hierarchical data-------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    e.first_name + ' ' + e.last_name  as employee,
    m.first_name + ' ' + m.last_name  as manager
FROM
    sales.staffs as e
INNER JOIN sales.staffs as m ON m.staff_id = e.manager_id
ORDER BY
    manager;
--5.7.2)The employee column does not have Fabiola Jackson because of the INNER JOIN effect. If you replace the INNER JOIN clause by the LEFT JOIN clause as shown in the following query, you will get the result set that includes Fabiola Jackson in the employee column:
SELECT
    e.first_name + ' ' + e.last_name employee,
    m.first_name + ' ' + m.last_name manager
FROM
    sales.staffs e
LEFT JOIN sales.staffs m ON m.staff_id = e.manager_id
ORDER BY
    manager;






/*
Section 6. Grouping data
• GROUP BY– group the query result based on the values in a specified list of column expressions.
• HAVING – specify a search condition for a group or an aggregate.
• GROUPING SETS – generates multiple grouping sets.
• CUBE – generate grouping sets with all combinations of the dimension columns.
• ROLLUP – generate grouping sets with an assumption of the hierarchy between input columns.
*/
--6.1.1)The GROUP BY clause allows you to arrange the rows of a query in groups. The groups are determined by the columns that you specify in the GROUP BY clause.
SELECT
    customer_id,
    YEAR (order_date) order_year
FROM
    sales.orders
WHERE
    customer_id IN (1, 2)
GROUP BY
    customer_id,
    YEAR (order_date)
ORDER BY
    customer_id;
--6.1.2)SQL Server GROUP BY clause and aggregate functions[For example, the following query returns the number of orders placed by the customer by year:]------------------------------------------------------------------------------------------
 SELECT 
        *
 FROM
     sales.orders
 WHERE
    customer_id IN (1, 2)
 

 
SELECT
    customer_id,
    YEAR (order_date) AS order_year,
    COUNT (order_id)  AS order_placed,
	COUNT(*) AS total_group_count
FROM
    sales.orders
WHERE
    customer_id IN (1, 2)
GROUP BY
    customer_id,
    YEAR (order_date)
ORDER BY
    customer_id; 
--6.1.3)The following query returns the number of customers in every city:------------------------------------------------------------------------------------------------------------------
SELECT
    city,
    COUNT (customer_id) as customer_count
FROM
    sales.customers
GROUP BY
    city
ORDER BY
    city;

--6.1.4)Similarly, the following query returns the number of customers by state and city.----------------------------------------------------------------------------------------------------
SELECT
    city,
    state,
    COUNT (customer_id) customer_count
FROM
    sales.customers
GROUP BY
    state,
    city
ORDER BY
    city,
    state;
--6.1.5)The following statement returns the minimum and maximum list prices of all products with the model 2018 by brand:----------------------------------------------------------------------
SELECT
    brand_name,
    MIN (list_price) min_price,
    MAX (list_price) max_price
FROM
    production.products p
INNER JOIN production.brands b ON b.brand_id = p.brand_id
WHERE
    model_year = 2018
GROUP BY
    brand_name
ORDER BY
    brand_name;
--6.1.6)The following query uses the SUM() function to get the net value of every order:------------------------------------------------------------------------------------------------------
SELECT
    order_id,
    SUM (quantity * list_price * (1 - discount)) as net_value
FROM
    sales.order_items
GROUP BY
    order_id;
--6.2.1)The following statement uses the HAVING clause to find the customers who placed at least two orders per year:-----------------------------------------------------------------------
SELECT
    customer_id,
    YEAR (order_date),
    COUNT (order_id) order_count
FROM
    sales.orders
WHERE
    customer_id IN (1, 2)
GROUP BY
    customer_id,
    YEAR (order_date)
HAVING
    COUNT (order_id) >= 2
ORDER BY
    customer_id;
--6.2.2)The following statement finds the sales orders whose net values are greater than 20,000:---------------------------------------------------------------------
SELECT
    order_id,
    SUM (quantity * list_price * (1 - discount))  as net_value
FROM
    sales.order_items
GROUP BY
    order_id
HAVING
    SUM (quantity * list_price * (1 - discount)) > 20000
ORDER BY
    net_value
--6.2.3)The following statement first finds the maximum and minimum list prices in each product category. Then, it filters out the category which has the maximum list price greater than 4,000 or the minimum list price less than 500:
SELECT
    category_id,
    MAX (list_price) max_list_price,
    MIN (list_price) min_list_price
FROM
    production.products
GROUP BY
    category_id
HAVING
    MAX (list_price) > 4000 OR MIN (list_price) < 500;
--6.3.0)Getting started with SQL Server GROUPING SETS[To get a unified result set with the aggregated data for all grouping sets, you can use the UNION ALL operator.Because UNION ALL operator requires all result set to have the same number of columns, you need to add NULL to the select list to the queries like this:]-----------------------------------------------------------------------------
SELECT 
      state,
	  city,
	  count(email) AS email_count          --The following query returns the total email count by state & city. It defines a grouping set ( state,city):
FROM 
    sales.customers
GROUP BY
      state,
	  city
UNION ALL
SELECT 
      state,
	  NULL,
	  count(email) AS email_count         --The following query returns the total email count by state. It defines a grouping set (state):
FROM 
    sales.customers
GROUP BY
      state
UNION ALL
SELECT 
      NULL,
	  city,                               --The following query returns the total email count by city. It defines a grouping set (city)
	  count(email) AS email_count
FROM 
    sales.customers
GROUP BY
	  city
UNION ALL
SELECT 
      NULL,
	  NULL,
	  count(email) AS email_count         --empty groupin sets():The following query the total email count in sales.customers
FROM 
    sales.customers
ORDER BY
      state,
	  city;




SELECT 
      NULL,
	  city,                               
	  count(email) AS email_count
FROM 
    sales.customers
GROUP BY
	   GROUPING SETS                                 --You can use this GROUPING SETS to rewrite the query that gets the above data
	   (                                    
		(state, city),
		(state),  
		(city),
		()
	    )
ORDER BY
      state,
	  city
--6.4.1)SQL Server CUBE examples-The following statement uses the CUBE to generate four grouping sets:------------------------------------------------------------------------------    
SELECT
    state,
    city,
    count(email) AS email_count
FROM
    sales.customers
GROUP BY   
    CUBE(state,city)
ORDER BY
        state,
	    city
--6.5.1)Introduction to the SQL Server ROLLUP-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    state,
    city,
    count(email) AS email_count
FROM
    sales.customers
GROUP BY   
    ROLLUP(state,city)                   --the ROLLUP(d1,d2) creates only three grouping sets, assuming the hierarchy d1 > d2  as follows:
ORDER BY                                 --(state,city)
        state,                           --(state)
	    city                             --()







		                                 
/*
Section 8. Set Operators:This section walks you through of using the set operators including union, intersect, and except to combine multiple result sets from the input queries.
• UNION – combine the result sets of two or more queries into a single result set.
• INTERSECT – return the intersection of the result sets of two or more queries.
• EXCEPT – find the difference between the two result sets of two input queries.
*/
--8.1.1)UNION examples:The following example combines names of staff and customers into a single list(excluding duplicate row) from two tables:-----------------------------------------------------------------
SELECT
    first_name,
    last_name
FROM
    sales.staffs
UNION
SELECT
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    first_name,
    last_name;
--8.1.2)UNION ALL examples:The following example combines names of staff and customers into a single list(including duplicate row) from two tables:---------------------------------------------------------------:-------------------------------------------------------------
SELECT
    first_name,
    last_name
FROM
    sales.staffs
UNION ALL
SELECT
    first_name,
    last_name
FROM
    sales.customers
ORDER BY
    first_name,
    last_name;
--8.2.1)The first query finds all cities of the customers and the second query finds the cities of the stores. The whole query, which uses INTERSECT, returns the common cities of customers and stores----
SELECT
    city
FROM
    sales.customers
INTERSECT
SELECT
    city
FROM
    sales.stores
ORDER BY
    city;
--8.3.1)Simple EXCEPT example:The following example uses the EXCEPT operator to find the products that have no sales:----------------------------------------------------------------------------
SELECT
    product_id
FROM
    production.products
EXCEPT
SELECT
    product_id
FROM
    sales.order_items
ORDER BY
    product_id






/*
Section 9. Common Table Expression (CTE)
• CTE – use common table expresssions to make complex queries more readable.
• Recursive CTE – query hierarchical data using recursive CTE.
*/
--9.1.1)B) Using a simple common table expression example to make report averages based on counts[This example uses the CTE to return the average number of sales orders in 2018 for all sales staffs.]
WITH cte_sales AS 
(
    SELECT 
        staff_id, 
        COUNT(*) order_count  
    FROM
        sales.orders
    WHERE 
        YEAR(order_date) = 2018
    GROUP BY
        staff_id	    
)
SELECT
    AVG(order_count)  AS average_orders_count_by_staffs
FROM 
    cte_sales;
--9.1.2) Using multiple SQL Server CTE examples in a single query example[The following example uses two CTE cte_category_counts and cte_category_sales to return the number of the products and sales for each product category. The outer query joins two CTEs using the category_id column.]
WITH cte_category_counts (category_id, category_name, product_count) AS 
(
SELECT 
      c.category_id, 
      c.category_name, 
      COUNT(p.product_id)
FROM 
      production.products AS p
INNER JOIN production.categories AS c ON c.category_id = p.category_id
GROUP BY 
      c.category_id, 
      c.category_name
),
cte_category_sales(category_id, sales) AS 
(
SELECT    
      p.category_id, 
      SUM(i.quantity * i.list_price * (1 - i.discount))
FROM    
      sales.order_items  AS i
INNER JOIN production.products AS p ON p.product_id = i.product_id 
INNER JOIN sales.orders AS o ON o.order_id = i.order_id
WHERE 
      order_status = 4 -- completed
GROUP BY 
      p.category_id
) 
SELECT 
    c.category_id, 
    c.category_name, 
    c.product_count, 
    s.sales
FROM
    cte_category_counts  AS c
INNER JOIN cte_category_sales  AS s ON s.category_id = c.category_id
ORDER BY 
    c.category_name;
--9.2.1) a recursive CTE example to get all subordinates of the top manager who does not have a manager (or the value in the manager_id column is NULL):
WITH cte_org AS 
(
SELECT       
      staff_id, 
      first_name,
      manager_id
FROM       
      sales.staffs
WHERE 
      manager_id IS NULL
UNION ALL
SELECT 
      e.staff_id, 
      e.first_name,
      e.manager_id
FROM 
      sales.staffs AS e
INNER JOIN cte_org AS o ON o.staff_id = e.manager_id
)
SELECT * FROM cte_org;


SELECT * FROM   
(
    SELECT 
        category_name, 
        product_id
    FROM 
        production.products p
        INNER JOIN production.categories c 
            ON c.category_id = p.category_id
)  AS t 
PIVOT(
    COUNT(product_id) 
    FOR category_name IN (
        [Children Bicycles], 
        [Comfort Bicycles], 
        [Cruisers Bicycles], 
        [Cyclocross Bicycles], 
        [Electric Bikes], 
        [Mountain Bikes], 
        [Road Bikes])
) AS pivot_table;















/*
Section 15. Expressions
• CASE – add if-else logic to SQL queries by using simple and searched CASE expressions.
• COALESCE – handle NULL values effectively using the COALESCE expression.
• NULLIF – return NULL if the two arguments are equal; otherwise, return the first argument.
*/
--15.1.1.A) Using simple CASE expression in the SELECT clause example[See the following sales.orders table from the sample database:]/The values in the order_status column are numbers, which is not meaningful in this case. To make the output more understandable, you can use the simple CASE expression as shown in the following query:
SELECT    
    CASE order_status
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Processing'
        WHEN 3 THEN 'Rejected'
        WHEN 4 THEN 'Completed'
    END AS order_status, 
    COUNT(order_id) order_count
FROM    
    sales.orders
WHERE 
    YEAR(order_date) = 2018
GROUP BY 
    order_status;
--15.1.1.B) Using simple CASE expression in aggregate function example[See the following query:]-----------------------------------------------------------------------------------------
SELECT    
    SUM(CASE
            WHEN order_status = 1
            THEN 1
            ELSE 0
        END) AS 'Pending', 
    SUM(CASE
            WHEN order_status = 2
            THEN 1
            ELSE 0
        END) AS 'Processing', 
    SUM(CASE
            WHEN order_status = 3
            THEN 1
            ELSE 0
        END) AS 'Rejected', 
    SUM(CASE
            WHEN order_status = 4
            THEN 1
            ELSE 0
        END) AS 'Completed', 
    COUNT(*) AS Total
FROM    
    sales.orders
WHERE 
    YEAR(order_date) = 2018;
--15.1.2) Using searched CASE expression in the SELECT clause[See the following sales.orders and sales.order_items from the sample database:]
SELECT    
    o.order_id, 
    SUM(quantity * list_price) order_value,
    CASE
        WHEN SUM(quantity * list_price) <= 500 
            THEN 'Very Low'
        WHEN SUM(quantity * list_price) > 500 AND 
            SUM(quantity * list_price) <= 1000 
            THEN 'Low'
        WHEN SUM(quantity * list_price) > 1000 AND 
            SUM(quantity * list_price) <= 5000 
            THEN 'Medium'
        WHEN SUM(quantity * list_price) > 5000 AND 
            SUM(quantity * list_price) <= 10000 
            THEN 'High'
        WHEN SUM(quantity * list_price) > 10000 
            THEN 'Very High'
    END order_priority
FROM    
    sales.orders o
INNER JOIN sales.order_items i ON i.order_id = o.order_id
WHERE 
    YEAR(order_date) = 2018
GROUP BY 
    o.order_id;
--15.2.1)SQL Server COALESCE expression examples[Using SQL Server COALESCE expression with character string data example]--------------------------------------------------------------------------------------------------------------------------
SELECT 
    COALESCE(NULL, 'Hi', 'Hello', NULL) result;


SELECT 
    COALESCE(NULL, NULL, 100, 200) result;
--15.2.2) Using SQL Server COALESCE expression to substitute NULL by new values[To make the output more business friendly, you can use the COALESCE expression to substitute NULL by the string N/A (not available) as shown in the following query:]
SELECT 
    first_name, 
    last_name, 
    COALESCE(phone,'N/A') phone, 
    email
FROM 
    sales.customers
ORDER BY 
    first_name, 
    last_name;
--15.3.1) Using SQL Server COALESCE expression to use the available data----------------------------------------------------------------------------------------------------------------
CREATE TABLE salaries (
    staff_id INT PRIMARY KEY,
    hourly_rate decimal,
    weekly_rate decimal,
    monthly_rate decimal,
    CHECK(
        hourly_rate IS NOT NULL OR 
        weekly_rate IS NOT NULL OR 
        monthly_rate IS NOT NULL)
         );
INSERT INTO 
    salaries
	(
        staff_id, 
        hourly_rate, 
        weekly_rate, 
        monthly_rate
    )
VALUES
    (1,20, NULL,NULL),
    (2,30, NULL,NULL),
    (3,NULL, 1000,NULL),
    (4,NULL, NULL,6000),
    (5,NULL, NULL,6500);
SELECT
    staff_id, 
    hourly_rate, 
    weekly_rate, 
    monthly_rate
FROM
    salaries
ORDER BY
    staff_id;
SELECT
    staff_id,
    COALESCE
	(
        hourly_rate*22*8, 
        weekly_rate*4, 
        monthly_rate
    )AS monthly_salary
FROM
    salaries;
--15.2.4)COALESCE vs. CASE expression[The COALESCE expression is a syntactic sugar of the CASE expression.]---------------------------------------------------------------------------------
--COALESCE(e1,e2,e3)
--CASE
--    WHEN e1 IS NOT NULL THEN e1
--    WHEN e2 IS NOT NULL THEN e2
--    ELSE e3
--END
--15.3.1)SQL Server NULLIF examples[Using NULLIF expression with numeric data examples.This example returns NULL because the first argument equals the second one:]
SELECT 
    NULLIF(10, 10) result;


SELECT 
    NULLIF(20, 10) result;


SELECT 
    NULLIF('Hello', 'Hello') result;


SELECT 
    NULLIF('Hello', 'Hi') result;


--15.3.2)Using NULLIF expression to translate a blank string to NULLThe NULLIF expression comes in handy when you’re working with legacy data that contains a mixture of null and empty strings in a column. Consider the following example.
--CREATE TABLE sales.leads
--(
--    lead_id    INT	PRIMARY KEY IDENTITY, 
--    first_name VARCHAR(100) NOT NULL, 
--    last_name  VARCHAR(100) NOT NULL, 
--    phone      VARCHAR(20), 
--    email      VARCHAR(255) NOT NULL
--);
--INSERT INTO sales.leads
--(
--    first_name, 
--    last_name, 
--    phone, 
--    email
--)
--VALUES
--(
--    'John', 
--    'Doe', 
--    '(408)-987-2345', 
--    'john.doe@example.com'
--),
--(
--    'Jane', 
--    'Doe', 
--    '', 
--    'jane.doe@example.com'
--),
--(
--    'David', 
--    'Doe', 
--    NULL, 
--    'david.doe@example.com'
--);
SELECT 
    lead_id, 
    first_name, 
    last_name, 
    phone, 
    email
FROM 
    sales.leads
ORDER BY
    lead_id;
SELECT    
    lead_id, 
    first_name, 
    last_name, 
    phone, 
    email
FROM    
    sales.leads
WHERE 
    NULLIF(phone,'') IS NULL;
--15.3.3)NULLIF and CASE expression-------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @a int = 10, @b int = 20;
SELECT
    CASE
        WHEN @a = @b THEN null
        ELSE 
            @a
    END AS result;






/*
Section 16. Useful Tips
• Find duplicates – show you how to find duplicate values in one or more columns of a table.
• Delete duplicates – describe how to remove duplicate rows from a table.
*/
--16.1.1)Find Duplicates From a Table in SQL Server Using GROUP BY clause to find duplicates in a table[This statement(before create table 't1') uses the GROUP BY clause to find the duplicate rows in both a and b columns of the t1 table:]--------------------------------------------------------------------------------------------------------------------
--DROP TABLE IF EXISTS t1;
--CREATE TABLE t1 (
--    id INT IDENTITY(1, 1), 
--    a  INT, 
--    b  INT, 
--    PRIMARY KEY(id)
--);
--INSERT INTO
--    t1(a,b)
--VALUES
--    (1,1),
--    (1,2),
--    (1,3),
--    (2,1),
--    (1,2),
--    (1,3),
--    (2,1),
--    (2,2);
SELECT 
    a, 
    b, 
    COUNT(*) occurrences
FROM t1
GROUP BY
    a, 
    b
HAVING 
    COUNT(*) > 1;
--16.1.2)Using ROW_NUMBER() function to find duplicates in a table[The following statement uses the ROW_NUMBER() function to find duplicate rows based on both a and b columns:]
WITH cte AS 
(
SELECT 
      a, 
      b, 
      ROW_NUMBER() OVER 
	  (
          PARTITION BY a,b
          ORDER BY a,b
	  )rownum
FROM 
    t1
) 
SELECT 
  * 
FROM 
    cte 
WHERE 
    rownum > 1;
--16.2.1)Delete Duplicates From a Table in SQL ServerDelete duplicate rows from a table example[The following statement uses a common table expression (CTE) to delete duplicate rows:]
DROP TABLE IF EXISTS sales.contacts;
CREATE TABLE sales.contacts(
    contact_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(255) NOT NULL,
);
INSERT INTO sales.contacts
    (first_name,last_name,email) 
VALUES
    ('Syed','Abbas','syed.abbas@example.com'),
    ('Catherine','Abel','catherine.abel@example.com'),
    ('Kim','Abercrombie','kim.abercrombie@example.com'),
    ('Kim','Abercrombie','kim.abercrombie@example.com'),
    ('Kim','Abercrombie','kim.abercrombie@example.com'),
    ('Hazem','Abolrous','hazem.abolrous@example.com'),
    ('Hazem','Abolrous','hazem.abolrous@example.com'),
    ('Humberto','Acevedo','humberto.acevedo@example.com'),
    ('Humberto','Acevedo','humberto.acevedo@example.com'),
    ('Pilar','Ackerman','pilar.ackerman@example.com');

SELECT 
   contact_id, 
   first_name, 
   last_name, 
   email
FROM 
   sales.contacts;
WITH cte AS 
(
    SELECT 
        contact_id, 
        first_name, 
        last_name, 
        email, 
        ROW_NUMBER() OVER 
		(
            PARTITION BY 
                first_name, 
                last_name, 
                email
            ORDER BY 
                first_name, 
                last_name, 
                email
        )row_num
     FROM 
        sales.contacts
)
DELETE FROM cte
WHERE row_num > 1;
--=========================================================THE END======================================================================================================================--
--========================================================================================================================================================================================--


















   













