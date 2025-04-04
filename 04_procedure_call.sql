
USE OrderDW;

-- 1. Example Call for PopulateDimDate
-- Purpose: Populates the Date dimension table. Typically run once during setup.
SELECT 'Calling PopulateDimDate...' AS Action;
CALL PopulateDimDate('2020-01-01', '2025-12-31');
SELECT 'PopulateDimDate call complete.' AS Status;
-- You can verify with: SELECT COUNT(*) FROM DimDate;


-- 2. Example Call for GetOrCreateCustomerKey
-- Purpose: Simulates getting a surrogate key for a source customer during ETL.
SELECT 'Calling GetOrCreateCustomerKey...' AS Action;
-- Declare a session variable to hold the output key
SET @output_customer_key = NULL;

-- Call the procedure with source customer data
CALL GetOrCreateCustomerKey(
    'CUSTNEW01',                -- p_CustomerID (Natural Key from source)
    'New Customer Inc.',        -- p_CustomerName
    'Retail',                   -- p_CustomerType
    'contact@newcustomer.com',  -- p_Email
    '555-1234',                 -- p_Phone
    @output_customer_key        -- OUT p_CustomerKey (Variable to receive the key)
);

-- Check the returned key (the value will depend on existing data)
SELECT @output_customer_key AS GeneratedCustomerKey;
SELECT 'GetOrCreateCustomerKey call complete.' AS Status;

