/*
    Project: New Mexico Capital Outlay Analysis
    Script:  02_create_schema.sql
    Purpose: Create the CapitalOutlay and Staging schemas if they do not already exist.
*/

-- Set the database to NMCapitalOutlay
USE NMCapitalOutlay;

/* ============================================================
   1. CREATE SCHEMAS IF THEY DO NOT ALREADY EXIST
   ============================================================ */

/*If the CapitalOutlay schema does not exist (IS NULL) create it
NOTE: EXEC('CREATE SCHEMA CapitalOutlay') is due to batch restrictions on the CREATE SCHEMA statement
where it must be the first statement in a batch. Buried in the IF statement here, it cannot be so
it is wrapped in an EXEC statement to be executed dynamically.
*/
IF SCHEMA_ID('CapitalOutlay') IS NULL
BEGIN
    EXEC('CREATE SCHEMA CapitalOutlay');
END;

-- If the Staging schema does not exist (IS NULL) create it
-- Same reasoning for the EXEC statement as above
IF SCHEMA_ID('Staging') IS NULL
BEGIN
    EXEC('CREATE SCHEMA Staging');
END;