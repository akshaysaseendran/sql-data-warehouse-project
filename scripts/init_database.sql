/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates the 'datawarehouse' database.
    If the database already exists, it is dropped and recreated.
    Three schemas are then created:
    'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will delete the entire 'datawarehouse'
    database if it already exists.
=============================================================
*/

-- Run this section while connected to the 'postgres' database

DROP DATABASE IF EXISTS datawarehouse;

CREATE DATABASE datawarehouse;



-- create database  'datawarehouse'




CREATE DATABASE datawarehouse;


CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
