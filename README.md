# Data-Engineer-Project-data-warehouse


## T-SQL Syntax Knowledge
### Why is INSERT INTO not at the top?
In SQL Server, ```when using a Common Table Expression (CTE) (WITH statement), the INSERT INTO statement must come after the CTE definition.``` This is because SQL Server expects the WITH clause to be immediately followed by a ```SELECT```, ```INSERT```, ```UPDATE```, or ```DELETE``` statement.
* A CTE (```WITH``` clause) must be the first statement in the batch.
If you place ```INSERT INTO``` before ```WITH```, SQL Server will not recognize the CTE.

- Incorrect Order (Causes Syntax Error)
  ```sql
    INSERT INTO silver.crm_cust_info (...)  -- ❌ Incorrect placement
    WITH ranking AS (
        SELECT ...
    )
    SELECT ...
    ```
  Error: "Incorrect syntax near WITH."
  
- Correct Order (CTE First, Then INSERT INTO)
  ```sql
    WITH ranking AS (  -- ✅ Define CTE first
    SELECT ...
    )
    INSERT INTO silver.crm_cust_info (...)  -- ✅ Then use it in INSERT
    SELECT ...
    ```
  
- Alternative: Use a Subquery Instead of CTE, If you prefer INSERT INTO at the top, you can replace the CTE with a subquery:
  ```sql
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
      TRIM(cst_firstname),
      TRIM(cst_lastname),
      CASE
          WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'single'
          WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'married'
          ELSE NULL
      END,
      CASE
          WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'female'
          WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'male'
          ELSE NULL
      END,
      cst_create_date
  FROM (
      SELECT *,
             ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS ranked
      FROM bronze.crm_cust_info
  ) AS ranking
  WHERE ranked = 1;
  ```


    
