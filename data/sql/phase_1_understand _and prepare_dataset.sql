/*
-- ============================================================================
SQL EDA Phase 1: Data Understanding and Cleaning and Validation
Purpose: understand data in the dataset and prepare it for analysis in MySQL.    

-- Contents:
-- Task 1. Overview data 
-- Task 2. Find Missing Data (Checking 'NULL's)
-- Task 3. Count total Clients, Products, Orders and time range of the dataset
-- Task 4. Clean columns from redundant data 
-- Task 5. Validate and Fix Data 
-- ============================================================================
*/


-- ============================================================================
-- Task 0. Preliminary preparation. Selecting the dataset in MySQL database 
-- Goal: Ensure that the coirrect dataset is selected for investigation and analysis.
-- ============================================================================

USE UK_online_retail_db;
-- NOTE: Data was uploaded from CSV  - see README file for details on data source and upload process

-- ============================================================================
-- Task 1. Overview data 
-- Goal: Check if import worked. Check column names, data types, and key fields in each table.
-- ============================================================================

-- Step 1. Check datatypes and if the dataset was imported correctly

DESCRIBE UK_online_retail_db; -- check dataset structure and column data types

-- Insight: "Date" column is in TEXT format, which I will convert to DateTime format,
-- "ProductNo" column contains letters which indicate specific subgroup of products and which I will substitute with a number to create individual IDs,

-- Step 2. Check top 5 lines in the database as a database preview

SELECT * 
FROM UK_online_retail_db
LIMIT 5; 

-- Step 3. Optional. Check if all data was imported correctly

SELECT * 
FROM UK_online_retail_db;

-- Result: Database was imported correctly. 


- ============================================================================
-- Task 2. Find Missing Data (Checking 'NULL's)
-- Goal: Understand datsaset structure. Check column names, data types, and key fields in each table.
-- ============================================================================

SELECT
    SUM(CASE WHEN TransactionNo IS NULL THEN 1 ELSE 0 END) AS Missing_Transaction_IDs,
    SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS Missing_Dates,
    SUM(CASE WHEN ProductNo IS NULL THEN 1 ELSE 0 END) AS Missing_Product_IDs,
    SUM(CASE WHEN ProductName IS NULL THEN 1 ELSE 0 END) AS Missing_Product_Names,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS Missing_Prices,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Missing_Quantities,
    SUM(CASE WHEN CustomerNo IS NULL THEN 1 ELSE 0 END) AS Missing_Customer_IDs,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS Missing_Countries
FROM UK_online_retail_db;

-- Insight: 55 Customer Numbers were found missing. I will fix it in following tasks.


-- ============================================================================
-- Task 3. Count total Clients, Products, Orders and time range of the dataset
-- Goal: Count how many tems are in each coloumn in total and unique.
-- ============================================================================

SELECT
-- Checking "Transaction numbers" column
    COUNT (TransactionNo) AS Total_Transaction_IDs,
    COUNT (DISTINCT TransactionNo) AS Total_Unique_Transaction_IDs,

-- Checking which time period is covered by the dataset
    DATEDIFF(MAX(STR_TO_DATE(Date,'%m/%d/%Y')), MIN(STR_TO_DATE(Date,'%m/%d/%Y'))) AS Dataset_Time_Range, 
    MAX(STR_TO_DATE(Date,'%m/%d/%Y')) AS MAX_Date,
    MIN(STR_TO_DATE(Date,'%m/%d/%Y')) AS MIN_Date,

-- Checking "Product numbers" column
    COUNT (ProductNo) AS Total_Product_IDs,
    COUNT (DISTINCT ProductNo) AS Total_Unique_Product_IDs,

-- Checking "Product names" column
    COUNT (ProductName) AS Total_Product_Names,
    COUNT (DISTINCT ProductName) AS Total_Unique_Product_Names,

-- Exclude "Price" column because it makes no sense to investigate them in this type of analysis

-- Checking "Quantity" column
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS Refunds_Count,
        
-- Checking "Customer numbers" column
    COUNT (CustomerNo) AS Total_Customer_IDs,
    COUNT (DISTINCT CustomerNo) AS Total_Unique_Customer_IDs,

-- Checking "Country" column
   COUNT (DISTINCT Country) AS Total_Unique_Countries -- Counting only unique countries makes sense

FROM  UK_online_retail_db;

-- Insight: Dataset contains 536350 lines containing information about transactions, including 8585 refunds
-- performed by 4738 unique customers from 38 countries.
-- The dataset covers period from 2018-12-01 till 2019-12-09, total of 373 days.

-- ============================================================================
-- Task 5. Validate and Fix Data 
-- Goal: By validating and fixing issues prepare the dataset for the following analysis and trends identification 
-- ============================================================================

-- Note. Basing on the previous steps of data understanding following issues were identified:
-- Issue 1. "Date" column is in TEXT format which should be converted to DateTime format
-- Issue 2. "CustomerNo" column contain NULLs which I decided to change to "0" to keep this information and because this value is unoccupied. See the Jupyter notebook for details. 
-- Issue 3. a) Database contains duplicate rows. 
--          b) There are entries of the same transactions in which "Price" varies.
--          c) Some entries lead to negative total "Quantity" of sold products.
-- I decided to remove the found entries full duplicates, entries with "Price" changed and entries with Negative total quantities. 
-- I assume these are erratic data coming up from wrong entries or from incomplete database history.. 
-- Therefore, I consider these issues inappropriate for the following analysis of the online retailer database. See the Jupyter notebook for details.
-- Issue 4. "ProductName" column have combinations of items with conjunctions "+", "&", "and" all probably meaning "and". I decided to keep "&" symbol for all options for simplicity. 
-- Thus, I renamed other versions accordingly.
-- Issue 5. I change the dataset country name 'Eire' to 'Ireland(Eire)' for clarity.


-- Note. Here, to solve all issues, I decided to create a CTAS table with cleaned amount and date format that will be reused in further data analysis of this dataset. 
-- This will help to avoid repeating data cleaning steps in each query and make the code more efficient and readable.
-- Note 2. "ProductNo" column contains letters for "cancelled" orders which I keep. See the Jupyter notebook for details.


CREATE TABLE IF NOT EXISTS UK_online_retail_db.clean_data_db AS (
    SELECT 
        TransactionNo AS Order_id,

        STR_TO_DATE(Date,'%m/%d/%Y') AS Order_Date,                                 -- Fixing Issue 1. Date column formatting

        ProductNo AS Product_id,

        REPLACE(REPLACE(REPLACE(                                                    -- Fixing Issue 4. Unifying names by replacing various symbols with "&" and removing double spaces
            REPLACE(ProductName, ' and ', ' & '), '+', ' & '), '&', ' & '),'  ',' '
            ) AS Product_name,                                                      

        Price AS Price_UKpounds,
        Quantity AS Quantity_Ordered,

        CASE WHEN CustomerNo IS NULL THEN 0 ELSE CustomerNo END AS Customer_id,     -- Fixing issue 4. Missing values changed to "0"

        REPLACE(Country, 'EIRE', 'Ireland(EIRE)') AS Customer_country               -- Fixing Issue 5. Changing country name for clarity
    FROM 
        (SELECT                                                                     -- Fixing Issue 3. Removing duplicates and changes in pricing
            *,                                                                     
            ROW_NUMBER() OVER (
                    PARTITION BY TransactionNo, ProductNo, Quantity, CustomerNo
                    ORDER BY Date
                ) AS rn
        FROM UK_online_retail_db) duplicates
    WHERE rn < 2 OR ProductNo NOT IN (                                              -- Fixing Issue 3. Removing total negative quantity products
        SELECT 
            ProductNo
        FROM
            (SELECT 
                ProductNo,
                SUM(Quantity) AS Total_sold
            FROM UK_online_retail_db
            GROUP BY ProductNo) negative_sold
        WHERE Total_sold < 0
        ) 
);



