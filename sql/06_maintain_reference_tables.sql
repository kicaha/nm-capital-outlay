/*
    Project: New Mexico Capital Outlay Analysis
    Script:  06_maintain_reference_tables.sql
    Purpose: Identify and maintain Agency and Fund reference codes
*/

USE NMCapitalOutlay;

/* ============================================================
   1. LAND DATA
   ============================================================ */

/*
    The landing table is intentionally permissive. Its purpose 
    is to receive the source CSV faithfully and hold the data while 
    missing codes are identified. 
    
    The only required fields are the Business Key (LegislativeYear, 
    Bill, WebID), FundCode, and AgencyCode. The remaining fields are
    only included due to the nature of BULK INSERT and are all nullable.

*/
CREATE TABLE #Landing (
    LegislativeYear smallint NOT NULL,
    Bill varchar(10) NOT NULL,
    WebID int NOT NULL,
    ChapterSection varchar(50) NULL,
    ProjectTitle nvarchar(255) NULL,
    FundCode varchar(10) NOT NULL,
    CityLocale nvarchar(50) NULL,
    County nvarchar(50) NULL,
    AgencyCode varchar(10) NOT NULL,
    StatusFlag varchar(10) NULL,
    ProjectTotalAfterVetoes int NULL,
    SourcePage int NULL
);

BULK INSERT #Landing
FROM 'C:\SQLData\HB285_2021_Statewide_projects.csv' -- Change filename as needed
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);
/* ============================================================
   2. CHECK FOR MISSING CODES
   ============================================================ */

/*
    These queries are to see if any new codes are found
    in the #Landing table that are not found in the 
    reference tables yet.
*/

SELECT DISTINCT L.FundCode
FROM #Landing AS L
LEFT JOIN CapitalOutlay.Fund AS F
    ON L.FundCode = F.FundCode
WHERE F.FundCode IS NULL;

SELECT DISTINCT L.AgencyCode
FROM #Landing AS L
LEFT JOIN CapitalOutlay.Agency AS A
    ON L.AgencyCode = A.AgencyCode
WHERE A.AgencyCode IS NULL;

/* ============================================================
   3. INSERT MISSING CODES
   ============================================================ */

/*
    Review all codes returned above before inserting them.

    After confirming that a new code is legitimate, manually insert it
    into the appropriate reference table using the structure below.
    Replace the placeholder values before execution.

    To insert Funds or Agencies, uncomment the code below, modify as needed
    and run that section. 
*/

-- Code for inserting Funds
/*
INSERT INTO CapitalOutlay.Fund (
    FundCode,
    FundName
)
VALUES
    ('CODE01', NULL),
    ('CODE02', NULL);
*/

-- Code for inserting Agencies
/*
INSERT INTO CapitalOutlay.Agency (
    AgencyCode,
    AgencyName
)
VALUES
    ('CODE01', NULL),
    ('CODE02', NULL);
*/

/* ============================================================
   4. VERIFY
   ============================================================ */

/*
    After inserting all approved codes, rerun the queries in Section 2.

    Both queries should return zero rows before proceeding with the
    project load.
*/