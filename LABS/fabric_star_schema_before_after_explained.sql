-- ============================================================
-- MICROSOFT FABRIC DATA WAREHOUSE
-- File: fabric_star_schema_before_after_explained.sql
-- Purpose:
--   1) Build normalized source tables (3NF) - BEFORE state
--   2) Run a BEFORE query directly on normalized tables
--   3) Build star schema tables - AFTER state
--   4) Run the same business question using the star schema
--
-- Fabric compatibility notes:
--   - Use VARCHAR/CHAR instead of NVARCHAR/NCHAR
--   - Do not use DEFAULT in CREATE TABLE
--   - Do not use computed columns in CREATE TABLE
--   - Avoid FORMAT(); use CONVERT(..., 112) for YYYYMMDD keys
-- ============================================================

-- ============================================================
-- STEP 1: DROP EXISTING TABLES (clean slate)
-- ============================================================
DROP TABLE IF EXISTS dbo.FactSales;
DROP TABLE IF EXISTS dbo.DimProduct;
DROP TABLE IF EXISTS dbo.DimCustomer;
DROP TABLE IF EXISTS dbo.DimDate;
DROP TABLE IF EXISTS dbo.DimStore;
DROP TABLE IF EXISTS dbo.DimPromotion;

DROP TABLE IF EXISTS dbo.src_SalesOrderLine;
DROP TABLE IF EXISTS dbo.src_SalesOrder;
DROP TABLE IF EXISTS dbo.src_Promotion;
DROP TABLE IF EXISTS dbo.src_Customer;
DROP TABLE IF EXISTS dbo.src_Store;
DROP TABLE IF EXISTS dbo.src_City;
DROP TABLE IF EXISTS dbo.src_Product;
DROP TABLE IF EXISTS dbo.src_Supplier;
DROP TABLE IF EXISTS dbo.src_Category;

-- ============================================================
-- STEP 2: NORMALIZED SOURCE TABLES (3NF - BEFORE STATE)
-- ============================================================
-- In normalized design, data is split into many small related tables.
-- This reduces duplication, but reporting queries require many joins.

CREATE TABLE dbo.src_Category (
    CategoryID   INT          NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    Department   VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.src_Supplier (
    SupplierID   INT          NOT NULL,
    SupplierName VARCHAR(200) NOT NULL,
    Country      VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.src_Product (
    ProductID   INT           NOT NULL,
    ProductName VARCHAR(200)  NOT NULL,
    CategoryID  INT           NOT NULL,
    SupplierID  INT           NOT NULL,
    UnitCost    DECIMAL(10,2) NOT NULL,
    UnitPrice   DECIMAL(10,2) NOT NULL,
    Brand       VARCHAR(100)  NOT NULL
);

CREATE TABLE dbo.src_City (
    CityID        INT          NOT NULL,
    CityName      VARCHAR(100) NOT NULL,
    StateProvince VARCHAR(100) NOT NULL,
    Country       VARCHAR(100) NOT NULL
);

CREATE TABLE dbo.src_Store (
    StoreID       INT          NOT NULL,
    StoreName     VARCHAR(200) NOT NULL,
    CityID        INT          NOT NULL,
    StoreType     VARCHAR(50)  NOT NULL,
    OpenDate      DATE         NOT NULL,
    SquareFootage INT          NOT NULL
);

CREATE TABLE dbo.src_Customer (
    CustomerID  INT          NOT NULL,
    FirstName   VARCHAR(100) NOT NULL,
    LastName    VARCHAR(100) NOT NULL,
    Email       VARCHAR(200) NOT NULL,
    CityID      INT          NOT NULL,
    LoyaltyTier VARCHAR(50)  NOT NULL,
    BirthYear   INT          NOT NULL,
    Gender      CHAR(1)      NOT NULL
);

CREATE TABLE dbo.src_Promotion (
    PromotionID   INT           NOT NULL,
    PromotionName VARCHAR(200)  NOT NULL,
    DiscountPct   DECIMAL(5,2)  NOT NULL,
    StartDate     DATE          NOT NULL,
    EndDate       DATE          NOT NULL,
    Channel       VARCHAR(100)  NOT NULL
);

CREATE TABLE dbo.src_SalesOrder (
    OrderID     INT  NOT NULL,
    OrderDate   DATE NOT NULL,
    CustomerID  INT  NOT NULL,
    StoreID     INT  NOT NULL,
    PromotionID INT  NULL
);

CREATE TABLE dbo.src_SalesOrderLine (
    OrderLineID INT           NOT NULL,
    OrderID     INT           NOT NULL,
    ProductID   INT           NOT NULL,
    Quantity    INT           NOT NULL,
    UnitPrice   DECIMAL(10,2) NOT NULL,
    Discount    DECIMAL(5,2)  NOT NULL
);

-- ============================================================
-- STEP 3: LOAD SAMPLE DATA INTO SOURCE TABLES
-- ============================================================
INSERT INTO dbo.src_Category VALUES
(1, 'Electronics',   'Technology'),
(2, 'Clothing',      'Apparel'),
(3, 'Home & Garden', 'Living'),
(4, 'Sports',        'Recreation'),
(5, 'Food & Drink',  'Grocery');

INSERT INTO dbo.src_Supplier VALUES
(1, 'TechSource Ltd',      'USA'),
(2, 'FashionForward Co',   'Italy'),
(3, 'HomeEssentials Inc',  'Germany'),
(4, 'SportZone Global',    'China'),
(5, 'FreshFoods Corp',     'USA');

INSERT INTO dbo.src_Product VALUES
(1,  'Wireless Headphones', 1, 1, 45.00,  89.99,  'SoundWave'),
(2,  'Smart Watch',         1, 1, 120.00, 249.99, 'TechGear'),
(3,  'Bluetooth Speaker',   1, 1, 30.00,  59.99,  'SoundWave'),
(4,  'Running Jacket',      2, 2, 25.00,  79.99,  'SpeedWear'),
(5,  'Casual Jeans',        2, 2, 18.00,  49.99,  'DenimCo'),
(6,  'Garden Hose 50ft',    3, 3, 12.00,  34.99,  'GardenPro'),
(7,  'LED Desk Lamp',       3, 3, 15.00,  39.99,  'BrightHome'),
(8,  'Yoga Mat',            4, 4, 10.00,  29.99,  'FlexFit'),
(9,  'Running Shoes',       4, 4, 40.00,  99.99,  'SpeedWear'),
(10, 'Protein Powder 2lb',  5, 5, 18.00,  44.99,  'NutriMax');

INSERT INTO dbo.src_City VALUES
(1, 'New York',    'New York',   'USA'),
(2, 'Los Angeles', 'California', 'USA'),
(3, 'Chicago',     'Illinois',   'USA'),
(4, 'Houston',     'Texas',      'USA'),
(5, 'Miami',       'Florida',    'USA');

INSERT INTO dbo.src_Store VALUES
(1, 'NYC Flagship',     1, 'Flagship',   '2015-03-01', 12000),
(2, 'LA Megastore',     2, 'Megastore',  '2017-06-15', 18000),
(3, 'Chicago Downtown', 3, 'Standard',   '2018-09-01', 8500),
(4, 'Houston Mall',     4, 'Mall Kiosk', '2020-01-10', 3200),
(5, 'Miami Beach',      5, 'Standard',   '2019-11-20', 7800);

INSERT INTO dbo.src_Customer VALUES
(1,  'James',    'Wilson',   'jwilson@email.com',    1, 'Gold',     1985, 'M'),
(2,  'Sophia',   'Martinez', 'smartinez@email.com',  2, 'Platinum', 1990, 'F'),
(3,  'Ethan',    'Brown',    'ebrown@email.com',     3, 'Silver',   1978, 'M'),
(4,  'Olivia',   'Davis',    'odavis@email.com',     4, 'Bronze',   2000, 'F'),
(5,  'Liam',     'Garcia',   'lgarcia@email.com',    5, 'Gold',     1995, 'M'),
(6,  'Emma',     'Taylor',   'etaylor@email.com',    1, 'Platinum', 1988, 'F'),
(7,  'Noah',     'Anderson', 'nanderson@email.com',  2, 'Silver',   1975, 'M'),
(8,  'Ava',      'Thomas',   'athomas@email.com',    3, 'Bronze',   2003, 'F'),
(9,  'Mason',    'Jackson',  'mjackson@email.com',   4, 'Gold',     1993, 'M'),
(10, 'Isabella', 'White',    'iwhite@email.com',     5, 'Silver',   1982, 'F');

INSERT INTO dbo.src_Promotion VALUES
(1, 'Summer Sale',      15.00, '2024-06-01', '2024-08-31', 'In-Store'),
(2, 'Black Friday',     30.00, '2024-11-29', '2024-11-30', 'Online & In-Store'),
(3, 'Loyalty Reward',   10.00, '2024-01-01', '2024-12-31', 'App'),
(4, 'Clearance',        40.00, '2024-07-15', '2024-07-31', 'In-Store'),
(5, 'New Year Kickoff', 20.00, '2024-01-01', '2024-01-07', 'Online');

INSERT INTO dbo.src_SalesOrder VALUES
(1001, '2024-01-03', 1,  1, 5),
(1002, '2024-01-15', 2,  2, NULL),
(1003, '2024-02-20', 3,  3, 3),
(1004, '2024-03-05', 4,  4, NULL),
(1005, '2024-06-12', 5,  5, 1),
(1006, '2024-07-22', 6,  1, 4),
(1007, '2024-08-08', 7,  2, 1),
(1008, '2024-09-18', 8,  3, 3),
(1009, '2024-11-29', 9,  4, 2),
(1010, '2024-12-15', 10, 5, NULL);

INSERT INTO dbo.src_SalesOrderLine VALUES
(1,  1001, 1,  2, 89.99,  0.00),
(2,  1001, 8,  1, 29.99,  0.00),
(3,  1002, 2,  1, 249.99, 0.00),
(4,  1002, 4,  2, 79.99,  0.00),
(5,  1003, 5,  3, 49.99,  10.00),
(6,  1003, 6,  1, 34.99,  10.00),
(7,  1004, 7,  2, 39.99,  0.00),
(8,  1005, 9,  1, 99.99,  15.00),
(9,  1005, 3,  2, 59.99,  15.00),
(10, 1006, 10, 4, 44.99,  40.00),
(11, 1007, 1,  1, 89.99,  15.00),
(12, 1008, 2,  1, 249.99, 10.00),
(13, 1009, 9,  2, 99.99,  30.00),
(14, 1009, 8,  3, 29.99,  30.00),
(15, 1010, 4,  2, 79.99,  0.00);

-- ============================================================
-- STEP 3A: BEFORE STAR SCHEMA QUERY - NORMALIZED 3NF QUERY
-- ============================================================
-- Business question:
--   What is monthly revenue and profit by product category and state?
--
-- In the normalized model, the query must join many tables:
--   OrderLine -> Order -> Product -> Category -> Store -> City
-- This is correct, but less friendly for analysts and BI reporting.

SELECT
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonth,
    c.CategoryName,
    ci.StateProvince,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    SUM(ol.Quantity) AS UnitsSold,
    SUM(ROUND(ol.Quantity * ol.UnitPrice, 2)) AS GrossRevenue,
    SUM(ROUND(ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100), 2)) AS NetRevenue,
    SUM(ROUND((ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100)) - (ol.Quantity * p.UnitCost), 2)) AS GrossProfit
FROM dbo.src_SalesOrderLine ol
JOIN dbo.src_SalesOrder o ON ol.OrderID = o.OrderID
JOIN dbo.src_Product p ON ol.ProductID = p.ProductID
JOIN dbo.src_Category c ON p.CategoryID = c.CategoryID
JOIN dbo.src_Store st ON o.StoreID = st.StoreID
JOIN dbo.src_City ci ON st.CityID = ci.CityID
GROUP BY
    YEAR(o.OrderDate),
    MONTH(o.OrderDate),
    c.CategoryName,
    ci.StateProvince
ORDER BY
    SalesYear,
    SalesMonth,
    NetRevenue DESC;

-- ============================================================
-- STEP 4: BUILD THE STAR SCHEMA - DIMENSION TABLES
-- ============================================================
-- Star schema creates reporting-friendly tables:
--   - Dimensions store descriptive context: Date, Product, Customer, Store, Promotion
--   - Fact table stores business events and numeric measures: Sales

CREATE TABLE dbo.DimDate (
    DateKey       INT          NOT NULL, -- YYYYMMDD key used by the fact table
    FullDate      DATE         NOT NULL,
    DayOfWeek     VARCHAR(10)  NOT NULL,
    DayNumber     INT          NOT NULL,
    WeekNumber    INT          NOT NULL,
    MonthNumber   INT          NOT NULL,
    MonthName     VARCHAR(10)  NOT NULL,
    Quarter       INT          NOT NULL,
    QuarterName   CHAR(2)      NOT NULL,
    Year          INT          NOT NULL,
    IsWeekend     BIT          NOT NULL,
    FiscalYear    INT          NOT NULL,
    FiscalQuarter INT          NOT NULL
);

INSERT INTO dbo.DimDate VALUES
(20240103, '2024-01-03', 'Wednesday', 3,  1,  1,  'January',   1, 'Q1', 2024, 0, 2024, 1),
(20240115, '2024-01-15', 'Monday',    15, 3,  1,  'January',   1, 'Q1', 2024, 0, 2024, 1),
(20240220, '2024-02-20', 'Tuesday',   20, 8,  2,  'February',  1, 'Q1', 2024, 0, 2024, 1),
(20240305, '2024-03-05', 'Tuesday',   5,  10, 3,  'March',     1, 'Q1', 2024, 0, 2024, 1),
(20240612, '2024-06-12', 'Wednesday', 12, 24, 6,  'June',      2, 'Q2', 2024, 0, 2024, 2),
(20240722, '2024-07-22', 'Monday',    22, 30, 7,  'July',      3, 'Q3', 2024, 0, 2024, 3),
(20240808, '2024-08-08', 'Thursday',  8,  32, 8,  'August',    3, 'Q3', 2024, 0, 2024, 3),
(20240918, '2024-09-18', 'Wednesday', 18, 38, 9,  'September', 3, 'Q3', 2024, 0, 2024, 3),
(20241129, '2024-11-29', 'Friday',    29, 48, 11, 'November',  4, 'Q4', 2024, 0, 2024, 4),
(20241215, '2024-12-15', 'Sunday',    15, 51, 12, 'December',  4, 'Q4', 2024, 1, 2024, 4);

CREATE TABLE dbo.DimProduct (
    ProductKey      INT           NOT NULL,
    ProductID       INT           NOT NULL,
    ProductName     VARCHAR(200)  NOT NULL,
    Brand           VARCHAR(100)  NOT NULL,
    CategoryName    VARCHAR(100)  NOT NULL,
    Department      VARCHAR(100)  NOT NULL,
    SupplierName    VARCHAR(200)  NOT NULL,
    SupplierCountry VARCHAR(100)  NOT NULL,
    UnitCost        DECIMAL(10,2) NOT NULL,
    ListPrice       DECIMAL(10,2) NOT NULL,
    GrossMarginPct  DECIMAL(5,2)  NOT NULL
);

-- DimProduct denormalizes Product + Category + Supplier into one reporting table.
INSERT INTO dbo.DimProduct
(ProductKey, ProductID, ProductName, Brand, CategoryName, Department, SupplierName, SupplierCountry, UnitCost, ListPrice, GrossMarginPct)
SELECT
    p.ProductID,
    p.ProductID,
    p.ProductName,
    p.Brand,
    c.CategoryName,
    c.Department,
    s.SupplierName,
    s.Country,
    p.UnitCost,
    p.UnitPrice,
    CAST(((p.UnitPrice - p.UnitCost) / NULLIF(p.UnitPrice, 0) * 100) AS DECIMAL(5,2))
FROM dbo.src_Product p
JOIN dbo.src_Category c ON p.CategoryID = c.CategoryID
JOIN dbo.src_Supplier s ON p.SupplierID = s.SupplierID;

CREATE TABLE dbo.DimCustomer (
    CustomerKey   INT          NOT NULL,
    CustomerID    INT          NOT NULL,
    FullName      VARCHAR(200) NOT NULL,
    Email         VARCHAR(200) NOT NULL,
    Gender        CHAR(1)      NOT NULL,
    BirthYear     INT          NOT NULL,
    AgeGroup      VARCHAR(20)  NOT NULL,
    LoyaltyTier   VARCHAR(50)  NOT NULL,
    City          VARCHAR(100) NOT NULL,
    StateProvince VARCHAR(100) NOT NULL,
    Country       VARCHAR(100) NOT NULL
);

-- DimCustomer denormalizes Customer + City.
INSERT INTO dbo.DimCustomer
(CustomerKey, CustomerID, FullName, Email, Gender, BirthYear, AgeGroup, LoyaltyTier, City, StateProvince, Country)
SELECT
    cu.CustomerID,
    cu.CustomerID,
    CONCAT(cu.FirstName, ' ', cu.LastName),
    cu.Email,
    cu.Gender,
    cu.BirthYear,
    CASE
        WHEN (2024 - cu.BirthYear) < 25 THEN '18-24'
        WHEN (2024 - cu.BirthYear) < 35 THEN '25-34'
        WHEN (2024 - cu.BirthYear) < 45 THEN '35-44'
        WHEN (2024 - cu.BirthYear) < 55 THEN '45-54'
        ELSE '55+'
    END,
    cu.LoyaltyTier,
    ci.CityName,
    ci.StateProvince,
    ci.Country
FROM dbo.src_Customer cu
JOIN dbo.src_City ci ON cu.CityID = ci.CityID;

CREATE TABLE dbo.DimStore (
    StoreKey      INT          NOT NULL,
    StoreID       INT          NOT NULL,
    StoreName     VARCHAR(200) NOT NULL,
    StoreType     VARCHAR(50)  NOT NULL,
    City          VARCHAR(100) NOT NULL,
    StateProvince VARCHAR(100) NOT NULL,
    Country       VARCHAR(100) NOT NULL,
    OpenDate      DATE         NOT NULL,
    SquareFootage INT          NOT NULL,
    SizeCategory  VARCHAR(20)  NOT NULL
);

-- DimStore denormalizes Store + City.
INSERT INTO dbo.DimStore
(StoreKey, StoreID, StoreName, StoreType, City, StateProvince, Country, OpenDate, SquareFootage, SizeCategory)
SELECT
    st.StoreID,
    st.StoreID,
    st.StoreName,
    st.StoreType,
    ci.CityName,
    ci.StateProvince,
    ci.Country,
    st.OpenDate,
    st.SquareFootage,
    CASE
        WHEN st.SquareFootage < 5000 THEN 'Small'
        WHEN st.SquareFootage < 10000 THEN 'Medium'
        ELSE 'Large'
    END
FROM dbo.src_Store st
JOIN dbo.src_City ci ON st.CityID = ci.CityID;

CREATE TABLE dbo.DimPromotion (
    PromotionKey  INT           NOT NULL,
    PromotionID   INT           NOT NULL,
    PromotionName VARCHAR(200)  NOT NULL,
    DiscountPct   DECIMAL(5,2)  NOT NULL,
    DiscountTier  VARCHAR(20)   NOT NULL,
    Channel       VARCHAR(100)  NOT NULL,
    StartDate     DATE          NOT NULL,
    EndDate       DATE          NOT NULL,
    DurationDays  INT           NOT NULL
);

INSERT INTO dbo.DimPromotion
(PromotionKey, PromotionID, PromotionName, DiscountPct, DiscountTier, Channel, StartDate, EndDate, DurationDays)
SELECT
    PromotionID,
    PromotionID,
    PromotionName,
    DiscountPct,
    CASE
        WHEN DiscountPct >= 30 THEN 'High'
        WHEN DiscountPct >= 15 THEN 'Medium'
        ELSE 'Low'
    END,
    Channel,
    StartDate,
    EndDate,
    DATEDIFF(DAY, StartDate, EndDate) + 1
FROM dbo.src_Promotion;

-- ============================================================
-- STEP 5: BUILD THE FACT TABLE
-- ============================================================
-- FactSales stores numeric measures at the grain of one order line.
-- Grain: one row per sales order line.
-- Measures: quantity, revenue, discount, cost, profit.

CREATE TABLE dbo.FactSales (
    SalesKey         BIGINT        NOT NULL,
    DateKey          INT           NOT NULL,
    ProductKey       INT           NOT NULL,
    CustomerKey      INT           NOT NULL,
    StoreKey         INT           NOT NULL,
    PromotionKey     INT           NULL,
    OrderID          INT           NOT NULL, -- Degenerate dimension: useful transaction identifier
    OrderLineID      INT           NOT NULL, -- Degenerate dimension: useful transaction line identifier
    QuantitySold     INT           NOT NULL,
    UnitPrice        DECIMAL(10,2) NOT NULL,
    DiscountPct      DECIMAL(5,2)  NOT NULL,
    DiscountAmount   DECIMAL(10,2) NOT NULL,
    GrossSalesAmount DECIMAL(10,2) NOT NULL,
    NetSalesAmount   DECIMAL(10,2) NOT NULL,
    CostAmount       DECIMAL(10,2) NOT NULL,
    GrossProfit      DECIMAL(10,2) NOT NULL,
    GrossProfitPct   DECIMAL(5,2)  NOT NULL
);

INSERT INTO dbo.FactSales
SELECT
    ROW_NUMBER() OVER (ORDER BY ol.OrderLineID) AS SalesKey,
    CAST(CONVERT(VARCHAR(8), o.OrderDate, 112) AS INT) AS DateKey,
    ol.ProductID AS ProductKey,
    o.CustomerID AS CustomerKey,
    o.StoreID AS StoreKey,
    o.PromotionID AS PromotionKey,
    o.OrderID,
    ol.OrderLineID,
    ol.Quantity AS QuantitySold,
    ol.UnitPrice,
    ol.Discount AS DiscountPct,
    ROUND(ol.Quantity * ol.UnitPrice * (ol.Discount / 100), 2) AS DiscountAmount,
    ROUND(ol.Quantity * ol.UnitPrice, 2) AS GrossSalesAmount,
    ROUND(ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100), 2) AS NetSalesAmount,
    ROUND(ol.Quantity * p.UnitCost, 2) AS CostAmount,
    ROUND((ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100)) - (ol.Quantity * p.UnitCost), 2) AS GrossProfit,
    ROUND((((ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100)) - (ol.Quantity * p.UnitCost))
        / NULLIF((ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100)), 0)) * 100, 2) AS GrossProfitPct
FROM dbo.src_SalesOrderLine ol
JOIN dbo.src_SalesOrder o ON ol.OrderID = o.OrderID
JOIN dbo.src_Product p ON ol.ProductID = p.ProductID;

-- ============================================================
-- STEP 6: AFTER STAR SCHEMA QUERY - SAME BUSINESS QUESTION
-- ============================================================
-- Same question as STEP 3A:
--   What is monthly revenue and profit by product category and state?
--
-- In the star schema, the query is easier:
--   FactSales -> DimDate -> DimProduct -> DimStore
-- The descriptive columns already exist in dimensions.

SELECT
    d.Year AS SalesYear,
    d.MonthNumber AS SalesMonth,
    p.CategoryName,
    s.StateProvince,
    COUNT(DISTINCT f.OrderID) AS TotalOrders,
    SUM(f.QuantitySold) AS UnitsSold,
    SUM(f.GrossSalesAmount) AS GrossRevenue,
    SUM(f.NetSalesAmount) AS NetRevenue,
    SUM(f.GrossProfit) AS GrossProfit
FROM dbo.FactSales f
JOIN dbo.DimDate d ON f.DateKey = d.DateKey
JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
JOIN dbo.DimStore s ON f.StoreKey = s.StoreKey
GROUP BY
    d.Year,
    d.MonthNumber,
    p.CategoryName,
    s.StateProvince
ORDER BY
    SalesYear,
    SalesMonth,
    NetRevenue DESC;

-- ============================================================
-- STEP 7: EXTRA STAR SCHEMA ANALYTICAL QUERIES
-- ============================================================

-- Q1: Monthly revenue and profit summary
SELECT
    d.Year,
    d.MonthName,
    d.MonthNumber,
    COUNT(DISTINCT f.OrderID) AS TotalOrders,
    SUM(f.QuantitySold) AS UnitsSold,
    SUM(f.GrossSalesAmount) AS GrossRevenue,
    SUM(f.NetSalesAmount) AS NetRevenue,
    SUM(f.GrossProfit) AS GrossProfit,
    ROUND(SUM(f.GrossProfit) / NULLIF(SUM(f.NetSalesAmount), 0) * 100, 1) AS ProfitMarginPct
FROM dbo.FactSales f
JOIN dbo.DimDate d ON f.DateKey = d.DateKey
GROUP BY d.Year, d.MonthName, d.MonthNumber
ORDER BY d.Year, d.MonthNumber;

-- Q2: Top 5 products by net revenue
SELECT TOP 5
    p.ProductName,
    p.CategoryName,
    p.Brand,
    SUM(f.QuantitySold) AS UnitsSold,
    SUM(f.NetSalesAmount) AS NetRevenue,
    SUM(f.GrossProfit) AS GrossProfit,
    ROUND(AVG(f.GrossProfitPct), 1) AS AvgMarginPct
FROM dbo.FactSales f
JOIN dbo.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductName, p.CategoryName, p.Brand
ORDER BY NetRevenue DESC;

-- Q3: Promotion effectiveness
SELECT
    COALESCE(pr.PromotionName, 'No Promotion') AS Promotion,
    COALESCE(pr.Channel, 'N/A') AS Channel,
    COALESCE(pr.DiscountTier, 'N/A') AS DiscountTier,
    COUNT(DISTINCT f.OrderID) AS Orders,
    SUM(f.DiscountAmount) AS TotalDiscountGiven,
    SUM(f.NetSalesAmount) AS NetRevenue,
    SUM(f.GrossProfit) AS GrossProfit
FROM dbo.FactSales f
LEFT JOIN dbo.DimPromotion pr ON f.PromotionKey = pr.PromotionKey
GROUP BY pr.PromotionName, pr.Channel, pr.DiscountTier
ORDER BY NetRevenue DESC;

-- ============================================================
-- LEARNING SUMMARY
-- ============================================================
-- BEFORE / 3NF:
--   - Good for operational systems and data integrity
--   - Reporting requires many joins
--   - Business columns are spread across multiple tables
--
-- AFTER / STAR SCHEMA:
--   - Good for analytics and BI tools such as Power BI
--   - Fact table stores measures
--   - Dimension tables store business descriptions
--   - Queries are simpler and easier for analysts
-- ============================================================
