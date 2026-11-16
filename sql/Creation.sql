CREATE DATABASE axon_mfg;
USE axon_mfg;


-- 1.Operation Dimension

CREATE TABLE dim_Operation (
  Operation_Code VARCHAR(10) PRIMARY KEY,
  Operation_Name VARCHAR(40),
  Standard_Cost_Per_Hour INT,
  Is_Automated VARCHAR(3)
);

-- 2.Machine Dimension

CREATE TABLE dim_Machine (
  Machine_Code   VARCHAR(10) PRIMARY KEY,
  Operation_Code VARCHAR(10),
  Operation_Name VARCHAR(40),
  Avg_Daily_Cost DECIMAL(10,2),
  Machine_Type   VARCHAR(20),
  Status         VARCHAR(10),
  FOREIGN KEY (Operation_Code) REFERENCES dim_Operation(Operation_Code)
);

-- 3. Buyer dimension
CREATE TABLE dim_Buyer (
    Buyer_ID VARCHAR(5) PRIMARY KEY,
    Buyer_Name VARCHAR(100),
    Region VARCHAR(50),
    Founded_Year INT,
    Segment VARCHAR(50)
);

-- 4. Customer dimension
CREATE TABLE dim_Customer (
    Customer_Code VARCHAR(10) PRIMARY KEY,
    Customer_Name VARCHAR(100),
    Customer_Type VARCHAR(50),
    City VARCHAR(50),
    Active VARCHAR(5)
);

-- 5. Employee dimension
CREATE TABLE dim_Employee (
    Employee_Code VARCHAR(10) PRIMARY KEY,
    Employee_Name VARCHAR(100),
    Department VARCHAR(50),
    `Level` VARCHAR(20)
);

-- 6. Department dimension
CREATE TABLE dim_Department (
    Dept_ID VARCHAR(5) PRIMARY KEY,
    Dept_Name VARCHAR(100),
    Category VARCHAR(100),
    Head_Count_Range VARCHAR(20),
    Floor VARCHAR(30)
);

-- 7. Item dimension
CREATE TABLE dim_Item (
    Item_Code VARCHAR(30) PRIMARY KEY,
    Item_Name VARCHAR(255),
    Department_Name VARCHAR(100),
    Item_Category VARCHAR(50)
);

-- 8. Date dimension
CREATE TABLE dim_Date (
    `Date` DATE PRIMARY KEY,
    `Day` INT,
    Day_Name VARCHAR(15),
    Week_Num INT,
    Month_Num INT,
    Month_Name VARCHAR(15),
    Quarter VARCHAR(2),
    `Year` INT,
    Is_Weekend VARCHAR(5),
    Season VARCHAR(20)
);

-- 9.Production Fact
CREATE TABLE fact_Production (
  Doc_Num        VARCHAR(20) NULL,          
  Date_FK        DATE,
  Buyer_ID       VARCHAR(5),  Customer_Code VARCHAR(10), Employee_Code VARCHAR(10),
  Machine_Code   VARCHAR(10), Operation_Code VARCHAR(10), Dept_ID VARCHAR(5), Item_Code VARCHAR(30),
  Delivery_Status VARCHAR(10), Is_Repeat_Order VARCHAR(3),
  WO_Qty INT, Press_Qty INT, Processed_Qty INT, Produced_Qty INT, Rejected_Qty INT,
  Today_Manufactured_Qty INT, Total_Qty BIGINT, Total_Value DECIMAL(14,2),
  Per_Day_Machine_Cost DECIMAL(10,2), Rejection_Rate_Pct DECIMAL(6,2),
  Efficiency_Rate_Pct DECIMAL(6,2), Machine_Utilization_Pct DECIMAL(6,2), Cost_per_Unit DECIMAL(10,2)
);


-- Data Integrity Check 
SELECT 'fact_Production' t, COUNT(*) FROM fact_Production     
UNION ALL SELECT 'dim_Buyer', COUNT(*) FROM dim_Buyer           
UNION ALL SELECT 'dim_Customer', COUNT(*) FROM dim_Customer      
UNION ALL SELECT 'dim_Employee', COUNT(*) FROM dim_Employee      
UNION ALL SELECT 'dim_Operation', COUNT(*) FROM dim_Operation    
UNION ALL SELECT 'dim_Machine', COUNT(*) FROM dim_Machine        
UNION ALL SELECT 'dim_Department', COUNT(*) FROM dim_Department   
UNION ALL SELECT 'dim_Item', COUNT(*) FROM dim_Item               
UNION ALL SELECT 'dim_Date', COUNT(*) FROM dim_Date;            

-- View Creation 

CREATE OR REPLACE VIEW vw_production_clean AS
SELECT
    f.*,
    b.Buyer_Name,
    d.Dept_Name,
    o.Operation_Name,
    e.Employee_Name,
    e.`Level` AS Employee_Level,
    i.Item_Category,
    dt.Month_Num,
    dt.Month_Name,
    dt.Quarter,
    dt.Season
FROM fact_Production AS f
LEFT JOIN dim_Buyer AS b
    ON b.Buyer_ID = f.Buyer_ID
LEFT JOIN dim_Department AS d
    ON d.Dept_ID = f.Dept_ID
LEFT JOIN dim_Operation AS o
    ON o.Operation_Code = f.Operation_Code
LEFT JOIN dim_Employee AS e
    ON e.Employee_Code = f.Employee_Code
LEFT JOIN dim_Item AS i
    ON i.Item_Code = f.Item_Code
LEFT JOIN dim_Date AS dt
    ON dt.`Date` = f.Date_FK
WHERE NULLIF(TRIM(f.Doc_Num), '') IS NOT NULL;


SELECT COUNT(*) FROM vw_production_clean;

SELECT COUNT(*)              AS all_rows,     
       COUNT(Doc_Num)        AS real_rows,     
       COUNT(*) - COUNT(Doc_Num) AS blank_rows   
FROM fact_Production;


