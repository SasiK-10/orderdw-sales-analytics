-- ==================================================================

USE OrderDW;

-- -----------------------------------------------------------------
-- Stored Procedures
-- -----------------------------------------------------------------

-- Procedure to Populate DimDate table
DROP PROCEDURE IF EXISTS PopulateDimDate;
DELIMITER //
CREATE PROCEDURE PopulateDimDate(IN startDate DATE, IN endDate DATE)
BEGIN
    DECLARE currentDate DATE DEFAULT startDate;
    WHILE currentDate <= endDate DO
        INSERT IGNORE INTO DimDate (
            DateKey, FullDate, DayNumberOfWeek, DayNameOfWeek, DayNumberOfMonth, DayNumberOfYear,
            WeekNumberOfYear, MonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear, IsWeekend
        ) VALUES (
            YEAR(currentDate) * 10000 + MONTH(currentDate) * 100 + DAY(currentDate),
            currentDate, DAYOFWEEK(currentDate), DAYNAME(currentDate), DAYOFMONTH(currentDate), DAYOFYEAR(currentDate),
            WEEKOFYEAR(currentDate), MONTHNAME(currentDate), MONTH(currentDate), QUARTER(currentDate), YEAR(currentDate),
            CASE WHEN DAYOFWEEK(currentDate) IN (1, 7) THEN TRUE ELSE FALSE END
        );
        SET currentDate = DATE_ADD(currentDate, INTERVAL 1 DAY);
    END WHILE;
END //
DELIMITER ;
-- Note: CALL PopulateDimDate('YYYY-MM-DD', 'YYYY-MM-DD'); should be run separately after creation.

-- Procedure to Get or Create a Customer Key (Example for ETL)
DROP PROCEDURE IF EXISTS GetOrCreateCustomerKey;
DELIMITER //
CREATE PROCEDURE GetOrCreateCustomerKey (
    IN p_CustomerID VARCHAR(50),
    IN p_CustomerName VARCHAR(255),
    IN p_CustomerType VARCHAR(50),
    IN p_Email VARCHAR(255),
    IN p_Phone VARCHAR(30),
    OUT p_CustomerKey INT
)
BEGIN
    SELECT CustomerKey INTO p_CustomerKey
    FROM DimCustomer
    WHERE CustomerID = p_CustomerID
    LIMIT 1;

    IF p_CustomerKey IS NULL THEN
        INSERT INTO DimCustomer (CustomerID, CustomerName, CustomerType, Email, Phone)
        VALUES (p_CustomerID, p_CustomerName, p_CustomerType, p_Email, p_Phone);
        SET p_CustomerKey = LAST_INSERT_ID();
    -- ELSE -- Optional SCD logic placeholder
    END IF;
END //
DELIMITER ;

-- Procedure to Load a Fact Order Line (Example for ETL)
DROP PROCEDURE IF EXISTS LoadFactOrderLine;
DELIMITER //
CREATE PROCEDURE LoadFactOrderLine (
    IN p_SourceOrderNumber VARCHAR(50), IN p_SourceOrderLineNumber INT, IN p_SourceOrderDate DATE,
    IN p_SourceShipDate DATE, IN p_SourceCustomerID VARCHAR(50), IN p_SourceProductID VARCHAR(50),
    IN p_SourceShipToAddressLine1 VARCHAR(255), IN p_SourceShipToCity VARCHAR(100),
    IN p_SourceShipToStateProvince VARCHAR(100), IN p_SourceShipToPostalCode VARCHAR(20),
    IN p_SourceShipToCountry VARCHAR(100), IN p_SourceShipperID VARCHAR(50),
    IN p_QuantityOrdered INT, IN p_UnitPrice DECIMAL(18, 4), IN p_DiscountAmount DECIMAL(18, 4),
    IN p_UnitCost DECIMAL(18, 4)
)
BEGIN
    DECLARE v_OrderDateKey INT; DECLARE v_ShipDateKey INT; DECLARE v_CustomerKey INT;
    DECLARE v_ProductKey INT; DECLARE v_ShipToLocationKey INT; DECLARE v_ShipperKey INT;
    DECLARE v_LineTotalAmount DECIMAL(18, 4); DECLARE v_LineCostAmount DECIMAL(18, 4);

    -- 1. Look up Dimension Keys (Simplified - robust ETL needs GetOrCreate procs for all dims)
    SELECT DateKey INTO v_OrderDateKey FROM DimDate WHERE FullDate = p_SourceOrderDate;
    IF p_SourceShipDate IS NOT NULL THEN SELECT DateKey INTO v_ShipDateKey FROM DimDate WHERE FullDate = p_SourceShipDate; ELSE SET v_ShipDateKey = NULL; END IF;
    CALL GetOrCreateCustomerKey(p_SourceCustomerID, 'Unknown', 'Unknown', 'Unknown', 'Unknown', v_CustomerKey); -- Pass real source values
    SELECT ProductKey INTO v_ProductKey FROM DimProduct WHERE ProductID = p_SourceProductID LIMIT 1; -- Needs GetOrCreateProductKey
    SELECT LocationKey INTO v_ShipToLocationKey FROM DimLocation WHERE AddressLine1 = p_SourceShipToAddressLine1 AND City = p_SourceShipToCity AND StateProvince = p_SourceShipToStateProvince AND PostalCode = p_SourceShipToPostalCode AND Country = p_SourceShipToCountry LIMIT 1; -- Needs GetOrCreateLocationKey
    IF p_SourceShipperID IS NOT NULL THEN SELECT ShipperKey INTO v_ShipperKey FROM DimShipper WHERE ShipperID = p_SourceShipperID LIMIT 1; ELSE SET v_ShipperKey = NULL; END IF; -- Needs GetOrCreateShipperKey

    -- Basic Key Validation (Robust ETL would handle unknown keys more gracefully, e.g., assign -1)
    IF v_OrderDateKey IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'OrderDateKey lookup failed'; END IF;
    IF v_CustomerKey IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CustomerKey lookup failed'; END IF;
    IF v_ProductKey IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ProductKey lookup failed'; END IF;
    IF v_ShipToLocationKey IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ShipToLocationKey lookup failed'; END IF;

    -- 2. Calculate Measures
    SET v_LineTotalAmount = (p_QuantityOrdered * p_UnitPrice) - p_DiscountAmount;
    IF p_UnitCost IS NOT NULL THEN SET v_LineCostAmount = p_QuantityOrdered * p_UnitCost; ELSE SET v_LineCostAmount = NULL; END IF;

    -- 3. Insert into Fact Table
    INSERT INTO FactOrderLines (
        OrderDateKey, ShipDateKey, CustomerKey, ProductKey, ShipToLocationKey, ShipperKey,
        OrderNumber, OrderLineNumber,
        QuantityOrdered, UnitPrice, DiscountAmount, LineTotalAmount, UnitCost, LineCostAmount
    ) VALUES (
        v_OrderDateKey, v_ShipDateKey, v_CustomerKey, v_ProductKey, v_ShipToLocationKey, v_ShipperKey,
        p_SourceOrderNumber, p_SourceOrderLineNumber,
        p_QuantityOrdered, p_UnitPrice, p_DiscountAmount, v_LineTotalAmount, p_UnitCost, v_LineCostAmount
    );
END //
DELIMITER ;






-- -----------------------------------------------------------------
-- Views
-- -----------------------------------------------------------------

-- View for simplified Sales Reporting
CREATE OR REPLACE VIEW vw_OrderLineDetails AS
SELECT
    fol.OrderLineKey, fol.OrderNumber, fol.OrderLineNumber,
    -- Date Dimensions
    d_ord.FullDate AS OrderDate, d_ord.MonthName AS OrderMonth, d_ord.CalendarQuarter AS OrderQuarter, d_ord.CalendarYear AS OrderYear,
    d_shp.FullDate AS ShipDate,
    -- Customer Dimension
    dc.CustomerName, dc.CustomerType, dc.Email AS CustomerEmail,
    -- Product Dimension
    dp.ProductName, dp.Category AS ProductCategory, dp.Subcategory AS ProductSubcategory, dp.Brand AS ProductBrand,
    -- Location Dimension
    dl.AddressLine1 AS ShipToAddress1, dl.City AS ShipToCity, dl.StateProvince AS ShipToState, dl.PostalCode AS ShipToPostalCode, dl.Country AS ShipToCountry, dl.Region AS ShipToRegion,
    -- Shipper Dimension
    ds.ShipperName, ds.ServiceLevel AS ShippingServiceLevel,
    -- Facts / Measures
    fol.QuantityOrdered, fol.UnitPrice, fol.DiscountAmount, fol.LineTotalAmount, fol.UnitCost, fol.LineCostAmount,
    (fol.LineTotalAmount - fol.LineCostAmount) AS LineProfitAmount
FROM
    FactOrderLines fol
JOIN DimDate d_ord ON fol.OrderDateKey = d_ord.DateKey
LEFT JOIN DimDate d_shp ON fol.ShipDateKey = d_shp.DateKey
JOIN DimCustomer dc ON fol.CustomerKey = dc.CustomerKey
JOIN DimProduct dp ON fol.ProductKey = dp.ProductKey
JOIN DimLocation dl ON fol.ShipToLocationKey = dl.LocationKey
LEFT JOIN DimShipper ds ON fol.ShipperKey = ds.ShipperKey;

-- ==================================================================
-- Script Complete
-- ==================================================================