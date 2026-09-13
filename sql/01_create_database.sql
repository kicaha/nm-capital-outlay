/*
    Project: New Mexico Capital Outlay Analysis
    Script:  01_create_database.sql
    Purpose: Create the project database if it does not already exist.
*/

-- Start with the system database in case NMCapitalOutlay has not yet been created 
USE master;

/* Check to see if the NMCapitalOutlay database has already been created
If NULL (does not exist), create it
*/

IF DB_ID('NMCapitalOutlay') IS NULL
BEGIN
    CREATE DATABASE NMCapitalOutlay;
END;
