/*
===============================================================================
Stored Procedure: Load silver Layer (Bronze-> Silver)
===============================================================================
Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
			SET @batch_start_time = GETDATE();
			PRINT '==========================================================';
			PRINT 'Loading Silver Layer';
			PRINT '==========================================================';

			PRINT '----------------------------------------------------------';
			PRINT 'Loading CRM Tables';
			PRINT '----------------------------------------------------------';
			
			-- Loading data into silver.crm_cust_info
			SET @start_time = GETDATE();
			PRINT '>> Truncating data: silver.crm_cust_info';
			TRUNCATE TABLE silver.crm_cust_info;
			PRINT '>> Inserting data: silver.crm_cust_info';

			WITH ranking AS (
				SELECT
					cst_id,
					cst_key,
					cst_firstname,
					cst_lastname,
					cst_material_status,
					cst_gender,
					TRY_CAST(cst_create_date AS DATE) AS cst_create_date,
					ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS ranked
				FROM
					bronze.crm_cust_info
				
				WHERE
						cst_firstname COLLATE Latin1_General_BIN NOT LIKE '%' + CAST(NCHAR(65533) AS NVARCHAR) + '%'
					AND PATINDEX('%[A-Za-z]%', cst_firstname COLLATE Latin1_General_BIN) > 0
			)



			INSERT INTO silver.crm_cust_info (
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_material_status,
				cst_gender,
				cst_create_date
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
				ranked = 1;
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>> ---------------';

			
			-- Loading data into silver.crm_prd_info
			SET @start_time = GETDATE();
			PRINT '>> Truncating data: silver.crm_prd_info';
			TRUNCATE TABLE silver.crm_prd_info;
			PRINT '>> Inserting data: silver.crm_prd_info';

			INSERT INTO silver.crm_prd_info (
				prd_id,
				cat_id,
				prd_key,
				prd_nm,
				prd_cost,
				prd_line,
				prd_start_dt,
				prd_end_dt
			)

			SELECT
				prd_id,
				REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
				(SUBSTRING(prd_key, 7, LEN(prd_key)))		AS prd_key,
				prd_nm,
				ISNULL(prd_cost, 0)							AS prd_cost,

				CASE
					WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'mountain'
					WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'road'
					WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other sales'
					WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'touring'
					ELSE NULL
				END AS prd_line,

				CAST(prd_start_dt AS DATE) AS prd_start_dt,
				CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt

			FROM
				bronze.crm_prd_info;
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>> ---------------';



			-- Loading data into silver.crm_sales_details
			SET @start_time = GETDATE();
			PRINT '>> Truncating data: silver.crm_sales_details';
			TRUNCATE TABLE silver.crm_sales_details;
			PRINT '>> Inserting data: silver.crm_sales_details';

			INSERT INTO silver.crm_sales_details (
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				sls_order_dt,
				sls_ship_dt,
				sls_due_dt,
				sls_sales,
				sls_quantity,
				sls_price

			)


			SELECT
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,

				CASE
					WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
					ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
				END AS sls_order_dt,

				CASE
					WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
					ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
				END AS sls_ship_dt,
	
				CASE
					WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
					ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
				END AS sls_due_dt,

				CASE
					WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
					ELSE sls_sales
				END AS sls_sales_g,

				sls_quantity,

				CASE
					WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
					ELSE sls_price
				END AS sls_price_g

			FROM
				bronze.crm_sales_details;
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>> ---------------';



			PRINT '----------------------------------------------------------';
			PRINT 'Loading ERP Tables';
			PRINT '----------------------------------------------------------';


			-- Loading data into silver.erp_cust_az12
			SET @start_time = GETDATE();
			PRINT '>> Truncating data: silver.erp_cust_az12';
			TRUNCATE TABLE silver.erp_cust_az12;
			PRINT '>> Inserting data: silver.erp_cust_az12';

			INSERT INTO silver.erp_cust_az12 (
				cid,
				bdate,
				gen
			)

			SELECT

				CASE
					WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
					ELSE cid
				END AS cid,

				CASE
					WHEN bdate > GETDATE() THEN NULL
					ELSE bdate
				END AS bdate,

				CASE
					WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'female'
					WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')	 THEN 'male'
					ELSE NULL
				END AS gen

			FROM
				bronze.erp_cust_az12;
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>> ---------------';


			-- Loading data into silver.erp_loc_a101
			SET @start_time = GETDATE();
			PRINT '>> Truncating data: silver.erp_loc_a101';
			TRUNCATE TABLE silver.erp_loc_a101;
			PRINT '>> Inserting data: silver.erp_loc_a101';

			INSERT INTO silver.erp_loc_a101 (
				cid,
				cntry
			)
			SELECT

				REPLACE(cid, '-', '') AS cid,
				CASE
					WHEN TRIM(cntry) = 'DE'				THEN 'Germany'
					WHEN TRIM(cntry) IN ('US', 'USA')	THEN 'United States'
					WHEN TRIM(cntry) = ''				THEN NULL
					ELSE TRIM(cntry)
				END AS cntry

			FROM
				bronze.erp_loc_a101;
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>> ---------------';

			
			-- Loading data into silver.erp_loc_a101
			SET @start_time = GETDATE();
			PRINT '>> Truncating data: silver.erp_loc_a101';
			TRUNCATE TABLE silver.erp_px_cat_g1v2;
			PRINT '>> Inserting data: silver.erp_loc_a101';

			INSERT INTO silver.erp_px_cat_g1v2 (
				id,
				cat,
				subcat,
				maintenance
			)

			SELECT
				id,
				cat,
				subcat,
				maintenance

			FROM
				bronze.erp_px_cat_g1v2;
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>> ---------------';



			SET @batch_end_time = GETDATE();
			PRINT '=========================================================='
			PRINT 'Loading data to Bronze Layer is Completed';
			PRINT 'Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
			PRINT '=========================================================='


		END TRY
		BEGIN CATCH
			PRINT '=========================================================='
			PRINT 'ERROR OCCURED DURING LOADING DATA INTO BRONZE LAYER'
			PRINT 'Error Message' + ERROR_MESSAGE();
			PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
			PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
			PRINT '=========================================================='
		END CATCH
END;
