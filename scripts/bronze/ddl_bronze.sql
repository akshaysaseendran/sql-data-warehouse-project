/* 
===================================================================================
DDL script : create bronze tables 
==================================================================================
script purpose :
this script table create tables in the 'bronze' schema 
==============================================================================
*/













-- create database  'datawarehouse'

CREATE DATABASE datawarehouse;


CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;


------------
-- table for  customers info

CREATE TABLE bronze.crm_cust_info
(

    cst_id              int,
    cst_key             varchar,
    cst_firstname       varchar(50),
    cst_lastname        varchar(50),
    cst_material_status varchar(50),
    cst_gndr            varchar(50),
    cst_create_date     date
);

--table for product info

CREATE TABLE bronze.crm_prd_info
(
    prd_id        INT,
    prd_key       VARCHAR,
    prd_nm        VARCHAR,
    prd_cost      NUMERIC(10,2),
    prd_line      VARCHAR,
    prd_start_dt  DATE,
    prd_end_dt    DATE
);
--table for sales info

CREATE TABLE bronze.crm_sales_details
(
    sls_ord_num    VARCHAR,
    sls_prd_key    VARCHAR,
    sls_cust_id    INT,
    sls_order_dt   INT,
    sls_ship_dt    INT,
    sls_due_dt     INT,
    sls_sales      NUMERIC(10,2),
    sls_quantity   INT,
    sls_price      NUMERIC(10,2)
);



-- =====================================================
-- ERP: Customer Information
-- =====================================================

CREATE TABLE bronze.erp_cust_az12
(
    cid    VARCHAR,
    bdate  DATE,
    gen    VARCHAR
);


-- =====================================================
-- ERP: Location Information
-- =====================================================

CREATE TABLE bronze.erp_loc_a101
(
    cid    VARCHAR,
    cntry  VARCHAR
);


-- =====================================================
-- ERP: Product Category Information
-- =====================================================

 ---------Inserting the csv files
--- using bulk insert

-- =====================================================
-- LOAD CRM DATA
-- =====================================================
--- using import/export data from the data base explorer



SELECT 'crm_cust_info' AS table_name, COUNT(*) AS row_count
FROM bronze.crm_cust_info

UNION ALL

SELECT 'crm_prd_info', COUNT(*)
FROM bronze.crm_prd_info

UNION ALL

SELECT 'crm_sales_details', COUNT(*)
FROM bronze.crm_sales_details

UNION ALL

SELECT 'erp_cust_az12', COUNT(*)
FROM bronze.erp_cust_az12

UNION ALL

SELECT 'erp_loc_a101', COUNT(*)
FROM bronze.erp_loc_a101

UNION ALL





-----

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
BEGIN

    RAISE NOTICE 'Starting Bronze Layer Load...';

    RAISE NOTICE 'crm_cust_info: % rows',
        (SELECT COUNT(*) FROM bronze.crm_cust_info);

    RAISE NOTICE 'crm_prd_info: % rows',
        (SELECT COUNT(*) FROM bronze.crm_prd_info);

    RAISE NOTICE 'crm_sales_details: % rows',
        (SELECT COUNT(*) FROM bronze.crm_sales_details);

    RAISE NOTICE 'erp_cust_az12: % rows',
        (SELECT COUNT(*) FROM bronze.erp_cust_az12);

    RAISE NOTICE 'erp_loc_a101: % rows',
        (SELECT COUNT(*) FROM bronze.erp_loc_a101);

    RAISE NOTICE 'erp_px_cat_g1v2: % rows',
        (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2);

    RAISE NOTICE 'Bronze Layer Load Completed Successfully!';

END;
$$;
CALL bronze.load_bronze();

SELECT 'erp_px_cat_g1v2', COUNT(*)
FROM bronze.erp_px_cat_g1v2;


-- ============================================================
-- BRONZE LAYER LOAD / VALIDATION PROCEDURE
-- PostgreSQL
-- ============================================================


-- ============================================================
-- 1. CREATE LOAD LOG TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS bronze.load_log
(
    load_id          BIGSERIAL PRIMARY KEY,
    start_time       TIMESTAMP,
    end_time         TIMESTAMP,
    duration         INTERVAL,
    status           VARCHAR(20),

    crm_cust_rows    BIGINT,
    crm_prd_rows     BIGINT,
    crm_sales_rows   BIGINT,

    erp_cust_rows    BIGINT,
    erp_loc_rows     BIGINT,
    erp_cat_rows     BIGINT
);


-- ============================================================
-- 2. CREATE / REPLACE PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE

    -- Timing
    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
    v_duration   INTERVAL;

    -- Row counts
    v_crm_cust_rows  BIGINT;
    v_crm_prd_rows   BIGINT;
    v_crm_sales_rows BIGINT;

    v_erp_cust_rows  BIGINT;
    v_erp_loc_rows   BIGINT;
    v_erp_cat_rows   BIGINT;

BEGIN

    -- ========================================================
    -- START
    -- ========================================================

    v_start_time := clock_timestamp();

    RAISE NOTICE '====================================================';
    RAISE NOTICE '           STARTING BRONZE LAYER LOAD';
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'Start Time: %', v_start_time;


    -- ========================================================
    -- CRM TABLES
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '----------------------------------------------------';


    RAISE NOTICE 'Loading: bronze.crm_cust_info';

    SELECT COUNT(*)
    INTO v_crm_cust_rows
    FROM bronze.crm_cust_info;

    RAISE NOTICE 'Rows loaded: %', v_crm_cust_rows;


    RAISE NOTICE 'Loading: bronze.crm_prd_info';

    SELECT COUNT(*)
    INTO v_crm_prd_rows
    FROM bronze.crm_prd_info;

    RAISE NOTICE 'Rows loaded: %', v_crm_prd_rows;


    RAISE NOTICE 'Loading: bronze.crm_sales_details';

    SELECT COUNT(*)
    INTO v_crm_sales_rows
    FROM bronze.crm_sales_details;

    RAISE NOTICE 'Rows loaded: %', v_crm_sales_rows;


    -- ========================================================
    -- ERP TABLES
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '----------------------------------------------------';


    RAISE NOTICE 'Loading: bronze.erp_cust_az12';

    SELECT COUNT(*)
    INTO v_erp_cust_rows
    FROM bronze.erp_cust_az12;

    RAISE NOTICE 'Rows loaded: %', v_erp_cust_rows;


    RAISE NOTICE 'Loading: bronze.erp_loc_a101';

    SELECT COUNT(*)
    INTO v_erp_loc_rows
    FROM bronze.erp_loc_a101;

    RAISE NOTICE 'Rows loaded: %', v_erp_loc_rows;


    RAISE NOTICE 'Loading: bronze.erp_px_cat_g1v2';

    SELECT COUNT(*)
    INTO v_erp_cat_rows
    FROM bronze.erp_px_cat_g1v2;

    RAISE NOTICE 'Rows loaded: %', v_erp_cat_rows;


    -- ========================================================
    -- END TIME & DURATION
    -- ========================================================

    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;


    -- ========================================================
    -- SAVE SUCCESS LOG
    -- ========================================================

    INSERT INTO bronze.load_log
    (
        start_time,
        end_time,
        duration,
        status,

        crm_cust_rows,
        crm_prd_rows,
        crm_sales_rows,

        erp_cust_rows,
        erp_loc_rows,
        erp_cat_rows
    )
    VALUES
    (
        v_start_time,
        v_end_time,
        v_duration,
        'SUCCESS',

        v_crm_cust_rows,
        v_crm_prd_rows,
        v_crm_sales_rows,

        v_erp_cust_rows,
        v_erp_loc_rows,
        v_erp_cat_rows
    );


    -- ========================================================
    -- FINAL OUTPUT
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '          BRONZE LAYER LOAD COMPLETED';
    RAISE NOTICE '====================================================';

    RAISE NOTICE 'End Time: %', v_end_time;
    RAISE NOTICE 'Total Duration: %', v_duration;

    RAISE NOTICE '';
    RAISE NOTICE 'CRM Customer Rows : %', v_crm_cust_rows;
    RAISE NOTICE 'CRM Product Rows  : %', v_crm_prd_rows;
    RAISE NOTICE 'CRM Sales Rows    : %', v_crm_sales_rows;

    RAISE NOTICE '';
    RAISE NOTICE 'ERP Customer Rows : %', v_erp_cust_rows;
    RAISE NOTICE 'ERP Location Rows : %', v_erp_loc_rows;
    RAISE NOTICE 'ERP Category Rows : %', v_erp_cat_rows;

    RAISE NOTICE '';
    RAISE NOTICE 'Status: SUCCESS';
    RAISE NOTICE '====================================================';


EXCEPTION
    WHEN OTHERS THEN

        v_end_time := clock_timestamp();

        v_duration := v_end_time - v_start_time;


        -- ====================================================
        -- SAVE FAILURE LOG
        -- ====================================================

        INSERT INTO bronze.load_log
        (
            start_time,
            end_time,
            duration,
            status
        )
        VALUES
        (
            v_start_time,
            v_end_time,
            v_duration,
            'FAILED'
        );


        RAISE NOTICE '';
        RAISE NOTICE '====================================================';
        RAISE NOTICE '          BRONZE LAYER LOAD FAILED';
        RAISE NOTICE '====================================================';

        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE NOTICE 'Duration: %', v_duration;

        RAISE;

END;
$$;


-- ============================================================
-- 3. EXECUTE THE PROCEDURE
-- ============================================================

CALL bronze.load_bronze();


-- ============================================================
-- 4. VIEW LOAD RESULT
-- ============================================================

SELECT
    load_id,
    start_time,
    end_time,
    duration,
    status,
    crm_cust_rows,
    crm_prd_rows,
    crm_sales_rows,
    erp_cust_rows,
    erp_loc_rows,
    erp_cat_rows
FROM bronze.load_log
ORDER BY load_id DESC
LIMIT 1;

CALL bronze.load_bronze();


--=======================================================================
--======================================================================
-- ============================================================
-- BRONZE LAYER LOAD PROCEDURE
-- PostgreSQL + DataGrip
-- ============================================================


-- ============================================================
-- 1. CREATE BRONZE SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS bronze;


-- ============================================================
-- 2. CREATE LOAD LOG TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS bronze.load_log
(
    load_id          BIGSERIAL PRIMARY KEY,

    start_time       TIMESTAMP NOT NULL,
    end_time         TIMESTAMP NOT NULL,
    duration         INTERVAL NOT NULL,

    status           VARCHAR(20) NOT NULL,

    crm_cust_rows    BIGINT,
    crm_prd_rows     BIGINT,
    crm_sales_rows   BIGINT,

    erp_cust_rows    BIGINT,
    erp_loc_rows     BIGINT,
    erp_cat_rows     BIGINT
);


-- ============================================================
-- 3. CREATE / REPLACE PROCEDURE
-- ============================================================

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE

    -- --------------------------------------------------------
    -- Timing variables
    -- --------------------------------------------------------

    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
    v_duration   INTERVAL;


    -- --------------------------------------------------------
    -- Row-count variables
    -- --------------------------------------------------------

    v_crm_cust_rows  BIGINT;
    v_crm_prd_rows   BIGINT;
    v_crm_sales_rows BIGINT;

    v_erp_cust_rows  BIGINT;
    v_erp_loc_rows   BIGINT;
    v_erp_cat_rows   BIGINT;


BEGIN

    -- ========================================================
    -- START TIMER
    -- ========================================================

    v_start_time := clock_timestamp();


    -- ========================================================
    -- HEADER
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '              BRONZE LAYER LOAD';
    RAISE NOTICE '====================================================';

    RAISE NOTICE 'Start Time: %', v_start_time;


    -- ========================================================
    -- CRM TABLES
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '----------------------------------------------------';


    -- --------------------------------------------------------
    -- CRM CUSTOMER
    -- --------------------------------------------------------

    RAISE NOTICE 'Loading: bronze.crm_cust_info';

    SELECT COUNT(*)
    INTO v_crm_cust_rows
    FROM bronze.crm_cust_info;

    RAISE NOTICE 'Rows loaded: %', v_crm_cust_rows;


    -- --------------------------------------------------------
    -- CRM PRODUCT
    -- --------------------------------------------------------

    RAISE NOTICE 'Loading: bronze.crm_prd_info';

    SELECT COUNT(*)
    INTO v_crm_prd_rows
    FROM bronze.crm_prd_info;

    RAISE NOTICE 'Rows loaded: %', v_crm_prd_rows;


    -- --------------------------------------------------------
    -- CRM SALES
    -- --------------------------------------------------------

    RAISE NOTICE 'Loading: bronze.crm_sales_details';

    SELECT COUNT(*)
    INTO v_crm_sales_rows
    FROM bronze.crm_sales_details;

    RAISE NOTICE 'Rows loaded: %', v_crm_sales_rows;


    -- ========================================================
    -- ERP TABLES
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '----------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '----------------------------------------------------';


    -- --------------------------------------------------------
    -- ERP CUSTOMER
    -- --------------------------------------------------------

    RAISE NOTICE 'Loading: bronze.erp_cust_az12';

    SELECT COUNT(*)
    INTO v_erp_cust_rows
    FROM bronze.erp_cust_az12;

    RAISE NOTICE 'Rows loaded: %', v_erp_cust_rows;


    -- --------------------------------------------------------
    -- ERP LOCATION
    -- --------------------------------------------------------

    RAISE NOTICE 'Loading: bronze.erp_loc_a101';

    SELECT COUNT(*)
    INTO v_erp_loc_rows
    FROM bronze.erp_loc_a101;

    RAISE NOTICE 'Rows loaded: %', v_erp_loc_rows;


    -- --------------------------------------------------------
    -- ERP PRODUCT CATEGORY
    -- --------------------------------------------------------

    RAISE NOTICE 'Loading: bronze.erp_px_cat_g1v2';

    SELECT COUNT(*)
    INTO v_erp_cat_rows
    FROM bronze.erp_px_cat_g1v2;

    RAISE NOTICE 'Rows loaded: %', v_erp_cat_rows;


    -- ========================================================
    -- STOP TIMER
    -- ========================================================

    v_end_time := clock_timestamp();

    v_duration := v_end_time - v_start_time;


    -- ========================================================
    -- SAVE LOAD INFORMATION
    -- ========================================================

    INSERT INTO bronze.load_log
    (
        start_time,
        end_time,
        duration,
        status,

        crm_cust_rows,
        crm_prd_rows,
        crm_sales_rows,

        erp_cust_rows,
        erp_loc_rows,
        erp_cat_rows
    )
    VALUES
    (
        v_start_time,
        v_end_time,
        v_duration,
        'SUCCESS',

        v_crm_cust_rows,
        v_crm_prd_rows,
        v_crm_sales_rows,

        v_erp_cust_rows,
        v_erp_loc_rows,
        v_erp_cat_rows
    );


    -- ========================================================
    -- FINAL OUTPUT
    -- ========================================================

    RAISE NOTICE '';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '          BRONZE LAYER LOAD COMPLETED';
    RAISE NOTICE '====================================================';

    RAISE NOTICE 'Start Time : %', v_start_time;
    RAISE NOTICE 'End Time   : %', v_end_time;
    RAISE NOTICE 'Duration   : %', v_duration;

    RAISE NOTICE '';

    RAISE NOTICE 'CRM Customer Rows : %', v_crm_cust_rows;
    RAISE NOTICE 'CRM Product Rows  : %', v_crm_prd_rows;
    RAISE NOTICE 'CRM Sales Rows    : %', v_crm_sales_rows;

    RAISE NOTICE '';

    RAISE NOTICE 'ERP Customer Rows : %', v_erp_cust_rows;
    RAISE NOTICE 'ERP Location Rows : %', v_erp_loc_rows;
    RAISE NOTICE 'ERP Category Rows : %', v_erp_cat_rows;

    RAISE NOTICE '';

    RAISE NOTICE 'STATUS: SUCCESS';

    RAISE NOTICE '====================================================';


-- =========================================================
-- ERROR HANDLING
-- =========================================================

EXCEPTION
    WHEN OTHERS THEN

        v_end_time := clock_timestamp();

        v_duration := v_end_time - v_start_time;


        -- ----------------------------------------------------
        -- Save failed load
        -- ----------------------------------------------------

        INSERT INTO bronze.load_log
        (
            start_time,
            end_time,
            duration,
            status,

            crm_cust_rows,
            crm_prd_rows,
            crm_sales_rows,

            erp_cust_rows,
            erp_loc_rows,
            erp_cat_rows
        )
        VALUES
        (
            v_start_time,
            v_end_time,
            v_duration,
            'FAILED',

            v_crm_cust_rows,
            v_crm_prd_rows,
            v_crm_sales_rows,

            v_erp_cust_rows,
            v_erp_loc_rows,
            v_erp_cat_rows
        );


        -- ----------------------------------------------------
        -- Display error
        -- ----------------------------------------------------

        RAISE NOTICE '';
        RAISE NOTICE '====================================================';
        RAISE NOTICE '          BRONZE LAYER LOAD FAILED';
        RAISE NOTICE '====================================================';

        RAISE NOTICE 'Error    : %', SQLERRM;
        RAISE NOTICE 'Duration : %', v_duration;

        RAISE NOTICE '====================================================';


        RAISE;

END;
$$;


-- ============================================================
-- 4. EXECUTE THE PROCEDURE
-- ============================================================

CALL bronze.load_bronze();


-- ============================================================
-- 5. SHOW LAST LOAD RESULT
-- ============================================================

SELECT
    load_id,
    start_time,
    end_time,
    duration,
    status,
    crm_cust_rows,
    crm_prd_rows,
    crm_sales_rows,
    erp_cust_rows,
    erp_loc_rows,
    erp_cat_rows
FROM bronze.load_log
ORDER BY load_id DESC
LIMIT 1;
