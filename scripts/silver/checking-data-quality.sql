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
