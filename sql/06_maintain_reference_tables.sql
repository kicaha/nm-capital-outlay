/*
    Project: New Mexico Capital Outlay Analysis
    Script:  06_maintain_reference_tables.sql
    Purpose: Identify and maintain Agency, Fund, and Sponsor reference mappings
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
DROP TABLE IF EXISTS #Landing;

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
    Identify Fund and Agency codes present in the annual project
    source that do not yet exist in the normalized reference tables.

    FundCode and AgencyCode come directly from the project source.
    Unlike Sponsor identity, these codes do not require identity
    resolution before they can be added.

    The source file does not provide FundName or AgencyName, so new
    reference records are created with the name left NULL.
*/

SELECT DISTINCT L.FundCode
FROM #Landing AS L
LEFT JOIN CapitalOutlay.Fund AS F
    ON L.FundCode = F.FundCode
WHERE F.FundID IS NULL
ORDER BY L.FundCode;

SELECT DISTINCT L.AgencyCode
FROM #Landing AS L
LEFT JOIN CapitalOutlay.Agency AS A
    ON L.AgencyCode = A.AgencyCode
WHERE A.AgencyID IS NULL
ORDER BY L.AgencyCode;


/* ============================================================
   3. INSERT MISSING CODES
   ============================================================ */

/*
    Add reference codes found in the annual source that do not yet
    exist in Fund or Agency.

    These INSERT statements are safe to rerun because NOT EXISTS
    prevents an existing code from being inserted again.
*/

INSERT INTO CapitalOutlay.Fund (FundCode, FundName)
SELECT DISTINCT
    L.FundCode,
    NULL
FROM #Landing AS L
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.Fund AS F
    WHERE F.FundCode = L.FundCode
);

INSERT INTO CapitalOutlay.Agency (AgencyCode, AgencyName)
SELECT DISTINCT
    L.AgencyCode,
    NULL
FROM #Landing AS L
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.Agency AS A
    WHERE A.AgencyCode = L.AgencyCode
);


/* ============================================================
   4. VERIFY REFERENCE CODES
   ============================================================ */

/*
    Both queries should return zero rows after Section 3.

    Any returned row indicates that a source code still does not have
    a corresponding normalized reference record and should be
    investigated before running 07_load_projects.sql.
*/

SELECT DISTINCT L.FundCode
FROM #Landing AS L
LEFT JOIN CapitalOutlay.Fund AS F
    ON L.FundCode = F.FundCode
WHERE F.FundID IS NULL
ORDER BY L.FundCode;

SELECT DISTINCT L.AgencyCode
FROM #Landing AS L
LEFT JOIN CapitalOutlay.Agency AS A
    ON L.AgencyCode = A.AgencyCode
WHERE A.AgencyID IS NULL
ORDER BY L.AgencyCode;


/* ============================================================
   5. MAINTAIN SPONSOR ALIASES
   ============================================================ */

/*
    Appropriation source data identifies sponsors using source labels
    that may not exactly match normalized Sponsor records.

    This section automatically creates an alias only when an exact
    source label matches exactly one Sponsor in the normalized Sponsor
    table AND that Sponsor has SponsorService in the appropriation year.
    Because SponsorAlias is global rather than year-specific, labels that
    match multiple Sponsors overall are not auto-resolved even if only
    one of them served in the current year.

    Labels with zero or multiple year-valid candidates remain unresolved
    for human review. Blank Sponsor values are valid and require no alias.
*/


/* ------------------------------------------------------------
   5A. LAND APPROPRIATION SPONSOR DATA
   ------------------------------------------------------------ */

DROP TABLE IF EXISTS #AppropriationReferenceLanding;

CREATE TABLE #AppropriationReferenceLanding (
    LegislativeYear nvarchar(20) NULL,
    Bill nvarchar(20) NULL,
    WebID nvarchar(20) NULL,
    Sponsor nvarchar(255) NULL,
    Amount nvarchar(50) NULL,
    SourcePage nvarchar(20) NULL
);

BULK INSERT #AppropriationReferenceLanding
FROM 'C:\SQLData\HB285_2021_Statewide_appropriations.csv' -- Change filename as needed
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);


/* ------------------------------------------------------------
   5B. BUILD YEAR-VALID SPONSOR CANDIDATES
   ------------------------------------------------------------ */

DROP TABLE IF EXISTS #SponsorCandidates;

SELECT DISTINCT
    TRY_CONVERT(smallint, TRIM(L.LegislativeYear)) AS LegislativeYear,
    TRIM(L.Sponsor) AS SourceSponsorLabel,
    S.SponsorID,
    S.DisplayName,
    CASE WHEN EXISTS (
        SELECT 1
        FROM CapitalOutlay.SponsorService AS SS
        WHERE SS.SponsorID = S.SponsorID
          AND SS.ServiceYear = TRY_CONVERT(smallint, TRIM(L.LegislativeYear))
    ) THEN 1 ELSE 0 END AS ServesInSourceYear
INTO #SponsorCandidates
FROM #AppropriationReferenceLanding AS L
INNER JOIN CapitalOutlay.Sponsor AS S
    ON TRIM(L.Sponsor) = S.LastName
    OR TRIM(L.Sponsor) = S.DisplayName
WHERE NULLIF(TRIM(L.Sponsor), '') IS NOT NULL;


/* ------------------------------------------------------------
   5C. CREATE SAFE AUTOMATIC ALIASES
   ------------------------------------------------------------ */

/*
    An alias is created only when the source label has exactly one
    year-valid Sponsor candidate in the landed appropriation source.

    Existing aliases are never overwritten.
*/

WITH CandidateCounts AS (
    SELECT
        SourceSponsorLabel,
        COUNT(DISTINCT SponsorID) AS CandidateCount
    FROM #SponsorCandidates
    GROUP BY
        SourceSponsorLabel
),
UniqueCandidates AS (
    SELECT
        C.SourceSponsorLabel,
        C.SponsorID
    FROM #SponsorCandidates AS C
    INNER JOIN CandidateCounts AS CC
        ON C.SourceSponsorLabel = CC.SourceSponsorLabel
    WHERE CC.CandidateCount = 1
      AND C.ServesInSourceYear = 1
)
INSERT INTO CapitalOutlay.SponsorAlias (
    SourceSponsorLabel,
    SponsorID,
    IsAutoResolvable
)
SELECT DISTINCT
    U.SourceSponsorLabel,
    U.SponsorID,
    1
FROM UniqueCandidates AS U
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorAlias AS SA
    WHERE SA.SourceSponsorLabel = U.SourceSponsorLabel
);


/* ------------------------------------------------------------
   5D. REVIEW AMBIGUOUS YEAR-VALID MATCHES
   ------------------------------------------------------------ */

/*
    Returned labels have more than one Sponsor candidate serving in
    the source year. They are intentionally not auto-resolved.
*/

WITH CandidateCounts AS (
    SELECT
        SourceSponsorLabel,
        COUNT(DISTINCT SponsorID) AS CandidateCount
    FROM #SponsorCandidates
    GROUP BY
        SourceSponsorLabel
)
SELECT
    C.LegislativeYear,
    C.SourceSponsorLabel,
    C.SponsorID,
    C.DisplayName,
    C.ServesInSourceYear,
    CC.CandidateCount
FROM #SponsorCandidates AS C
INNER JOIN CandidateCounts AS CC
    ON C.SourceSponsorLabel = CC.SourceSponsorLabel
LEFT JOIN CapitalOutlay.SponsorAlias AS SA
    ON C.SourceSponsorLabel = SA.SourceSponsorLabel
WHERE CC.CandidateCount > 1
  AND SA.SponsorAliasID IS NULL
ORDER BY
    C.SourceSponsorLabel,
    C.DisplayName;


/* ------------------------------------------------------------
   5E. REVIEW REMAINING UNRESOLVED LABELS
   ------------------------------------------------------------ */

/*
    These labels were not safe for automatic alias creation. They may
    have no Sponsor candidate, multiple Sponsor candidates, or a single
    candidate who did not serve in the source year.
*/

SELECT
    TRY_CONVERT(smallint, TRIM(L.LegislativeYear)) AS LegislativeYear,
    TRIM(L.Sponsor) AS SourceSponsorLabel,
    COUNT(*) AS AppropriationCount
FROM #AppropriationReferenceLanding AS L
LEFT JOIN CapitalOutlay.SponsorAlias AS SA
    ON TRIM(L.Sponsor) = SA.SourceSponsorLabel
WHERE NULLIF(TRIM(L.Sponsor), '') IS NOT NULL
  AND SA.SponsorAliasID IS NULL
GROUP BY
    TRY_CONVERT(smallint, TRIM(L.LegislativeYear)),
    TRIM(L.Sponsor)
ORDER BY
    AppropriationCount DESC,
    SourceSponsorLabel;


/* ------------------------------------------------------------
   5F. HUMAN-REVIEW TEMPLATES
   ------------------------------------------------------------ */

/*
    Use only when review establishes a mapping that cannot be created
    automatically above.

    MISSING SPONSOR TEMPLATE:

    INSERT INTO CapitalOutlay.Sponsor (
        GivenName, LastName, SponsorType, DisplayName
    )
    VALUES (
        'Given Name', 'Last Name', 'Person', 'Display Name'
    );

    APPROVED ALIAS TEMPLATE:

    INSERT INTO CapitalOutlay.SponsorAlias (
        SourceSponsorLabel, SponsorID, IsAutoResolvable
    )
    VALUES (
        'SOURCE LABEL', 123, 1
    );
*/


/* ------------------------------------------------------------
   5G. VERIFY REMAINING UNMAPPED SPONSOR LABELS
   ------------------------------------------------------------ */

SELECT
    TRIM(L.Sponsor) AS SourceSponsorLabel,
    COUNT(*) AS AppropriationCount
FROM #AppropriationReferenceLanding AS L
LEFT JOIN CapitalOutlay.SponsorAlias AS SA
    ON TRIM(L.Sponsor) = SA.SourceSponsorLabel
WHERE NULLIF(TRIM(L.Sponsor), '') IS NOT NULL
  AND SA.SponsorAliasID IS NULL
GROUP BY
    TRIM(L.Sponsor)
ORDER BY
    AppropriationCount DESC,
    SourceSponsorLabel;


/* ------------------------------------------------------------
   5H. APPLY AUTO-RESOLVABLE ALIASES TO EXISTING APPROPRIATIONS
   ------------------------------------------------------------ */

UPDATE A
SET A.SponsorID = SA.SponsorID
FROM CapitalOutlay.Appropriation AS A
INNER JOIN CapitalOutlay.SponsorAlias AS SA
    ON A.SourceSponsorLabel = SA.SourceSponsorLabel
WHERE A.SponsorID IS NULL
  AND SA.IsAutoResolvable = 1;


/* ------------------------------------------------------------
   5I. SPONSOR RESOLUTION SUMMARY
   ------------------------------------------------------------ */

SELECT
    P.LegislativeYear,
    COUNT(*) AS TotalAppropriations,
    SUM(CASE
            WHEN A.SponsorID IS NOT NULL
            THEN 1 ELSE 0
        END) AS ResolvedSponsor,
    SUM(CASE
            WHEN A.SponsorID IS NULL
             AND NULLIF(TRIM(A.SourceSponsorLabel), '') IS NOT NULL
            THEN 1 ELSE 0
        END) AS UnresolvedSponsor,
    SUM(CASE
            WHEN A.SponsorID IS NULL
             AND NULLIF(TRIM(A.SourceSponsorLabel), '') IS NULL
            THEN 1 ELSE 0
        END) AS BlankSourceSponsor
FROM CapitalOutlay.Appropriation AS A
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeProjectID = P.LegislativeProjectID
GROUP BY
    P.LegislativeYear
ORDER BY
    P.LegislativeYear;
