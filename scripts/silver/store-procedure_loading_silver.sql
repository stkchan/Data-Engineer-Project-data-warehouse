-- Checking NULL and Duplicate values in Primary Key column

WITH ranking AS (
	SELECT
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_material_status,
		cst_gender,
		cst_create_date,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS ranked
		
	FROM
		bronze.crm_cust_info 

)

SELECT

	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname)  AS cst_lastname,

	CASE
		WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'single'
		WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'married'
		ELSE NULL
	END AS cst_material_status,


	CASE
		WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'female'
		WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'male'
		ELSE NULL
	END AS cst_gender,

	cst_create_date

FROM
	ranking

WHERE
	ranked = 1 
