/*
    Project: New Mexico Capital Outlay Analysis
    Script:  01_create_database.sql
    Purpose: Create the project database if it does not already exist.
*/

USE master;
GO

IF DB_ID('NMCapitalOutlay') IS NULL
BEGIN
    CREATE DATABASE NMCapitalOutlay;
END;
GO

USE NMCapitalOutlay;
GO