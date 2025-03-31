-- Detecting LATIN values

SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_material_status,
	ci.cst_gender,
	ci.cst_create_date,

	cst_firstname COLLATE Latin1_General_CI_AS AS ConvertedColumn
	

FROM
	silver.crm_cust_info AS ci
WHERE
	

	ci.cst_firstname COLLATE Latin1_General_BIN LIKE '%' + CAST(NCHAR(65533) AS NVARCHAR) + '%';



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




-- Checking for "sls_price", "sls_quantity", and "sls_sales"
-- First of all, please go talk to "BUSINESS USERS" or "THE PERSON who is responsible for tracking or acquiring this data"
-- If values in "sls_sales" are negative, zero, or null, derive it using "sls_quantity" and "sls_price"
-- If values in "sls_price" are zero, or null, calculate it using "sls_sales" and "sls_quantity"
-- If values in "sls_price" are nagive, convert it to a positive value"

SELECT
	sls_sales,
	sls_quantity,
	sls_price,

	CASE
		WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales_g,

	CASE
		WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS sls_price_g

FROM
	bronze.crm_sales_details

WHERE
	sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL
	OR sls_quantity IS NULL
	OR sls_price IS NULL
	OR sls_sales <= 0
	OR sls_quantity <= 0
	OR sls_price <= 0

ORDER BY
	sls_sales,
	sls_quantity,
	sls_price;


-- Checking for Out-Of-Range DATES
SELECT
	bdate

FROM
	bronze.erp_cust_az12

WHERE
	bdate < '1924-01-01'
	OR bdate > GETDATE()






































