-- Checking DUPLICATE values of cst_id
SELECT
	cst_id,
	COUNT(*)
FROM
	silver.crm_cust_info
GROUP BY
	cst_id
HAVING
	COUNT(*) > 1;


-- Checking SPACES values of cst_firstname & cst_lastname
SELECT 
    --cst_firstname
	cst_lastname
FROM
	silver.crm_cust_info
WHERE
	--cst_firstname != TRIM(cst_firstname)
	cst_lastname != TRIM(cst_lastname);


-- Checking DISTINCT values of cst_gender
SELECT 
    DISTINCT cst_gender
FROM
	silver.crm_cust_info;


-- Checking values of prd_cost
SELECT 
    prd_cost
FROM
	silver.crm_prd_info
WHERE
	prd_cost < 0
	OR prd_cost IS NULL;


-- Checking for invalid DATE ORDERS
SELECT 
    *
FROM
	silver.crm_prd_info
WHERE
	prd_end_dt < prd_start_dt;




---------------------------------------------------------------------- TABLE = bronze.crm_sales_details

-- Checking "Spaces" values in sls_ord_num column
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price

FROM
	bronze.crm_sales_details

WHERE
	sls_ord_num != TRIM(sls_ord_num);



-- Checking VALUES that not in prd_key
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price

FROM
	bronze.crm_sales_details

WHERE
	sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);



-- Checking VALUES Invalid DATE

SELECT
	NULLIF(sls_order_dt, 0) AS sls_order_dt
	
FROM
	bronze.crm_sales_details

WHERE
	sls_order_dt <=0
	OR LEN(sls_order_dt) != 8;



-- Checking VALUES Invalid Order DATE
SELECT
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt

FROM
	bronze.crm_sales_details

WHERE
		sls_order_dt > sls_ship_dt
	OR	sls_order_dt > sls_due_dt;
























