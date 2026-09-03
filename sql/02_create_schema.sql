/*
    Project: New Mexico Capital Outlay Analysis
    Script:  02_create_schema.sql
    Purpose: Create the CIPReporting schema if it does not already exist.
*/

USE NMCapitalOutlay;
GO

IF SCHEMA_ID('CIPReporting') IS NULL
BEGIN
    EXEC('CREATE SCHEMA CIPReporting');
END;
GO