-- ============================================================
--  SUPERSTORE SALES ANALYSIS — SQL QUERIES
--  Based on: Sales Analysis of a Superstore Dashboard
--  Tables: superstore_sales
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 0. TABLE CREATION (Run once to set up the schema)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS superstore_sales (
    Order_ID        VARCHAR(20)    NOT NULL,
    Order_Date      DATE           NOT NULL,
    Ship_Date       DATE,
    Ship_Mode       VARCHAR(30),
    Customer_ID     VARCHAR(15)    NOT NULL,
    Customer_Name   VARCHAR(100),
    Segment         VARCHAR(30),
    Country         VARCHAR(50),
    City            VARCHAR(100),
    State           VARCHAR(50),
    Region          VARCHAR(20),
    Product_ID      VARCHAR(20)    NOT NULL,
    Category        VARCHAR(50),
    Sub_Category    VARCHAR(50),
    Product_Name    VARCHAR(200),
    Sales           DECIMAL(12,2)  NOT NULL,
    Quantity        INT,
    Discount        DECIMAL(5,2),
    Profit          DECIMAL(12,2),
    PRIMARY KEY (Order_ID, Product_ID)
);


-- ============================================================
-- SECTION 1 — KPI SUMMARY (Total Sales & Total Profit Gauges)
-- ============================================================

-- 1.1  Overall Total Sales and Total Profit
SELECT
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales;


-- 1.2  KPIs filtered by Category and Region (mimics dashboard dropdowns)
--      Replace 'Technology' and 'West' with actual filter values, or remove WHERE clause for "All"
SELECT
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
WHERE Category = 'Technology'   -- remove or change as needed
  AND Region   = 'West';         -- remove or change as needed


-- ============================================================
-- SECTION 2 — TOTAL SALES & PROFIT BY CATEGORY (Pie Charts)
-- ============================================================

-- 2.1  Sales and Profit contribution by Category
SELECT
    Category,
    ROUND(SUM(Sales), 2)                                         AS Total_Sales,
    ROUND(SUM(Profit), 2)                                        AS Total_Profit,
    ROUND(SUM(Sales)  / SUM(SUM(Sales))  OVER () * 100, 2)      AS Sales_Share_Pct,
    ROUND(SUM(Profit) / SUM(SUM(Profit)) OVER () * 100, 2)      AS Profit_Share_Pct
FROM superstore_sales
GROUP BY Category
ORDER BY Total_Sales DESC;


-- 2.2  Profit margin by Category (highlights loss-making categories)
SELECT
    Category,
    ROUND(SUM(Sales), 2)                                       AS Total_Sales,
    ROUND(SUM(Profit), 2)                                      AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2)       AS Profit_Margin_Pct,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END)                AS Loss_Orders
FROM superstore_sales
GROUP BY Category
ORDER BY Profit_Margin_Pct DESC;


-- ============================================================
-- SECTION 3 — TOTAL SALES & PROFIT BY MONTH (Line Chart)
-- ============================================================

-- 3.1  Monthly Sales and Profit (all years combined by month name)
SELECT
    MONTHNAME(Order_Date)                    AS Month_Name,
    MONTH(Order_Date)                        AS Month_Num,
    ROUND(SUM(Sales), 2)                     AS Total_Sales,
    ROUND(SUM(Profit), 2)                    AS Total_Profit,
    ROUND(AVG(Sales), 2)                     AS Avg_Sales_Per_Order
FROM superstore_sales
GROUP BY Month_Name, Month_Num
ORDER BY Month_Num;


-- 3.2  Monthly trend by year (for year-over-year comparison)
SELECT
    YEAR(Order_Date)        AS Year,
    MONTH(Order_Date)       AS Month_Num,
    MONTHNAME(Order_Date)   AS Month_Name,
    ROUND(SUM(Sales), 2)    AS Total_Sales,
    ROUND(SUM(Profit), 2)   AS Total_Profit
FROM superstore_sales
GROUP BY Year, Month_Num, Month_Name
ORDER BY Year, Month_Num;


-- 3.3  Running total of sales by month (cumulative trend)
SELECT
    YEAR(Order_Date)                                               AS Year,
    MONTH(Order_Date)                                              AS Month_Num,
    ROUND(SUM(Sales), 2)                                           AS Monthly_Sales,
    ROUND(SUM(SUM(Sales)) OVER (
        PARTITION BY YEAR(Order_Date)
        ORDER BY MONTH(Order_Date)
    ), 2)                                                          AS Cumulative_Sales
FROM superstore_sales
GROUP BY Year, Month_Num
ORDER BY Year, Month_Num;


-- ============================================================
-- SECTION 4 — TOTAL SALES BY STATE (Geographic Map)
-- ============================================================

-- 4.1  Sales by State (bubbles on map)
SELECT
    State,
    Region,
    ROUND(SUM(Sales), 2)   AS Total_Sales,
    ROUND(SUM(Profit), 2)  AS Total_Profit,
    COUNT(DISTINCT Order_ID) AS Order_Count,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
GROUP BY State, Region
ORDER BY Total_Sales DESC;


-- 4.2  Top 10 States by Sales
SELECT
    State,
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM superstore_sales
GROUP BY State
ORDER BY Total_Sales DESC
LIMIT 10;


-- 4.3  Bottom 10 States by Sales
SELECT
    State,
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM superstore_sales
GROUP BY State
ORDER BY Total_Sales ASC
LIMIT 10;


-- ============================================================
-- SECTION 5 — HIGH & LOW SALES BY SUB-CATEGORY (Bar Charts)
-- ============================================================

-- 5.1  All Sub-Categories ranked by Sales (shows both high and low ends)
SELECT
    Sub_Category,
    Category,
    ROUND(SUM(Sales), 2)   AS Total_Sales,
    ROUND(SUM(Profit), 2)  AS Total_Profit,
    COUNT(DISTINCT Order_ID) AS Order_Count,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
GROUP BY Sub_Category, Category
ORDER BY Total_Sales DESC;


-- 5.2  Top 5 Sub-Categories by Sales (High Sales chart)
SELECT
    Sub_Category,
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM superstore_sales
GROUP BY Sub_Category
ORDER BY Total_Sales DESC
LIMIT 5;


-- 5.3  Bottom 5 Sub-Categories by Sales (Low Sales chart)
SELECT
    Sub_Category,
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM superstore_sales
GROUP BY Sub_Category
ORDER BY Total_Sales ASC
LIMIT 5;


-- 5.4  Sub-Categories with negative profit (loss makers)
SELECT
    Sub_Category,
    Category,
    ROUND(SUM(Sales), 2)   AS Total_Sales,
    ROUND(SUM(Profit), 2)  AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
GROUP BY Sub_Category, Category
HAVING Total_Profit < 0
ORDER BY Total_Profit ASC;


-- ============================================================
-- SECTION 6 — CUSTOMER & SEGMENT ANALYSIS
-- ============================================================

-- 6.1  Sales and Profit by Customer Segment
SELECT
    Segment,
    ROUND(SUM(Sales), 2)    AS Total_Sales,
    ROUND(SUM(Profit), 2)   AS Total_Profit,
    COUNT(DISTINCT Order_ID)  AS Order_Count,
    COUNT(DISTINCT Customer_ID) AS Customer_Count,
    ROUND(AVG(Sales), 2)    AS Avg_Order_Value
FROM superstore_sales
GROUP BY Segment
ORDER BY Total_Sales DESC;


-- 6.2  Top 10 Customers by Sales
SELECT
    Customer_ID,
    Customer_Name,
    Segment,
    ROUND(SUM(Sales), 2)   AS Total_Sales,
    ROUND(SUM(Profit), 2)  AS Total_Profit,
    COUNT(DISTINCT Order_ID) AS Order_Count
FROM superstore_sales
GROUP BY Customer_ID, Customer_Name, Segment
ORDER BY Total_Sales DESC
LIMIT 10;


-- 6.3  Customers with highest order frequency
SELECT
    Customer_ID,
    Customer_Name,
    COUNT(DISTINCT Order_ID)  AS Total_Orders,
    ROUND(SUM(Sales), 2)      AS Total_Sales,
    ROUND(SUM(Profit), 2)     AS Total_Profit
FROM superstore_sales
GROUP BY Customer_ID, Customer_Name
ORDER BY Total_Orders DESC
LIMIT 10;


-- ============================================================
-- SECTION 7 — SHIPPING & OPERATIONS ANALYSIS
-- ============================================================

-- 7.1  Sales by Ship Mode
SELECT
    Ship_Mode,
    COUNT(DISTINCT Order_ID) AS Order_Count,
    ROUND(SUM(Sales), 2)     AS Total_Sales,
    ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 1) AS Avg_Ship_Days
FROM superstore_sales
GROUP BY Ship_Mode
ORDER BY Total_Sales DESC;


-- 7.2  Average shipping time by category and ship mode
SELECT
    Category,
    Ship_Mode,
    ROUND(AVG(DATEDIFF(Ship_Date, Order_Date)), 1) AS Avg_Ship_Days,
    COUNT(DISTINCT Order_ID) AS Order_Count
FROM superstore_sales
GROUP BY Category, Ship_Mode
ORDER BY Category, Avg_Ship_Days;


-- ============================================================
-- SECTION 8 — DISCOUNT IMPACT ANALYSIS
-- ============================================================

-- 8.1  Effect of discount on profitability
SELECT
    CASE
        WHEN Discount = 0             THEN 'No Discount'
        WHEN Discount BETWEEN 0.01 AND 0.2 THEN '1%-20% Discount'
        WHEN Discount BETWEEN 0.21 AND 0.4 THEN '21%-40% Discount'
        ELSE '> 40% Discount'
    END                              AS Discount_Band,
    COUNT(*)                         AS Order_Count,
    ROUND(AVG(Discount) * 100, 1)   AS Avg_Discount_Pct,
    ROUND(SUM(Sales), 2)            AS Total_Sales,
    ROUND(SUM(Profit), 2)           AS Total_Profit,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
GROUP BY Discount_Band
ORDER BY Avg_Discount_Pct;


-- 8.2  Orders with highest discount causing losses
SELECT
    Order_ID,
    Product_Name,
    Category,
    Sub_Category,
    Discount,
    ROUND(Sales, 2)  AS Sales,
    ROUND(Profit, 2) AS Profit
FROM superstore_sales
WHERE Profit < 0
  AND Discount > 0
ORDER BY Profit ASC
LIMIT 20;


-- ============================================================
-- SECTION 9 — YEAR-OVER-YEAR & TREND ANALYSIS
-- ============================================================

-- 9.1  Annual Sales and Profit summary
SELECT
    YEAR(Order_Date)       AS Year,
    ROUND(SUM(Sales), 2)   AS Total_Sales,
    ROUND(SUM(Profit), 2)  AS Total_Profit,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
GROUP BY Year
ORDER BY Year;


-- 9.2  YoY Sales Growth by Category
SELECT
    YEAR(Order_Date)  AS Year,
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(
        (SUM(Sales) - LAG(SUM(Sales)) OVER (PARTITION BY Category ORDER BY YEAR(Order_Date)))
        / NULLIF(LAG(SUM(Sales)) OVER (PARTITION BY Category ORDER BY YEAR(Order_Date)), 0) * 100
    , 2) AS YoY_Growth_Pct
FROM superstore_sales
GROUP BY Year, Category
ORDER BY Category, Year;


-- ============================================================
-- SECTION 10 — REGION-LEVEL ANALYSIS
-- ============================================================

-- 10.1  Sales and Profit by Region
SELECT
    Region,
    ROUND(SUM(Sales), 2)    AS Total_Sales,
    ROUND(SUM(Profit), 2)   AS Total_Profit,
    COUNT(DISTINCT Order_ID)  AS Order_Count,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS Profit_Margin_Pct
FROM superstore_sales
GROUP BY Region
ORDER BY Total_Sales DESC;


-- 10.2  Best performing Category per Region
SELECT
    Region,
    Category,
    ROUND(SUM(Sales), 2)  AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM superstore_sales
GROUP BY Region, Category
ORDER BY Region, Total_Sales DESC;


-- ============================================================
-- END OF FILE
-- ============================================================
