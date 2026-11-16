-- KPI #1 · Production KPIs: produced, efficiency, utilization, cost per unit
SELECT SUM(WO_Qty)        AS ordered,
       SUM(Processed_Qty) AS processed,
       SUM(Produced_Qty)  AS produced,
       ROUND(SUM(Produced_Qty)  / SUM(Processed_Qty) * 100, 2) AS efficiency_pct,
       ROUND(SUM(Processed_Qty) / SUM(WO_Qty) * 100, 2)        AS utilization_pct,
       ROUND(SUM(Total_Value)   / SUM(Produced_Qty), 2)        AS cost_per_unit
FROM vw_production_clean;

-- KPI #2 Production output by month
SELECT
    Month_Num,
    Month_Name,
    SUM(Produced_Qty) AS total_produced,
    SUM(Rejected_Qty) AS total_rejected,
    ROUND(SUM(Total_Value), 2) AS total_value
FROM vw_production_clean
GROUP BY Month_Num, Month_Name
ORDER BY Month_Num;

-- KPI #3 Machine cost versus output
SELECT
    v.Machine_Code,
    m.Machine_Type AS Machine_Type,
    ROUND(SUM(v.Per_Day_Machine_Cost), 2) AS summed_daily_machine_cost,
    SUM(v.Produced_Qty) AS total_produced,
    ROUND(
        SUM(v.Per_Day_Machine_Cost) /
        NULLIF(SUM(v.Produced_Qty), 0),
        2
    ) AS cost_per_produced_unit_proxy
FROM vw_production_clean v
LEFT JOIN dim_Machine m
    ON v.Machine_Code = m.Machine_Code
GROUP BY
    v.Machine_Code,
    m.Machine_Type
ORDER BY cost_per_produced_unit_proxy;

-- KPI #4 Top 10 customers by production value
SELECT
    v.Customer_Code,
    c.Customer_Name,
    ROUND(SUM(v.Total_Value), 2) AS total_value,
    SUM(v.Produced_Qty) AS total_produced,
    COUNT(DISTINCT v.Doc_Num) AS unique_documents
FROM vw_production_clean v
LEFT JOIN dim_Customer c
    ON v.Customer_Code = c.Customer_Code
GROUP BY
    v.Customer_Code,
    c.Customer_Name
ORDER BY total_value DESC
LIMIT 10;

-- KPI #5 Overall rejection rate (%)
SELECT
    SUM(Rejected_Qty) AS total_rejected,
    SUM(Produced_Qty) AS total_produced,
    CONCAT(
        ROUND(
            100.0 * SUM(Rejected_Qty) /
            NULLIF(SUM(Produced_Qty), 0),
            2
        ),
        '%'
    ) AS rejection_rate
FROM vw_production_clean;

-- KPI #6 Highest rejection rate
SELECT Machine_Code, COUNT(*) AS orders,
       ROUND(SUM(Rejected_Qty) / SUM(Produced_Qty) * 100, 2) AS rej_rate_pct
FROM vw_production_clean
WHERE Doc_Num IS NOT NULL
GROUP BY Machine_Code
HAVING COUNT(*) >= 50
ORDER BY rej_rate_pct DESC
LIMIT 5;

-- KPI #7 Machine utilization (processed vs ordered)
SELECT
    Machine_Code,
    ROUND(SUM(Processed_Qty) / NULLIF(SUM(WO_Qty), 0) * 100, 2) AS utilization_pct,
    SUM(Produced_Qty) AS total_produced
FROM vw_production_clean
GROUP BY Machine_Code
ORDER BY total_produced DESC;

-- Integrity #1 Production rows pointing at a missing dimension record
SELECT SUM(b.Buyer_ID IS NULL)       AS missing_buyer,
       SUM(c.Customer_Code IS NULL)  AS missing_customer,
       SUM(e.Employee_Code IS NULL)  AS missing_employee,
       SUM(m.Machine_Code IS NULL)   AS missing_machine,
       SUM(o.Operation_Code IS NULL) AS missing_operation,
       SUM(d.Dept_ID IS NULL)        AS missing_department,
       SUM(i.Item_Code IS NULL)      AS missing_item
FROM vw_production_clean v
LEFT JOIN dim_Buyer b      ON b.Buyer_ID = v.Buyer_ID
LEFT JOIN dim_Customer c   ON c.Customer_Code = v.Customer_Code
LEFT JOIN dim_Employee e   ON e.Employee_Code = v.Employee_Code
LEFT JOIN dim_Machine m    ON m.Machine_Code = v.Machine_Code
LEFT JOIN dim_Operation o  ON o.Operation_Code = v.Operation_Code
LEFT JOIN dim_Department d ON d.Dept_ID = v.Dept_ID
LEFT JOIN dim_Item i       ON i.Item_Code = v.Item_Code;

-- Integrity #2 Duplicate work orders
SELECT Doc_Num, COUNT(*) AS copies
FROM vw_production_clean
GROUP BY Doc_Num
HAVING COUNT(*) > 1;

-- Integrity #3 Negative quantities or values
SELECT COUNT(*) AS negative_rows
FROM vw_production_clean
WHERE WO_Qty < 0 OR Processed_Qty < 0 OR Produced_Qty < 0
   OR Rejected_Qty < 0 OR Total_Value < 0;