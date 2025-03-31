-- Identifying DUPLICATE VALUES in PRIMARY KEY
WITH x AS (
SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_material_status,

	CASE
		WHEN ci.cst_gender IS NULL THEN ca.gen
		ELSE ci.cst_gender
	END AS cst_gender,

	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry

FROM
	silver.crm_cust_info AS ci
LEFT JOIN
	silver.erp_cust_az12 AS ca
ON	ci.cst_key = ca.cid
LEFT JOIN
	silver.erp_loc_a101  AS la
ON	ci.cst_key = la.cid
)

SELECT
	cst_id,
	COUNT(*)
FROM
	x
GROUP BY
	cst_id
HAVING
	COUNT(*) > 1;






-- DETECTING DISTINCT values

WITH x AS (
SELECT
	
	DISTINCT CASE
		WHEN ci.cst_gender IS NULL THEN ca.gen
		ELSE ci.cst_gender
	END AS cst_gender,
	ca.gen


FROM
	silver.crm_cust_info AS ci
LEFT JOIN
	silver.erp_cust_az12 AS ca
ON	ci.cst_key = ca.cid
LEFT JOIN
	silver.erp_loc_a101  AS la
ON	ci.cst_key = la.cid

)

SELECT
	
	DISTINCT CASE
		WHEN cst_gender IS NOT NULL THEN cst_gender
		ELSE COALESCE(gen, NULL)
	END AS x

FROM
	x
