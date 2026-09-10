USE NMCapitalOutlay;
GO

-- Create temp tables
CREATE TABLE #ProjectLanding (
	LegislativeYear smallint NULL,
	Bill nvarchar(10) NULL,
	WebID int NULL,
	ChapterSection varchar(50) NULL,
	ProjectTitle nvarchar(255) NULL,
	FundCode varchar(10) NULL,
	CityLocale nvarchar(50) NULL,
	County nvarchar(50) NULL,
	AgencyCode varchar(10) NULL,
	StatusFlag varchar(10) NULL,
	ProjectTotalAfterVetoes int NULL,
	SourcePage int NULL
	);

CREATE TABLE #AppropriationLanding (
	LegislativeYear smallint NULL,
	Bill nvarchar(10) NULL,
	WebID int NULL,
	Sponsor nvarchar(100) NULL,
    Amount int NULL,
	SourcePage int NULL
	);

-- Load data from csv
BULK INSERT #ProjectLanding
FROM 'C:\SQLData\HB450_2025_Statewide_projects.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);

BULK INSERT #AppropriationLanding
FROM 'C:\SQLData\HB450_2025_Statewide_appropriations.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);

-- Verify incoming files loaded

-- Clear Staging tables in case data remains from previous run
TRUNCATE TABLE Staging.Project;
TRUNCATE TABLE Staging.Appropriation;

-- Load temporary batch into staging tables
INSERT INTO Staging.Project(
    LegislativeYear,
    Bill,
    WebID,
    ChapterSection,
    ProjectTitle,
    FundCode,
    CityLocale,
    County,
    AgencyCode,
    StatusFlag,
    ProjectTotalAfterVetoes,
    SourcePage
)
SELECT
    LegislativeYear,
    Bill,
    WebID,
    ChapterSection,
    ProjectTitle,
    FundCode,
    CityLocale,
    County,
    AgencyCode,
    StatusFlag,
    ProjectTotalAfterVetoes,
    SourcePage
FROM #ProjectLanding;

INSERT INTO Staging.Appropriation(
    LegislativeYear,
    Bill,
    WebID,
    Sponsor,
    Amount,
    SourcePage
)
SELECT
    LegislativeYear,
    Bill,
    WebID,
    Sponsor,
    Amount,
    SourcePage
FROM #AppropriationLanding;

-- Validate staging data before normalization
-- Is any part of the Business Key missing?
SELECT LegislativeYear, Bill, WebID
FROM Staging.Project
WHERE LegislativeYear IS NULL
    OR Bill IS NULL
    OR WebID IS Null;

-- Do any Business Keys occur more than once?
SELECT LegislativeYear, Bill, WebID
FROM Staging.Project
GROUP BY LegislativeYear, Bill, WebID
HAVING COUNT(*) > 1;

-- Are any Project Titles missing?
SELECT LegislativeYear, Bill, WebID
FROM Staging.Project
WHERE ProjectTitle IS NULL;

-- Is any part of the Business Key missing?
SELECT LegislativeYear, Bill, WebID
FROM Staging.Appropriation
WHERE LegislativeYear IS NULL
    OR Bill IS NULL
    OR WebID IS Null;

-- Do any Sponsors appear more than once for the same project?
SELECT LegislativeYear, Bill, WebID, Sponsor
FROM Staging.Appropriation
GROUP BY LegislativeYear, Bill, WebID, Sponsor
HAVING COUNT(*) > 1;

-- Are any Sponsors or Amounts missing?
SELECT LegislativeYear, Bill, WebID, Sponsor, Amount
FROM Staging.Appropriation
WHERE Sponsor IS NULL
    OR Amount IS NULL;

-- Does every appropriation have a corresponding project in Staging.Project?
SELECT A.LegislativeYear, A.Bill, A.WebID
FROM Staging.Appropriation AS A
LEFT JOIN Staging.Project AS P 
    ON P.LegislativeYear = A.LegislativeYear
    AND P.Bill = A.Bill
    AND P.WebID = A.WebID
WHERE P.StageProjectID IS NULL;

-- Does the sum of all appropriation amounts equal that projects ProjectTotalAfterVetoes?
SELECT P.LegislativeYear, P.Bill, P.WebID, SUM(A.Amount) AS AppropriationTotal, P.ProjectTotalAfterVetoes, P.StatusFlag
FROM Staging.Appropriation AS A
JOIN Staging.Project AS P
    ON P.LegislativeYear = A.LegislativeYear
    AND P.Bill = A.Bill
    AND P.WebID = A.WebID
WHERE P.StatusFlag <> 'VETO'
GROUP BY P.LegislativeYear, P.Bill, P.WebID, P.ProjectTotalAfterVetoes, P.StatusFlag
HAVING SUM(A.Amount) <> P.ProjectTotalAfterVetoes;

-- Normalize Data.
-- Update Agency if new Agencies appear
INSERT INTO CIPReporting.Agency (AgencyCode)
SELECT DISTINCT P.AgencyCode
FROM Staging.Project AS P
LEFT JOIN CIPReporting.Agency AS A
    ON P.AgencyCode = A.AgencyCode
WHERE A.AgencyID IS NULL
    AND P.AgencyCode IS NOT NULL;

-- Update Fund if new Funds appear
INSERT INTO CIPReporting.Fund (FundCode)
SELECT DISTINCT P.FundCode
FROM Staging.Project AS P
LEFT JOIN CIPReporting.Fund AS F
    ON P.FundCode = F.FundCode
WHERE F.FundID IS NULL
    AND P.FundCode IS NOT NULL;

-- Update Sponsor if new Sponsors appear
INSERT INTO CIPReporting.Sponsor (SponsorName)
SELECT DISTINCT A.Sponsor
FROM Staging.Appropriation AS A
LEFT JOIN CIPReporting.Sponsor AS S
    ON S.SponsorName = A.Sponsor
WHERE S.SponsorID IS NULL
    AND A.Sponsor IS NOT NULL;

-- Update LegislativeProject with new projects, and add lookup IDs for Agency, Fund, and Sponsor
INSERT INTO CIPReporting.LegislativeProject (
    LegislativeYear,
    Bill,
    WebID,
    ProjectTitle,
    ChapterSection,
    CityLocale,
    County,
    StatusFlag,
    ProjectTotalAfterVetoes,
    AgencyID,
    FundID
    )
SELECT 
    P.LegislativeYear,
    P.Bill,
    P.WebID,
    P.ProjectTitle,
    P.ChapterSection,
    P.CityLocale,
    P.County,
    P.StatusFlag,
    P.ProjectTotalAfterVetoes,
    A.AgencyID,
    F.FundID
FROM Staging.Project AS P
LEFT JOIN CIPReporting.Agency AS A
    ON P.AgencyCode = A.AgencyCode
LEFT JOIN CIPReporting.Fund AS F
    ON P.FundCode = F.FundCode
LEFT JOIN CIPReporting.LegislativeProject AS LP
    ON P.LegislativeYear = LP.LegislativeYear
    AND P.Bill = LP.Bill
    AND P.WebID = LP.WebID
WHERE LP.LegislativeProjectID IS NULL
;


-- Update Appropriation with new project appropriations and lookup for SponsorID
INSERT INTO CIPReporting.Appropriation (
    LegislativeProjectID,
    SponsorID,
    Amount
    ) 
SELECT 
    LP.LegislativeProjectID,
    S.SponsorID,
    A.Amount
FROM Staging.Appropriation AS A
LEFT JOIN CIPReporting.Sponsor AS S
    ON S.SponsorName = A.Sponsor
LEFT JOIN CIPReporting.LegislativeProject AS LP
    ON A.LegislativeYear = LP.LegislativeYear
    AND A.Bill = LP.Bill
    AND A.WebID = LP.WebID
LEFT JOIN CIPReporting.Appropriation AS AP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
    AND AP.SponsorID = S.SponsorID
WHERE AP.SponsorID IS NULL
    AND AP.LegislativeProjectID IS NULL
;




-- Clean staging tables after successful completion of data load to normalized tables
TRUNCATE TABLE Staging.Appropriation;
TRUNCATE TABLE Staging.Project;