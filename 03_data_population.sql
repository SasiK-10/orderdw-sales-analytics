
USE OrderDW;

-- Clear existing data (Run in this order if uncommented)
/*
DELETE FROM FactOrderLines;
DELETE FROM DimShipper;
DELETE FROM DimLocation;
DELETE FROM DimProduct;
DELETE FROM DimCustomer;
DELETE FROM DimDate;
-- Reset auto_increment counters if needed (optional):
-- ALTER TABLE DimCustomer AUTO_INCREMENT = 1;
-- ALTER TABLE DimProduct AUTO_INCREMENT = 1;
-- ALTER TABLE DimLocation AUTO_INCREMENT = 1;
-- ALTER TABLE DimShipper AUTO_INCREMENT = 1;
-- ALTER TABLE FactOrderLines AUTO_INCREMENT = 1;
*/


-- 1. Populate DimDate (Manually selected dates)
-- DateKey format is YYYYMMDD
INSERT IGNORE INTO DimDate (DateKey, FullDate, DayNumberOfWeek, DayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, MonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear, IsWeekend) VALUES
(20240115, '2024-01-15', 2, 'Monday', 15, 15, 3, 'January', 1, 1, 2024, 0),
(20240210, '2024-02-10', 7, 'Saturday', 10, 41, 6, 'February', 2, 1, 2024, 1),
(20240211, '2024-02-11', 1, 'Sunday', 11, 42, 6, 'February', 2, 1, 2024, 1),
(20240305, '2024-03-05', 3, 'Tuesday', 5, 65, 10, 'March', 3, 1, 2024, 0),
(20240422, '2024-04-22', 2, 'Monday', 22, 113, 17, 'April', 4, 2, 2024, 0),
(20240518, '2024-05-18', 7, 'Saturday', 18, 139, 20, 'May', 5, 2, 2024, 1),
(20240630, '2024-06-30', 1, 'Sunday', 30, 182, 26, 'June', 6, 2, 2024, 1),
(20240704, '2024-07-04', 5, 'Thursday', 4, 186, 27, 'July', 7, 3, 2024, 0),
(20240819, '2024-08-19', 2, 'Monday', 19, 232, 34, 'August', 8, 3, 2024, 0),
(20240925, '2024-09-25', 4, 'Wednesday', 25, 269, 39, 'September', 9, 3, 2024, 0),
(20241031, '2024-10-31', 5, 'Thursday', 31, 305, 44, 'October', 10, 4, 2024, 0),
(20241111, '2024-11-11', 2, 'Monday', 11, 316, 46, 'November', 11, 4, 2024, 0),
(20241224, '2024-12-24', 3, 'Tuesday', 24, 359, 52, 'December', 12, 4, 2024, 0),
(20241225, '2024-12-25', 4, 'Wednesday', 25, 360, 52, 'December', 12, 4, 2024, 0),
(20250101, '2025-01-01', 4, 'Wednesday', 1, 1, 1, 'January', 1, 1, 2025, 0),
-- Using current date from context (April 3, 2025)
(20250403, '2025-04-03', 5, 'Thursday', 3, 93, 14, 'April', 4, 2, 2025, 0);


-- 2. Populate DimCustomer
INSERT INTO DimCustomer (CustomerID, CustomerName, CustomerType, Email, Phone) VALUES
('CUST001', 'Acme Corporation', 'Business', 'orders@acme.com', '555-0101'),
('CUST002', 'Beta Services LLC', 'Business', 'contact@beta.llc', '555-0102'),
('CUST003', 'Charlie Retail Inc.', 'Retail', 'purchasing@charlieinc.com', '555-0103'),
('CUST004', 'Delta Manufacturing', 'Business', 'supply@delta.mfg', '555-0104'),
('CUST005', 'Echo Supplies', 'Wholesale', 'sales@echo.supplies', '555-0105'),
('IND001', 'Alice Wonderland', 'Individual', 'alice.w@mail.com', '555-0201'),
('IND002', 'Bob The Builder', 'Individual', 'bob.b@mail.com', '555-0202'),
('IND003', 'Carol Danvers', 'Individual', 'carol.d@mail.com', '555-0203'),
('IND004', 'David Banner', 'Individual', 'david.b@mail.com', '555-0204'),
('IND005', 'Eve Moneypenny', 'Individual', 'eve.m@mail.com', '555-0205'),
('CUST006', 'Foxtrot Systems', 'Business', 'info@foxtrot.sys', '555-0106');


-- 3. Populate DimProduct
INSERT INTO DimProduct (ProductID, ProductName, ProductDescription, Category, Subcategory, Brand, StandardCost, ListPrice, Size, Color) VALUES
('WID-PRO-XL', 'Widget Pro XL', 'Professional Grade Widget, Extra Large', 'Widgets', 'Pro Series', 'WidgetCo', 75.50, 149.99, 'XL', 'Blue'),
('WID-STD-M', 'Widget Standard M', 'Standard Widget, Medium', 'Widgets', 'Standard', 'WidgetCo', 30.00, 59.95, 'M', 'Red'),
('GAD-ADV-S', 'Gadget Advanced S', 'Advanced Gadget, Small', 'Gadgets', 'Advanced', 'GadgetCorp', 120.00, 249.00, 'S', 'Black'),
('GAD-ECO-L', 'Gadget Economy L', 'Economy Gadget, Large', 'Gadgets', 'Economy', 'GadgetCorp', 45.00, 89.99, 'L', 'Green'),
('CMP-A1', 'Alpha Component A1', 'Core component Alpha type 1', 'Components', 'Alpha Series', 'CompSys', 8.25, 19.95, NULL, 'Silver'),
('CMP-B2', 'Beta Component B2', 'Auxiliary component Beta type 2', 'Components', 'Beta Series', 'CompSys', 15.75, 34.50, NULL, 'Gold'),
('SFT-CRM-ENT', 'CRM Suite Enterprise', 'Customer Relationship Management Suite - Enterprise Edition', 'Software', 'Business Suite', 'SoftSol', 500.00, 1999.00, NULL, NULL),
('SFT-IMG-PRO', 'Image Editor Pro', 'Professional Image Editing Software', 'Software', 'Graphics', 'SoftSol', 99.00, 249.99, NULL, NULL),
('ACC-CBL-USB3', 'USB 3.0 Cable', 'Standard USB 3.0 A-to-B Cable, 1m', 'Accessories', 'Cables', 'AccWorld', 2.50, 9.99, '1m', 'Black'),
('ACC-ADP-PWR', 'Universal Power Adapter', 'Multi-region universal power adapter', 'Accessories', 'Adapters', 'AccWorld', 11.00, 29.95, NULL, 'White'),
('WID-PRO-S', 'Widget Pro S', 'Professional Grade Widget, Small', 'Widgets', 'Pro Series', 'WidgetCo', 65.00, 129.99, 'S', 'Blue');


-- 4. Populate DimLocation
INSERT INTO DimLocation (AddressLine1, AddressLine2, City, StateProvince, PostalCode, Country, Region) VALUES
('123 Main St', NULL, 'Plano', 'TX', '75075', 'United States', 'South'),
('456 Corporate Dr', 'Suite 100', 'Dallas', 'TX', '75201', 'United States', 'South'),
('789 Innovation Way', NULL, 'Austin', 'TX', '78701', 'United States', 'South'),
('10 Market St', 'Floor 5', 'San Francisco', 'CA', '94105', 'United States', 'West'),
('22 Business Ave', NULL, 'Los Angeles', 'CA', '90012', 'United States', 'West'),
('55 Commerce Blvd', NULL, 'New York', 'NY', '10001', 'United States', 'East'),
('1 Liberty Pl', 'Ste 2000', 'Philadelphia', 'PA', '19103', 'United States', 'East'),
('33 Tech Park', NULL, 'Seattle', 'WA', '98101', 'United States', 'West'),
('100 King St W', 'PO Box 100', 'Toronto', 'ON', 'M5X 1A9', 'Canada', 'Canada'),
('1 Rue de la Paix', NULL, 'Paris', 'Ile-de-France', '75002', 'France', 'Europe'),
('88 Queen St', NULL, 'London', 'England', 'EC4N 8EL', 'United Kingdom', 'Europe');


-- 5. Populate DimShipper
INSERT INTO DimShipper (ShipperID, ShipperName, ServiceLevel) VALUES
('FDX', 'FedEx', 'Ground'),
('FDX', 'FedEx', 'Priority Overnight'),
('UPS', 'UPS', 'Ground'),
('UPS', 'UPS', 'Next Day Air'),
('USPS', 'US Postal Service', 'Priority Mail'),
('DHL', 'DHL Express', 'Worldwide Express'); -- Note: 6 rows inserted here for variety.


-- 6. Populate FactOrderLines
-- ** REMEMBER THE WARNING: Assumes keys 1, 2, 3... for CUST, PROD, LOC, SHIP **
-- We will use DateKeys defined in Step 1.
INSERT INTO FactOrderLines (OrderDateKey, ShipDateKey, CustomerKey, ProductKey, ShipToLocationKey, ShipperKey, OrderNumber, OrderLineNumber, QuantityOrdered, UnitPrice, DiscountAmount, LineTotalAmount, UnitCost, LineCostAmount) VALUES
-- Order 1 (Acme, Plano, FedEx Ground)
(20240115, 20240115, 1, 2, 1, 1, 'ORD1001', 1, 10, 59.95, 0.00, 599.50, 30.00, 300.00),
(20240115, 20240115, 1, 5, 1, 1, 'ORD1001', 2, 100, 19.95, 19.95, 1975.05, 8.25, 825.00), -- 1% discount item 2
-- Order 2 (Alice, Austin, USPS Priority)
(20240210, 20240211, 6, 8, 3, 5, 'ORD1002', 1, 1, 249.99, 25.00, 224.99, 99.00, 99.00), -- $25 discount
-- Order 3 (Beta Services, SF, UPS Next Day)
(20240305, 20240305, 2, 7, 4, 4, 'ORD1003', 1, 2, 1999.00, 199.90, 3798.10, 500.00, 1000.00), -- 10% discount
-- Order 4 (Bob, LA, UPS Ground)
(20240422, 20240422, 7, 9, 5, 3, 'ORD1004', 1, 5, 9.99, 0.00, 49.95, 2.50, 12.50),
(20240422, 20240422, 7, 10, 5, 3, 'ORD1004', 2, 2, 29.95, 0.00, 59.90, 11.00, 22.00),
-- Order 5 (Charlie Retail, NYC, FedEx P.O.)
(20240518, 20240518, 3, 1, 6, 2, 'ORD1005', 1, 20, 149.99, 299.98, 2699.82, 75.50, 1510.00), -- 10% discount
(20240518, 20240518, 3, 3, 6, 2, 'ORD1005', 2, 15, 249.00, 373.50, 3361.50, 120.00, 1800.00), -- 10% discount
-- Order 6 (Delta Mfg, Seattle, UPS Ground)
(20240630, 20240704, 4, 6, 8, 3, 'ORD1006', 1, 50, 34.50, 0.00, 1725.00, 15.75, 787.50),
-- Order 7 (Carol, Philly, USPS Priority)
(20240819, 20240819, 8, 4, 7, 5, 'ORD1007', 1, 3, 89.99, 5.00, 264.97, 45.00, 135.00), -- $5 discount total
-- Order 8 (Echo Supplies, Toronto, DHL Express)
(20240925, 20240925, 5, 11, 9, 6, 'ORD1008', 1, 30, 129.99, 0.00, 3899.70, 65.00, 1950.00),
-- Order 9 (David, London, DHL Express)
(20241031, 20241111, 9, 8, 11, 6, 'ORD1009', 1, 1, 249.99, 0.00, 249.99, 99.00, 99.00),
-- Order 10 (Foxtrot, Dallas, FedEx Ground)
(20241224, 20241224, 11, 7, 2, 1, 'ORD1010', 1, 1, 1999.00, 0.00, 1999.00, 500.00, 500.00),
-- Order 11 (Acme, Paris, DHL Express) - Repeat customer/product
(20250101, 20250101, 1, 1, 10, 6, 'ORD1011', 1, 5, 149.99, 75.00, 674.95, 75.50, 377.50), -- ~$15 discount per item
-- Order 12 (Eve, Plano, UPS Ground)
(20250403, NULL, 10, 9, 1, 3, 'ORD1012', 1, 20, 9.99, 9.99, 189.81, 2.50, 50.00); -- 5% discount, Not shipped yet


-- ==================================================================
-- Data Population Complete
-- ==================================================================

-- Verify row counts
SELECT COUNT(*) AS DimDateCount FROM DimDate;
SELECT COUNT(*) AS DimCustomerCount FROM DimCustomer;
SELECT COUNT(*) AS DimProductCount FROM DimProduct;
SELECT COUNT(*) AS DimLocationCount FROM DimLocation;
SELECT COUNT(*) AS DimShipperCount FROM DimShipper;
SELECT COUNT(*) AS FactOrderLinesCount FROM FactOrderLines;