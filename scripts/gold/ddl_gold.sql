/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS

WITH first_step AS (
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
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
	cst_id				   AS customer_id,
	cst_key				   AS customer_code,
	cst_firstname		           AS customer_first_name,
	cst_material_status	           AS customer_material_status,
	cntry				   AS country,

	 CASE
		WHEN cst_gender IS NOT NULL THEN cst_gender
		ELSE COALESCE(gen, NULL)
	END AS gender,

	bdate			AS birth_date,
	cst_create_date	AS create_date
  
FROM
	first_step;
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id		    AS product_id,
	pn.prd_key		    AS product_code,
	pn.prd_nm		    AS product_name,	
	pn.cat_id		    AS category_id,
	pc.cat			    AS category,
	pc.subcat		    AS sub_category,
	pc.maintenance,
	pn.prd_cost		    AS cost,
	pn.prd_line		    AS product_line,
	pn.prd_start_dt AS start_date

FROM
	silver.crm_prd_info	AS pn
LEFT JOIN
	silver.erp_px_cat_g1v2	AS pc
ON	pn.cat_id = pc.id

WHERE
	pn.prd_end_dt IS NULL; -- Filter out all historical data
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE View gold.fact_sales AS

SELECT
	sd.sls_ord_num		AS order_number,
	pr.product_key,		
	cu.customer_key,		
	sd.sls_order_dt		AS order_date,
	sd.sls_ship_dt		AS shipping_date,
	sd.sls_due_dt		AS due_date,
	sd.sls_sales		AS sales_amount,
	sd.sls_quantity		AS quantity,
	sd.sls_price		AS price

FROM
	silver.crm_sales_details AS sd
LEFT JOIN
	gold.dim_products	 AS pr
ON  sd.sls_prd_key = pr.product_code
LEFT JOIN
	gold.dim_customers	 AS cu
ON	sd.sls_cust_id = cu.customer_id

WHERE
	customer_key IS NOT NULL;
GO
