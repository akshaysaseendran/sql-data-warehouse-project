-- ============================================================
-- STORED PROCEDURE: LOAD SILVER LAYER
-- PostgreSQL
-- Bronze -> Silver
-- ============================================================

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE

    -- ========================================================
    -- Timing variables
    -- ========================================================

    v_batch_start_time TIMESTAMP;
    v_batch_end_time   TIMESTAMP;

    v_start_time       TIMESTAMP;
    v_end_time         TIMESTAMP;

    v_duration         INTERVAL;


BEGIN

    -- ========================================================
    -- START BATCH TIMER
    -- ========================================================

    v_batch_start_time := clock_timestamp();


    RAISE NOTICE '';
    RAISE NOTICE '================================================';
    RAISE NOTICE '           LOADING SILVER LAYER';
    RAISE NOTICE '================================================';


    -- ========================================================
    -- CRM TABLES
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';


    -- ========================================================
    -- CRM CUSTOMER INFORMATION
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';

    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';


    INSERT INTO silver.crm_cust_info
    (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )

    SELECT
        cst_id,

        cst_key,

        TRIM(cst_firstname) AS cst_firstname,

        TRIM(cst_lastname) AS cst_lastname,

        -- Normalize marital status
        CASE
            WHEN UPPER(TRIM(cst_material_status)) = 'S'
                THEN 'Single'

            WHEN UPPER(TRIM(cst_material_status)) = 'M'
                THEN 'Married'

            ELSE 'n/a'
        END AS cst_marital_status,

        -- Normalize gender
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F'
                THEN 'Female'

            WHEN UPPER(TRIM(cst_gndr)) = 'M'
                THEN 'Male'

            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM
    (
        SELECT
            *,
            ROW_NUMBER() OVER
            (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last

        FROM bronze.crm_cust_info

        WHERE cst_id IS NOT NULL
    ) t

    WHERE flag_last = 1;


    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;

    RAISE NOTICE '>> Load Duration: %', v_duration;
    RAISE NOTICE '>> ----------------------------------------';


    -- ========================================================
    -- CRM PRODUCT INFORMATION
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';

    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';


    INSERT INTO silver.crm_prd_info
    (
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

        -- Extract category ID
        REPLACE(
            SUBSTRING(prd_key FROM 1 FOR 5),
            '-',
            '_'
        ) AS cat_id,

        -- Extract product key
        SUBSTRING(prd_key FROM 7) AS prd_key,

        prd_nm,

        -- Replace NULL cost with 0
        COALESCE(prd_cost, 0) AS prd_cost,

        -- Normalize product line
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M'
                THEN 'Mountain'

            WHEN UPPER(TRIM(prd_line)) = 'R'
                THEN 'Road'

            WHEN UPPER(TRIM(prd_line)) = 'S'
                THEN 'Other Sales'

            WHEN UPPER(TRIM(prd_line)) = 'T'
                THEN 'Touring'

            ELSE 'n/a'
        END AS prd_line,

        prd_start_dt,

        -- End date = one day before next start date
        (
            LEAD(prd_start_dt) OVER
            (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            )
            - INTERVAL '1 day'
        )::DATE AS prd_end_dt

    FROM bronze.crm_prd_info;


    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;

    RAISE NOTICE '>> Load Duration: %', v_duration;
    RAISE NOTICE '>> ----------------------------------------';


    -- ========================================================
    -- CRM SALES DETAILS
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';

    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';


    INSERT INTO silver.crm_sales_details
    (
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


        -- ====================================================
        -- Convert order date YYYYMMDD integer -> DATE
        -- ====================================================

        CASE
            WHEN sls_order_dt = 0
                OR LENGTH(sls_order_dt::TEXT) <> 8
                THEN NULL

            ELSE TO_DATE(
                sls_order_dt::TEXT,
                'YYYYMMDD'
            )
        END AS sls_order_dt,


        -- ====================================================
        -- Convert ship date
        -- ====================================================

        CASE
            WHEN sls_ship_dt = 0
                OR LENGTH(sls_ship_dt::TEXT) <> 8
                THEN NULL

            ELSE TO_DATE(
                sls_ship_dt::TEXT,
                'YYYYMMDD'
            )
        END AS sls_ship_dt,


        -- ====================================================
        -- Convert due date
        -- ====================================================

        CASE
            WHEN sls_due_dt = 0
                OR LENGTH(sls_due_dt::TEXT) <> 8
                THEN NULL

            ELSE TO_DATE(
                sls_due_dt::TEXT,
                'YYYYMMDD'
            )
        END AS sls_due_dt,


        -- ====================================================
        -- Correct sales value
        -- ====================================================

        CASE

            WHEN sls_sales IS NULL
                OR sls_sales <= 0
                OR sls_sales <> sls_quantity * ABS(sls_price)

            THEN sls_quantity * ABS(sls_price)

            ELSE sls_sales

        END AS sls_sales,


        sls_quantity,


        -- ====================================================
        -- Correct price
        -- ====================================================

        CASE

            WHEN sls_price IS NULL
                OR sls_price <= 0

            THEN
                sls_sales / NULLIF(sls_quantity, 0)

            ELSE sls_price

        END AS sls_price


    FROM bronze.crm_sales_details;


    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;

    RAISE NOTICE '>> Load Duration: %', v_duration;
    RAISE NOTICE '>> ----------------------------------------';


    -- ========================================================
    -- ERP TABLES
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';


    -- ========================================================
    -- ERP CUSTOMER
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';

    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';


    INSERT INTO silver.erp_cust_az12
    (
        cid,
        bdate,
        gen
    )

    SELECT

        -- Remove NAS prefix
        CASE

            WHEN cid LIKE 'NAS%'
                THEN SUBSTRING(cid FROM 4)

            ELSE cid

        END AS cid,


        -- Remove future birthdates
        CASE

            WHEN bdate > CURRENT_DATE
                THEN NULL

            ELSE bdate

        END AS bdate,


        -- Normalize gender
        CASE

            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                THEN 'Female'

            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                THEN 'Male'

            ELSE 'n/a'

        END AS gen


    FROM bronze.erp_cust_az12;


    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;

    RAISE NOTICE '>> Load Duration: %', v_duration;
    RAISE NOTICE '>> ----------------------------------------';


    -- ========================================================
    -- ERP LOCATION
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';

    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';


    INSERT INTO silver.erp_loc_a101
    (
        cid,
        cntry
    )

    SELECT

        -- Remove hyphens
        REPLACE(cid, '-', '') AS cid,


        -- Normalize country
        CASE

            WHEN TRIM(cntry) = 'DE'
                THEN 'Germany'

            WHEN TRIM(cntry) IN ('US', 'USA')
                THEN 'United States'

            WHEN TRIM(cntry) = ''
                OR cntry IS NULL
                THEN 'n/a'

            ELSE TRIM(cntry)

        END AS cntry


    FROM bronze.erp_loc_a101;


    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;

    RAISE NOTICE '>> Load Duration: %', v_duration;
    RAISE NOTICE '>> ----------------------------------------';


    -- ========================================================
    -- ERP PRODUCT CATEGORY
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';


    INSERT INTO silver.erp_px_cat_g1v2
    (
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

    FROM bronze.erp_px_cat_g1v2;


    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;

    RAISE NOTICE '>> Load Duration: %', v_duration;
    RAISE NOTICE '>> ----------------------------------------';


    -- ========================================================
    -- BATCH END
    -- ========================================================

    v_batch_end_time := clock_timestamp();

    v_duration := v_batch_end_time - v_batch_start_time;


    RAISE NOTICE '';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '     LOADING SILVER LAYER COMPLETED';
    RAISE NOTICE '==========================================';

    RAISE NOTICE 'Batch Start Time: %', v_batch_start_time;
    RAISE NOTICE 'Batch End Time  : %', v_batch_end_time;
    RAISE NOTICE 'Total Duration  : %', v_duration;

    RAISE NOTICE '==========================================';


EXCEPTION

    WHEN OTHERS THEN

        v_batch_end_time := clock_timestamp();

        v_duration := v_batch_end_time - v_batch_start_time;


        RAISE NOTICE '';
        RAISE NOTICE '==========================================';
        RAISE NOTICE '     ERROR OCCURRED DURING SILVER LOAD';
        RAISE NOTICE '==========================================';

        RAISE NOTICE 'Error Message : %', SQLERRM;
        RAISE NOTICE 'Error Code    : %', SQLSTATE;
        RAISE NOTICE 'Duration      : %', v_duration;

        RAISE NOTICE '==========================================';


        -- Re-throw the error
        RAISE;

END;
$$;


-- ============================================================
-- EXECUTE SILVER LOAD
-- ============================================================

CALL silver.load_silver();
