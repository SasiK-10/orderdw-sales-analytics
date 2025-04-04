-- Drop the database if it already exists to ensure a clean start
DROP DATABASE IF EXISTS OrderDW;

-- Create the new database
CREATE DATABASE OrderDW;

-- Switch to the newly created database context
USE OrderDW;

-- Set default character set and collation (optional but recommended)
ALTER DATABASE OrderDW CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==================================================================
-- Dimension Table: DimDate
-- Stores date attributes for slicing and dicing facts by time.
-- ==================================================================
CREATE TABLE IF NOT EXISTS DimDate (
    DateKey INT PRIMARY KEY COMMENT 'Surrogate key for the date dimension (e.g., YYYYMMDD)',
    FullDate DATE NOT NULL COMMENT 'Actual date value',
    DayNumberOfWeek TINYINT NOT NULL COMMENT 'Day number within the week (e.g., 1=Sunday, 7=Saturday)',
    DayNameOfWeek VARCHAR(10) NOT NULL COMMENT 'Name of the day (e.g., Sunday, Monday)',
    DayNumberOfMonth TINYINT NOT NULL COMMENT 'Day number within the month (1-31)',
    DayNumberOfYear SMALLINT NOT NULL COMMENT 'Day number within the year (1-366)',
    WeekNumberOfYear TINYINT NOT NULL COMMENT 'Week number within the year (ISO 8601 standard often preferred)',
    MonthName VARCHAR(10) NOT NULL COMMENT 'Name of the month (e.g., January, February)',
    MonthNumberOfYear TINYINT NOT NULL COMMENT 'Month number within the year (1-12)',
    CalendarQuarter TINYINT NOT NULL COMMENT 'Calendar quarter (1-4)',
    CalendarYear SMALLINT NOT NULL COMMENT 'Calendar year (e.g., 2024)',
    IsWeekend BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'True if the day is a Saturday or Sunday, False otherwise',
    UNIQUE INDEX idx_DimDate_FullDate (FullDate) COMMENT 'Ensure date uniqueness and fast lookup by date'
) COMMENT = 'Dimension table storing date attributes for analysis.';

-- ==================================================================
-- Dimension Table: DimCustomer
-- Stores descriptive attributes about customers.
-- ==================================================================
CREATE TABLE IF NOT EXISTS DimCustomer (
    CustomerKey INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key for the customer dimension',
    CustomerID VARCHAR(50) NOT NULL COMMENT 'Natural key from the source system (e.g., CRM ID)',
    CustomerName VARCHAR(255) NOT NULL COMMENT 'Full name or company name of the customer',
    CustomerType VARCHAR(50) COMMENT 'Type or category of the customer (e.g., Retail, Wholesale)',
    Email VARCHAR(255) COMMENT 'Customer email address',
    Phone VARCHAR(30) COMMENT 'Customer phone number',
    -- Add SCD Type 2 attributes below if history tracking is needed later
    -- EffectiveStartDate DATE NOT NULL,
    -- EffectiveEndDate DATE,
    -- IsCurrent BOOLEAN NOT NULL DEFAULT TRUE,
    INDEX idx_DimCustomer_CustomerID (CustomerID) COMMENT 'Index on the natural key for lookups during ETL'
) COMMENT = 'Dimension table storing customer attributes.';

-- ==================================================================
-- Dimension Table: DimProduct
-- Stores descriptive attributes about products.
-- ==================================================================
CREATE TABLE IF NOT EXISTS DimProduct (
    ProductKey INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key for the product dimension',
    ProductID VARCHAR(50) NOT NULL COMMENT 'Natural key from the source system (e.g., SKU)',
    ProductName VARCHAR(255) NOT NULL COMMENT 'Name of the product',
    ProductDescription TEXT COMMENT 'Detailed description of the product',
    Category VARCHAR(100) COMMENT 'Product category',
    Subcategory VARCHAR(100) COMMENT 'Product subcategory',
    Brand VARCHAR(100) COMMENT 'Product brand',
    StandardCost DECIMAL(18, 4) COMMENT 'Standard cost of the product',
    ListPrice DECIMAL(18, 4) COMMENT 'Manufacturer Suggested Retail Price (MSRP) or list price',
    Size VARCHAR(20) COMMENT 'Product size',
    Color VARCHAR(30) COMMENT 'Product color',
    -- Add SCD Type 2 attributes below if history tracking is needed later
    -- EffectiveStartDate DATE NOT NULL,
    -- EffectiveEndDate DATE,
    -- IsCurrent BOOLEAN NOT NULL DEFAULT TRUE,
    INDEX idx_DimProduct_ProductID (ProductID) COMMENT 'Index on the natural key for lookups during ETL'
) COMMENT = 'Dimension table storing product attributes.';

-- ==================================================================
-- Dimension Table: DimLocation
-- Stores descriptive attributes about geographic locations.
-- ==================================================================
CREATE TABLE IF NOT EXISTS DimLocation (
    LocationKey INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key for the location dimension',
    AddressLine1 VARCHAR(255) NOT NULL COMMENT 'Street address line 1',
    AddressLine2 VARCHAR(255) COMMENT 'Street address line 2',
    City VARCHAR(100) NOT NULL COMMENT 'City name',
    StateProvince VARCHAR(100) NOT NULL COMMENT 'State or Province name',
    PostalCode VARCHAR(20) NOT NULL COMMENT 'Postal or ZIP code',
    Country VARCHAR(100) NOT NULL COMMENT 'Country name',
    Region VARCHAR(100) COMMENT 'Sales region or territory',
    UNIQUE INDEX idx_DimLocation_Address (AddressLine1, City, StateProvince, PostalCode, Country)
) COMMENT = 'Dimension table storing geographic location attributes.';

-- ==================================================================
-- Dimension Table: DimShipper
-- Stores descriptive attributes about shipping carriers or methods.
-- ==================================================================
CREATE TABLE IF NOT EXISTS DimShipper (
    ShipperKey INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate key for the shipper dimension',
    ShipperID VARCHAR(50) NOT NULL COMMENT 'Natural key from the source system (e.g., Carrier Code)',
    ShipperName VARCHAR(100) NOT NULL COMMENT 'Name of the shipping company (e.g., UPS, FedEx, USPS)',
    ServiceLevel VARCHAR(100) COMMENT 'Shipping service level (e.g., Ground, Next Day Air)',
    INDEX idx_DimShipper_ShipperID (ShipperID) COMMENT 'Index on the natural key for lookups during ETL'
) COMMENT = 'Dimension table storing shipper/carrier attributes.';

-- ==================================================================
-- Fact Table: FactOrderLines
-- Central table containing measures related to order line items.
-- ==================================================================
CREATE TABLE IF NOT EXISTS FactOrderLines (
    OrderLineKey BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Surrogate primary key for the fact table row (optional but good practice)',

    -- Foreign Keys to Dimension Tables
    OrderDateKey INT NOT NULL COMMENT 'FK to DimDate, representing the date the order was placed',
    ShipDateKey INT COMMENT 'FK to DimDate, representing the date the line item was shipped (can be NULL if not yet shipped)',
    CustomerKey INT NOT NULL COMMENT 'FK to DimCustomer',
    ProductKey INT NOT NULL COMMENT 'FK to DimProduct',
    ShipToLocationKey INT NOT NULL COMMENT 'FK to DimLocation, representing the shipping address',
    ShipperKey INT COMMENT 'FK to DimShipper (can be NULL if not yet shipped or shipper unknown)',

    -- Degenerate Dimensions
    OrderNumber VARCHAR(50) NOT NULL COMMENT 'Operational order number from the source system',
    OrderLineNumber INT NOT NULL COMMENT 'Line number within the specific order',

    -- Measures (Facts)
    QuantityOrdered INT NOT NULL COMMENT 'Number of units ordered for this line item',
    UnitPrice DECIMAL(18, 4) NOT NULL COMMENT 'Price per unit before discount',
    DiscountAmount DECIMAL(18, 4) NOT NULL DEFAULT 0.00 COMMENT 'Total discount amount applied to this line item',
    LineTotalAmount DECIMAL(18, 4) NOT NULL COMMENT 'Total amount for this line item (Quantity * UnitPrice - DiscountAmount)',
    UnitCost DECIMAL(18, 4) COMMENT 'Cost per unit for this product at the time of order/shipment',
    LineCostAmount DECIMAL(18, 4) COMMENT 'Total cost for this line item (Quantity * UnitCost)',

    -- Foreign Key Constraints
    CONSTRAINT fk_FactOrderLines_DimDate_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES DimDate (DateKey) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_FactOrderLines_DimDate_ShipDate FOREIGN KEY (ShipDateKey) REFERENCES DimDate (DateKey) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_FactOrderLines_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES DimCustomer (CustomerKey) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_FactOrderLines_DimProduct FOREIGN KEY (ProductKey) REFERENCES DimProduct (ProductKey) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_FactOrderLines_DimLocation_ShipTo FOREIGN KEY (ShipToLocationKey) REFERENCES DimLocation (LocationKey) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_FactOrderLines_DimShipper FOREIGN KEY (ShipperKey) REFERENCES DimShipper (ShipperKey) ON DELETE SET NULL ON UPDATE CASCADE,

    -- Indexing Foreign Keys for join performance
    INDEX idx_FactOrderLines_OrderDateKey (OrderDateKey),
    INDEX idx_FactOrderLines_ShipDateKey (ShipDateKey),
    INDEX idx_FactOrderLines_CustomerKey (CustomerKey),
    INDEX idx_FactOrderLines_ProductKey (ProductKey),
    INDEX idx_FactOrderLines_ShipToLocationKey (ShipToLocationKey),
    INDEX idx_FactOrderLines_ShipperKey (ShipperKey),

    -- Indexing Degenerate Dimensions if frequently used for filtering/lookup
    INDEX idx_FactOrderLines_OrderNumber (OrderNumber, OrderLineNumber)

) COMMENT = 'Fact table containing measures related to individual order line items.';

-- Switch to the OrderDW database context if running separately
USE OrderDW;

-- -----------------------------------------------------------------
-- Audit Table for FactOrderLines
-- -----------------------------------------------------------------
-- Purpose: To log INSERT actions performed on the FactOrderLines table,
--          as captured by the example trigger trg_FactOrderLines_Audit_AfterInsert.
-- Prerequisite: Must exist before creating and enabling the trigger.
-- -----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS FactOrderLinesAuditLog (
    AuditLogID BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Primary key for the audit log entry',
    AuditTimestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when the audit record was created',
    AuditUser VARCHAR(100) NOT NULL COMMENT 'User or process that performed the action (e.g., from USER() function)',
    ActionType VARCHAR(10) NOT NULL COMMENT 'Type of action logged (e.g., INSERT, UPDATE, DELETE)',

    -- Columns copied from FactOrderLines at the time of the event
    OrderLineKey BIGINT NOT NULL COMMENT 'The OrderLineKey from FactOrderLines that was affected',
    OrderNumber VARCHAR(50) NOT NULL COMMENT 'Degenerate dimension from FactOrderLines',
    OrderLineNumber INT NOT NULL COMMENT 'Degenerate dimension from FactOrderLines',
    CustomerKey INT NOT NULL COMMENT 'FK to DimCustomer from FactOrderLines',
    ProductKey INT NOT NULL COMMENT 'FK to DimProduct from FactOrderLines',
    QuantityOrdered INT NOT NULL COMMENT 'Measure from FactOrderLines',
    LineTotalAmount DECIMAL(18, 4) NOT NULL COMMENT 'Measure from FactOrderLines',

    -- Add other columns from FactOrderLines if needed for audit purposes

    -- Indexing for common audit queries
    INDEX idx_AuditTimestamp (AuditTimestamp),
    INDEX idx_Audit_OrderLineKey (OrderLineKey) COMMENT 'To find history for a specific fact record'

) COMMENT = 'Audit trail log for changes to the FactOrderLines table.';

-- -----------------------------------------------------------------
-- Triggers (Example - Use with Caution)
-- -----------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_FactOrderLines_Audit_AfterInsert;
 -- Uncomment to create the trigger (Ensure FactOrderLinesAuditLog table exists)
DELIMITER //
CREATE TRIGGER trg_FactOrderLines_Audit_AfterInsert
AFTER INSERT ON FactOrderLines
FOR EACH ROW
BEGIN
    -- Example: Log inserts into a separate audit table
    INSERT INTO FactOrderLinesAuditLog (
        AuditTimestamp, AuditUser, ActionType,
        OrderLineKey, OrderNumber, OrderLineNumber, CustomerKey, ProductKey, QuantityOrdered, LineTotalAmount
    ) VALUES (
        CURRENT_TIMESTAMP, USER(), 'INSERT',
        NEW.OrderLineKey, NEW.OrderNumber, NEW.OrderLineNumber, NEW.CustomerKey, NEW.ProductKey, NEW.QuantityOrdered, NEW.LineTotalAmount
    );
END //
DELIMITER ;

