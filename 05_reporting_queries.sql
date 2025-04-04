
USE OrderDW;

-- Query 1: Total Sales and Profit by Year
-- Shows total sales, calculated profit, approximate order count, and order line count by year.
SELECT
    OrderYear,
    SUM(LineTotalAmount) AS TotalSales,
    SUM(LineProfitAmount) AS TotalProfit, -- Assumes LineProfitAmount is defined in the view
    COUNT(DISTINCT OrderNumber) AS NumberOfOrders,
    COUNT(OrderLineKey) AS NumberOfOrderLines
FROM
    vw_OrderLineDetails
GROUP BY
    OrderYear
ORDER BY
    OrderYear;

-- Query 2: Top 10 Products by Total Sales Amount
-- Identifies the top 10 products based on generated revenue.
SELECT
    ProductName,
    ProductCategory,
    SUM(LineTotalAmount) AS TotalSalesAmount
FROM
    vw_OrderLineDetails
GROUP BY
    ProductName,
    ProductCategory
ORDER BY
    TotalSalesAmount DESC
LIMIT 10;

-- Query 3: Sales by Product Category and Customer Type
-- Breaks down sales amount and quantity by product category and customer type.
SELECT
    ProductCategory,
    CustomerType,
    SUM(LineTotalAmount) AS TotalSales,
    SUM(QuantityOrdered) AS TotalQuantitySold
FROM
    vw_OrderLineDetails
GROUP BY
    ProductCategory,
    CustomerType
ORDER BY
    ProductCategory,
    CustomerType;

-- Query 4: Monthly Sales Trend for a Specific Year (e.g., 2024)
-- Shows the month-by-month sales progression within a given year.
-- *** Change the year in the WHERE clause as needed ***
SELECT
    OrderYear,
    DATE_FORMAT(OrderDate, '%Y-%m') AS SalesMonth,
    SUM(LineTotalAmount) AS MonthlySales
FROM
    vw_OrderLineDetails
WHERE
    OrderYear = 2024 -- <<< ADJUST YEAR HERE
GROUP BY
    OrderYear,
    SalesMonth
ORDER BY
    SalesMonth;

-- Query 5: Sales Performance by Shipping Country and State/Province
-- Aggregates sales based on the shipping location, showing top states/provinces within countries.
SELECT
    ShipToCountry,
    ShipToState,
    SUM(LineTotalAmount) AS TotalSales,
    COUNT(DISTINCT CustomerName) AS NumberOfCustomers
FROM
    vw_OrderLineDetails
GROUP BY
    ShipToCountry,
    ShipToState
ORDER BY
    ShipToCountry,
    TotalSales DESC;

-- ==================================================================
-- End of Sample Queries
-- ==================================================================
