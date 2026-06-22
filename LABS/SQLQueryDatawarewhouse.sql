-- ============================================================
-- MICROSOFT FABRIC DATA WAREHOUSE
-- Star Schema: Retail Sales
-- From: Normalized (3NF) → Star Schema
-- Tables: 1 Fact + 5 Dimensions (6 total)
-- ============================================================

-- ============================================================
-- STEP 1: DROP EXISTING TABLES (clean slate)
-- ============================================================

IF OBJECT_ID('dbo.FactSales',        'U') IS NOT NULL DROP TABLE dbo.FactSales;
IF OBJECT_ID('dbo.DimProduct',       'U') IS NOT NULL DROP TABLE dbo.DimProduct;
IF OBJECT_ID('dbo.DimCustomer',      'U') IS NOT NULL DROP TABLE dbo.DimCustomer;
IF OBJECT_ID('dbo.DimDate',          'U') IS NOT NULL DROP TABLE dbo.DimDate;
IF OBJECT_ID('dbo.DimStore',         'U') IS NOT NULL DROP TABLE dbo.DimStore;
IF OBJECT_ID('dbo.DimPromotion',     'U') IS NOT NULL DROP TABLE dbo.DimPromotion;

-- ============================================================
-- STEP 2: NORMALIZED SOURCE TABLES (3NF — the "before" state)
-- ============================================================

-- --- SOURCE: Categories ---
CREATE TABLE dbo.src_Category (
    CategoryID   INT           NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    Department   NVARCHAR(100) NOT NULL
);

-- --- SOURCE: Suppliers ---
CREATE TABLE dbo.src_Supplier (
    SupplierID   INT           NOT NULL,
    SupplierName NVARCHAR(200) NOT NULL,
    Country      NVARCHAR(100) NOT NULL
);

-- --- SOURCE: Products (normalized — FK to Category & Supplier) ---
CREATE TABLE dbo.src_Product (
    ProductID    INT           NOT NULL,
    ProductName  NVARCHAR(200) NOT NULL,
    CategoryID   INT           NOT NULL,
    SupplierID   INT           NOT NULL,
    UnitCost     DECIMAL(10,2) NOT NULL,
    UnitPrice    DECIMAL(10,2) NOT NULL,
    Brand        NVARCHAR(100) NOT NULL
);

-- --- SOURCE: Cities ---
CREATE TABLE dbo.src_City (
    CityID       INT           NOT NULL,
    CityName     NVARCHAR(100) NOT NULL,
    StateProvince NVARCHAR(100) NOT NULL,
    Country      NVARCHAR(100) NOT NULL
);

-- --- SOURCE: Stores (normalized — FK to City) ---
CREATE TABLE dbo.src_Store (
    StoreID      INT           NOT NULL,
    StoreName    NVARCHAR(200) NOT NULL,
    CityID       INT           NOT NULL,
    StoreType    NVARCHAR(50)  NOT NULL,
    OpenDate     DATE          NOT NULL,
    SquareFootage INT          NOT NULL
);

-- --- SOURCE: Customers (normalized — FK to City) ---
CREATE TABLE dbo.src_Customer (
    CustomerID   INT           NOT NULL,
    FirstName    NVARCHAR(100) NOT NULL,
    LastName     NVARCHAR(100) NOT NULL,
    Email        NVARCHAR(200) NOT NULL,
    CityID       INT           NOT NULL,
    LoyaltyTier  NVARCHAR(50)  NOT NULL,
    BirthYear    INT           NOT NULL,
    Gender       NCHAR(1)      NOT NULL
);

-- --- SOURCE: Promotions ---
CREATE TABLE dbo.src_Promotion (
    PromotionID   INT           NOT NULL,
    PromotionName NVARCHAR(200) NOT NULL,
    DiscountPct   DECIMAL(5,2)  NOT NULL,
    StartDate     DATE          NOT NULL,
    EndDate       DATE          NOT NULL,
    Channel       NVARCHAR(100) NOT NULL
);

-- --- SOURCE: Sales Orders (normalized — many FKs) ---
CREATE TABLE dbo.src_SalesOrder (
    OrderID      INT           NOT NULL,
    OrderDate    DATE          NOT NULL,
    CustomerID   INT           NOT NULL,
    StoreID      INT           NOT NULL,
    PromotionID  INT           NULL
);

-- --- SOURCE: Sales Order Lines ---
CREATE TABLE dbo.src_SalesOrderLine (
    OrderLineID  INT           NOT NULL,
    OrderID      INT           NOT NULL,
    ProductID    INT           NOT NULL,
    Quantity     INT           NOT NULL,
    UnitPrice    DECIMAL(10,2) NOT NULL,
    Discount     DECIMAL(5,2)  NOT NULL DEFAULT 0
);

-- ============================================================
-- STEP 3: LOAD SAMPLE DATA INTO SOURCE TABLES
-- ============================================================

-- Categories
INSERT INTO dbo.src_Category VALUES
(1, 'Electronics',   'Technology'),
(2, 'Clothing',      'Apparel'),
(3, 'Home & Garden', 'Living'),
(4, 'Sports',        'Recreation'),
(5, 'Food & Drink',  'Grocery');

-- Suppliers
INSERT INTO dbo.src_Supplier VALUES
(1, 'TechSource Ltd',      'USA'),
(2, 'FashionForward Co',   'Italy'),
(3, 'HomeEssentials Inc',  'Germany'),
(4, 'SportZone Global',    'China'),
(5, 'FreshFoods Corp',     'USA');

-- Products
INSERT INTO dbo.src_Product VALUES
(1,  'Wireless Headphones',   1, 1, 45.00,  89.99,  'SoundWave'),
(2,  'Smart Watch',           1, 1, 120.00, 249.99, 'TechGear'),
(3,  'Bluetooth Speaker',     1, 1, 30.00,  59.99,  'SoundWave'),
(4,  'Running Jacket',        2, 2, 25.00,  79.99,  'SpeedWear'),
(5,  'Casual Jeans',          2, 2, 18.00,  49.99,  'DenimCo'),
(6,  'Garden Hose 50ft',      3, 3, 12.00,  34.99,  'GardenPro'),
(7,  'LED Desk Lamp',         3, 3, 15.00,  39.99,  'BrightHome'),
(8,  'Yoga Mat',              4, 4, 10.00,  29.99,  'FlexFit'),
(9,  'Running Shoes',         4, 4, 40.00,  99.99,  'SpeedWear'),
(10, 'Protein Powder 2lb',    5, 5, 18.00,  44.99,  'NutriMax');

-- Cities
INSERT INTO dbo.src_City VALUES
(1, 'New York',    'New York',   'USA'),
(2, 'Los Angeles', 'California', 'USA'),
(3, 'Chicago',     'Illinois',   'USA'),
(4, 'Houston',     'Texas',      'USA'),
(5, 'Miami',       'Florida',    'USA');

-- Stores
INSERT INTO dbo.src_Store VALUES
(1, 'NYC Flagship',    1, 'Flagship',    '2015-03-01', 12000),
(2, 'LA Megastore',    2, 'Megastore',   '2017-06-15', 18000),
(3, 'Chicago Downtown',3, 'Standard',    '2018-09-01',  8500),
(4, 'Houston Mall',    4, 'Mall Kiosk',  '2020-01-10',  3200),
(5, 'Miami Beach',     5, 'Standard',    '2019-11-20',  7800);

-- Customers
INSERT INTO dbo.src_Customer VALUES
(1,  'James',   'Wilson',  'jwilson@email.com',  1, 'Gold',     1985, 'M'),
(2,  'Sophia',  'Martinez','smartinez@email.com', 2, 'Platinum', 1990, 'F'),
(3,  'Ethan',   'Brown',   'ebrown@email.com',   3, 'Silver',   1978, 'M'),
(4,  'Olivia',  'Davis',   'odavis@email.com',   4, 'Bronze',   2000, 'F'),
(5,  'Liam',    'Garcia',  'lgarcia@email.com',  5, 'Gold',     1995, 'M'),
(6,  'Emma',    'Taylor',  'etaylor@email.com',  1, 'Platinum', 1988, 'F'),
(7,  'Noah',    'Anderson','nanderson@email.com', 2, 'Silver',   1975, 'M'),
(8,  'Ava',     'Thomas',  'athomas@email.com',  3, 'Bronze',   2003, 'F'),
(9,  'Mason',   'Jackson', 'mjackson@email.com', 4, 'Gold',     1993, 'M'),
(10, 'Isabella','White',   'iwhite@email.com',   5, 'Silver',   1982, 'F');

-- Promotions
INSERT INTO dbo.src_Promotion VALUES
(1, 'Summer Sale',       15.00, '2024-06-01', '2024-08-31', 'In-Store'),
(2, 'Black Friday',      30.00, '2024-11-29', '2024-11-30', 'Online & In-Store'),
(3, 'Loyalty Reward',    10.00, '2024-01-01', '2024-12-31', 'App'),
(4, 'Clearance',         40.00, '2024-07-15', '2024-07-31', 'In-Store'),
(5, 'New Year Kickoff',  20.00, '2024-01-01', '2024-01-07', 'Online');

-- Sales Orders
INSERT INTO dbo.src_SalesOrder VALUES
(1001, '2024-01-03', 1, 1, 5),
(1002, '2024-01-15', 2, 2, NULL),
(1003, '2024-02-20', 3, 3, 3),
(1004, '2024-03-05', 4, 4, NULL),
(1005, '2024-06-12', 5, 5, 1),
(1006, '2024-07-22', 6, 1, 4),
(1007, '2024-08-08', 7, 2, 1),
(1008, '2024-09-18', 8, 3, 3),
(1009, '2024-11-29', 9, 4, 2),
(1010, '2024-12-15', 10, 5, NULL);

-- Sales Order Lines
INSERT INTO dbo.src_SalesOrderLine VALUES
(1, 1001, 1,  2, 89.99, 0.00),
(2, 1001, 8,  1, 29.99, 0.00),
(3, 1002, 2,  1, 249.99,0.00),
(4, 1002, 4,  2, 79.99, 0.00),
(5, 1003, 5,  3, 49.99, 10.00),
(6, 1003, 6,  1, 34.99, 10.00),
(7, 1004, 7,  2, 39.99, 0.00),
(8, 1005, 9,  1, 99.99, 15.00),
(9, 1005, 3,  2, 59.99, 15.00),
(10,1006, 10, 4, 44.99, 40.00),
(11,1007, 1,  1, 89.99, 15.00),
(12,1008, 2,  1, 249.99,10.00),
(13,1009, 9,  2, 99.99, 30.00),
(14,1009, 8,  3, 29.99, 30.00),
(15,1010, 4,  2, 79.99, 0.00);

-- ============================================================
-- STEP 4: BUILD THE STAR SCHEMA — DIMENSION TABLES
-- ============================================================

-- -------------------------------------------------------
-- DIM 1: DimDate  (Date dimension — no FK to source)
-- -------------------------------------------------------
CREATE TABLE dbo.DimDate (
    DateKey        INT           NOT NULL,   -- Surrogate key: YYYYMMDD
    FullDate       DATE          NOT NULL,
    DayOfWeek      NVARCHAR(10)  NOT NULL,
    DayNumber      INT           NOT NULL,
    WeekNumber     INT           NOT NULL,
    MonthNumber    INT           NOT NULL,
    MonthName      NVARCHAR(10)  NOT NULL,
    Quarter        INT           NOT NULL,
    QuarterName    NCHAR(2)      NOT NULL,
    Year           INT           NOT NULL,
    IsWeekend      BIT           NOT NULL,
    FiscalYear     INT           NOT NULL,
    FiscalQuarter  INT           NOT NULL
);

INSERT INTO dbo.DimDate VALUES
(20240103, '2024-01-03', 'Wednesday', 3,  1,  1, 'January',   1, 'Q1', 2024, 0, 2024, 1),
(20240115, '2024-01-15', 'Monday',   15,  3,  1, 'January',   1, 'Q1', 2024, 0, 2024, 1),
(20240220, '2024-02-20', 'Tuesday',  20,  8,  2, 'February',  1, 'Q1', 2024, 0, 2024, 1),
(20240305, '2024-03-05', 'Tuesday',   5, 10,  3, 'March',     1, 'Q1', 2024, 0, 2024, 1),
(20240612, '2024-06-12', 'Wednesday',12, 24,  6, 'June',      2, 'Q2', 2024, 0, 2024, 2),
(20240722, '2024-07-22', 'Monday',   22, 30,  7, 'July',      3, 'Q3', 2024, 0, 2024, 3),
(20240808, '2024-08-08', 'Thursday',  8, 32,  8, 'August',    3, 'Q3', 2024, 0, 2024, 3),
(20240918, '2024-09-18', 'Wednesday',18, 38,  9, 'September', 3, 'Q3', 2024, 0, 2024, 3),
(20241129, '2024-11-29', 'Friday',   29, 48, 11, 'November',  4, 'Q4', 2024, 0, 2024, 4),
(20241215, '2024-12-15', 'Sunday',   15, 51, 12, 'December',  4, 'Q4', 2024, 1, 2024, 4);

-- -------------------------------------------------------
-- DIM 2: DimProduct  (denormalized — merged Category+Supplier)
-- -------------------------------------------------------
CREATE TABLE dbo.DimProduct (
    ProductKey       INT           NOT NULL,   -- Surrogate key
    ProductID        INT           NOT NULL,   -- Business key
    ProductName      NVARCHAR(200) NOT NULL,
    Brand            NVARCHAR(100) NOT NULL,
    CategoryName     NVARCHAR(100) NOT NULL,
    Department       NVARCHAR(100) NOT NULL,
    SupplierName     NVARCHAR(200) NOT NULL,
    SupplierCountry  NVARCHAR(100) NOT NULL,
    UnitCost         DECIMAL(10,2) NOT NULL,
    ListPrice        DECIMAL(10,2) NOT NULL,
    GrossMarginPct   AS (CAST(((ListPrice - UnitCost) / ListPrice * 100) AS DECIMAL(5,2)))
);

INSERT INTO dbo.DimProduct (ProductKey, ProductID, ProductName, Brand, CategoryName, Department, SupplierName, SupplierCountry, UnitCost, ListPrice)
SELECT
    p.ProductID       AS ProductKey,
    p.ProductID,
    p.ProductName,
    p.Brand,
    c.CategoryName,
    c.Department,
    s.SupplierName,
    s.Country         AS SupplierCountry,
    p.UnitCost,
    p.UnitPrice       AS ListPrice
FROM dbo.src_Product   p
JOIN dbo.src_Category  c ON p.CategoryID = c.CategoryID
JOIN dbo.src_Supplier  s ON p.SupplierID = s.SupplierID;

-- -------------------------------------------------------
-- DIM 3: DimCustomer  (denormalized — merged City)
-- -------------------------------------------------------
CREATE TABLE dbo.DimCustomer (
    CustomerKey    INT           NOT NULL,   -- Surrogate key
    CustomerID     INT           NOT NULL,   -- Business key
    FullName       NVARCHAR(200) NOT NULL,
    Email          NVARCHAR(200) NOT NULL,
    Gender         NCHAR(1)      NOT NULL,
    BirthYear      INT           NOT NULL,
    AgeGroup       NVARCHAR(20)  NOT NULL,
    LoyaltyTier    NVARCHAR(50)  NOT NULL,
    City           NVARCHAR(100) NOT NULL,
    StateProvince  NVARCHAR(100) NOT NULL,
    Country        NVARCHAR(100) NOT NULL
);

INSERT INTO dbo.DimCustomer (CustomerKey, CustomerID, FullName, Email, Gender, BirthYear, AgeGroup, LoyaltyTier, City, StateProvince, Country)
SELECT
    cu.CustomerID    AS CustomerKey,
    cu.CustomerID,
    cu.FirstName + ' ' + cu.LastName AS FullName,
    cu.Email,
    cu.Gender,
    cu.BirthYear,
    CASE
        WHEN (2024 - cu.BirthYear) < 25 THEN '18–24'
        WHEN (2024 - cu.BirthYear) < 35 THEN '25–34'
        WHEN (2024 - cu.BirthYear) < 45 THEN '35–44'
        WHEN (2024 - cu.BirthYear) < 55 THEN '45–54'
        ELSE '55+'
    END AS AgeGroup,
    cu.LoyaltyTier,
    ci.CityName      AS City,
    ci.StateProvince,
    ci.Country
FROM dbo.src_Customer cu
JOIN dbo.src_City     ci ON cu.CityID = ci.CityID;

-- -------------------------------------------------------
-- DIM 4: DimStore  (denormalized — merged City)
-- -------------------------------------------------------
CREATE TABLE dbo.DimStore (
    StoreKey       INT           NOT NULL,   -- Surrogate key
    StoreID        INT           NOT NULL,   -- Business key
    StoreName      NVARCHAR(200) NOT NULL,
    StoreType      NVARCHAR(50)  NOT NULL,
    City           NVARCHAR(100) NOT NULL,
    StateProvince  NVARCHAR(100) NOT NULL,
    Country        NVARCHAR(100) NOT NULL,
    OpenDate       DATE          NOT NULL,
    SquareFootage  INT           NOT NULL,
    SizeCategory   NVARCHAR(20)  NOT NULL
);

INSERT INTO dbo.DimStore (StoreKey, StoreID, StoreName, StoreType, City, StateProvince, Country, OpenDate, SquareFootage, SizeCategory)
SELECT
    st.StoreID    AS StoreKey,
    st.StoreID,
    st.StoreName,
    st.StoreType,
    ci.CityName   AS City,
    ci.StateProvince,
    ci.Country,
    st.OpenDate,
    st.SquareFootage,
    CASE
        WHEN st.SquareFootage < 5000  THEN 'Small'
        WHEN st.SquareFootage < 10000 THEN 'Medium'
        ELSE 'Large'
    END AS SizeCategory
FROM dbo.src_Store st
JOIN dbo.src_City  ci ON st.CityID = ci.CityID;

-- -------------------------------------------------------
-- DIM 5: DimPromotion
-- -------------------------------------------------------
CREATE TABLE dbo.DimPromotion (
    PromotionKey   INT           NOT NULL,   -- Surrogate key
    PromotionID    INT           NOT NULL,   -- Business key
    PromotionName  NVARCHAR(200) NOT NULL,
    DiscountPct    DECIMAL(5,2)  NOT NULL,
    DiscountTier   NVARCHAR(20)  NOT NULL,
    Channel        NVARCHAR(100) NOT NULL,
    StartDate      DATE          NOT NULL,
    EndDate        DATE          NOT NULL,
    DurationDays   AS (DATEDIFF(DAY, StartDate, EndDate) + 1)
);

INSERT INTO dbo.DimPromotion (PromotionKey, PromotionID, PromotionName, DiscountPct, DiscountTier, Channel, StartDate, EndDate)
SELECT
    PromotionID   AS PromotionKey,
    PromotionID,
    PromotionName,
    DiscountPct,
    CASE
        WHEN DiscountPct >= 30 THEN 'High'
        WHEN DiscountPct >= 15 THEN 'Medium'
        ELSE 'Low'
    END AS DiscountTier,
    Channel,
    StartDate,
    EndDate
FROM dbo.src_Promotion;

-- ============================================================
-- STEP 5: BUILD THE FACT TABLE
-- ============================================================

CREATE TABLE dbo.FactSales (
    SalesKey         BIGINT        NOT NULL,   -- Surrogate PK
    DateKey          INT           NOT NULL,   -- FK → DimDate
    ProductKey       INT           NOT NULL,   -- FK → DimProduct
    CustomerKey      INT           NOT NULL,   -- FK → DimCustomer
    StoreKey         INT           NOT NULL,   -- FK → DimStore
    PromotionKey     INT           NULL,        -- FK → DimPromotion (nullable = no promo)
    -- Degenerate dimensions (kept on fact, no dim table needed)
    OrderID          INT           NOT NULL,
    OrderLineID      INT           NOT NULL,
    -- Additive measures
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
    ROW_NUMBER() OVER (ORDER BY ol.OrderLineID)           AS SalesKey,
    -- Date key: YYYYMMDD integer
    CAST(FORMAT(o.OrderDate, 'yyyyMMdd') AS INT)          AS DateKey,
    ol.ProductID                                           AS ProductKey,
    o.CustomerID                                           AS CustomerKey,
    o.StoreID                                              AS StoreKey,
    o.PromotionID                                          AS PromotionKey,
    o.OrderID,
    ol.OrderLineID,
    ol.Quantity                                            AS QuantitySold,
    ol.UnitPrice,
    ol.Discount                                            AS DiscountPct,
    ROUND(ol.Quantity * ol.UnitPrice * (ol.Discount / 100), 2) AS DiscountAmount,
    ROUND(ol.Quantity * ol.UnitPrice, 2)                  AS GrossSalesAmount,
    ROUND(ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100), 2) AS NetSalesAmount,
    ROUND(ol.Quantity * p.UnitCost, 2)                    AS CostAmount,
    ROUND(ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100)
          - ol.Quantity * p.UnitCost, 2)                  AS GrossProfit,
    ROUND(((ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100)
           - ol.Quantity * p.UnitCost)
          / NULLIF(ol.Quantity * ol.UnitPrice * (1 - ol.Discount / 100), 0)) * 100, 2)
                                                           AS GrossProfitPct
FROM      dbo.src_SalesOrderLine ol
JOIN      dbo.src_SalesOrder     o  ON ol.OrderID    = o.OrderID
JOIN      dbo.src_Product        p  ON ol.ProductID  = p.ProductID;

-- ============================================================
-- STEP 6: SAMPLE ANALYTICAL QUERIES (STAR SCHEMA)
-- ============================================================

-- ----------------------------------------------------------
-- Q1: Monthly revenue and profit summary
-- ----------------------------------------------------------
SELECT
    d.Year,
    d.MonthName,
    d.MonthNumber,
    COUNT(DISTINCT f.OrderID)          AS TotalOrders,
    SUM(f.QuantitySold)                AS UnitsSold,
    SUM(f.GrossSalesAmount)            AS GrossRevenue,
    SUM(f.NetSalesAmount)              AS NetRevenue,
    SUM(f.GrossProfit)                 AS GrossProfit,
    ROUND(SUM(f.GrossProfit)
        / NULLIF(SUM(f.NetSalesAmount), 0) * 100, 1) AS ProfitMarginPct
FROM      dbo.FactSales f
JOIN      dbo.DimDate   d ON f.DateKey = d.DateKey
GROUP BY  d.Year, d.MonthName, d.MonthNumber
ORDER BY  d.Year, d.MonthNumber;

-- ----------------------------------------------------------
-- Q2: Top 5 products by net revenue with margin
-- ----------------------------------------------------------
SELECT TOP 5
    p.ProductName,
    p.CategoryName,
    p.Brand,
    SUM(f.QuantitySold)        AS UnitsSold,
    SUM(f.NetSalesAmount)      AS NetRevenue,
    SUM(f.GrossProfit)         AS GrossProfit,
    ROUND(AVG(f.GrossProfitPct), 1) AS AvgMarginPct
FROM      dbo.FactSales  f
JOIN      dbo.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY  p.ProductName, p.CategoryName, p.Brand
ORDER BY  NetRevenue DESC;

-- ----------------------------------------------------------
-- Q3: Sales by store city and store type
-- ----------------------------------------------------------
SELECT
    s.City,
    s.StateProvince,
    s.StoreType,
    s.SizeCategory,
    COUNT(DISTINCT f.OrderID)  AS Orders,
    SUM(f.NetSalesAmount)      AS NetRevenue,
    ROUND(SUM(f.NetSalesAmount)
        / NULLIF(s.SquareFootage, 0), 2) AS RevenuePerSqFt
FROM      dbo.FactSales f
JOIN      dbo.DimStore  s ON f.StoreKey = s.StoreKey
GROUP BY  s.City, s.StateProvince, s.StoreType, s.SizeCategory, s.SquareFootage
ORDER BY  NetRevenue DESC;

-- ----------------------------------------------------------
-- Q4: Customer loyalty tier performance
-- ----------------------------------------------------------
SELECT
    c.LoyaltyTier,
    c.AgeGroup,
    COUNT(DISTINCT f.CustomerKey) AS UniqueCustomers,
    COUNT(DISTINCT f.OrderID)     AS TotalOrders,
    SUM(f.NetSalesAmount)         AS TotalRevenue,
    ROUND(SUM(f.NetSalesAmount)
        / NULLIF(COUNT(DISTINCT f.CustomerKey), 0), 2) AS RevenuePerCustomer
FROM      dbo.FactSales   f
JOIN      dbo.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY  c.LoyaltyTier, c.AgeGroup
ORDER BY  c.LoyaltyTier, c.AgeGroup;

-- ----------------------------------------------------------
-- Q5: Promotion effectiveness analysis
-- ----------------------------------------------------------
SELECT
    COALESCE(pr.PromotionName, 'No Promotion')  AS Promotion,
    COALESCE(pr.Channel, 'N/A')                 AS Channel,
    COALESCE(pr.DiscountTier, 'N/A')            AS DiscountTier,
    COUNT(DISTINCT f.OrderID)                   AS Orders,
    SUM(f.DiscountAmount)                       AS TotalDiscountGiven,
    SUM(f.NetSalesAmount)                       AS NetRevenue,
    SUM(f.GrossProfit)                          AS GrossProfit,
    ROUND(AVG(f.GrossProfitPct), 1)             AS AvgMarginPct
FROM      dbo.FactSales              f
LEFT JOIN dbo.DimPromotion           pr ON f.PromotionKey = pr.PromotionKey
GROUP BY  pr.PromotionName, pr.Channel, pr.DiscountTier
ORDER BY  NetRevenue DESC;

-- ----------------------------------------------------------
-- Q6: Full-star join — quarterly sales by category and region
-- ----------------------------------------------------------
SELECT
    d.Year,
    d.QuarterName,
    p.CategoryName,
    p.Department,
    s.StateProvince,
    SUM(f.NetSalesAmount)  AS NetRevenue,
    SUM(f.GrossProfit)     AS GrossProfit,
    SUM(f.QuantitySold)    AS UnitsSold
FROM      dbo.FactSales  f
JOIN      dbo.DimDate    d  ON f.DateKey     = d.DateKey
JOIN      dbo.DimProduct p  ON f.ProductKey  = p.ProductKey
JOIN      dbo.DimStore   s  ON f.StoreKey    = s.StoreKey
JOIN      dbo.DimCustomer c ON f.CustomerKey = c.CustomerKey
LEFT JOIN dbo.DimPromotion pr ON f.PromotionKey = pr.PromotionKey
GROUP BY  d.Year, d.QuarterName, d.Quarter, p.CategoryName, p.Department, s.StateProvince
ORDER BY  d.Year, d.Quarter, NetRevenue DESC;
