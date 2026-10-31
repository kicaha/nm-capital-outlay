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

/* ============================================================
   5. MAINTAIN SPONSOR ALIASES
   ============================================================ */

/*
    Appropriation source data identifies sponsors using source labels
    that may not exactly match normalized Sponsor records.

    SponsorAlias is the controlled mapping between an exact source
    label and an established Sponsor record.

    The appropriation source may identify legitimate sponsors who are
    not present in Sponsor. The annual legislator roster is therefore
    not treated as a complete authority for every sponsor appearing in
    appropriation data.

    Maintenance process:

        1. Land the annual appropriation source.
        2. Identify source labels that do not yet have an alias.
        3. Review possible existing Sponsor matches.
        4. Review labels with no existing Sponsor candidate.
        5. Create missing Sponsor records only when identity is known.
        6. Create approved SponsorAlias mappings.
        7. Verify the remaining unresolved labels.
        8. Optionally apply newly approved aliases to appropriations
           that were loaded before the alias existed.

    IsAutoResolvable = 1 means the exact source label can safely and
    consistently resolve to the selected Sponsor.

    IsAutoResolvable = 0 retains a reviewed relationship without
    allowing automatic SponsorID assignment.

    An unresolved nonblank Sponsor label does NOT invalidate an
    appropriation. 08_load_appropriations.sql preserves the source
    label and loads SponsorID as NULL.

    Blank Sponsor values are valid source data and require no alias.
*/


/* ------------------------------------------------------------
   5A. LAND APPROPRIATION SPONSOR DATA
   ------------------------------------------------------------ */

/*
    This landing table exists only for Sponsor reference maintenance.
    Full appropriation validation occurs in 08_load_appropriations.sql.
*/

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
   5B. IDENTIFY UNMAPPED SOURCE SPONSOR LABELS
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
   5C. FIND POSSIBLE EXISTING SPONSOR MATCHES
   ------------------------------------------------------------ */

/*
    CandidateCount shows whether a source label has one or multiple
    possible existing Sponsor matches. These are review candidates
    only; this query does not create aliases automatically.
*/

WITH CandidateMatches AS (
    SELECT DISTINCT
        TRIM(L.Sponsor) AS SourceSponsorLabel,
        S.SponsorID,
        S.GivenName,
        S.LastName,
        S.DisplayName,
        S.SponsorType
    FROM #AppropriationReferenceLanding AS L
    LEFT JOIN CapitalOutlay.SponsorAlias AS SA
        ON TRIM(L.Sponsor) = SA.SourceSponsorLabel
    INNER JOIN CapitalOutlay.Sponsor AS S
        ON TRIM(L.Sponsor) = S.LastName
        OR TRIM(L.Sponsor) = S.DisplayName
    WHERE NULLIF(TRIM(L.Sponsor), '') IS NOT NULL
      AND SA.SponsorAliasID IS NULL
)
SELECT
    C.SourceSponsorLabel,
    C.SponsorID,
    C.GivenName,
    C.LastName,
    C.DisplayName,
    C.SponsorType,
    COUNT(*) OVER (
        PARTITION BY C.SourceSponsorLabel
    ) AS CandidateCount
FROM CandidateMatches AS C
ORDER BY
    C.SourceSponsorLabel,
    C.DisplayName;


/* ------------------------------------------------------------
   5D. IDENTIFY LABELS WITH NO EXISTING SPONSOR CANDIDATE
   ------------------------------------------------------------ */

/*
    Human review determines whether each returned label represents:
        1. an existing Sponsor with different source formatting;
        2. a legitimate missing Person or Institutional Sponsor; or
        3. an identity that should remain unresolved.

    Do not create a Sponsor merely to eliminate an unresolved label.
*/

SELECT
    TRIM(L.Sponsor) AS SourceSponsorLabel,
    COUNT(*) AS AppropriationCount
FROM #AppropriationReferenceLanding AS L
LEFT JOIN CapitalOutlay.SponsorAlias AS SA
    ON TRIM(L.Sponsor) = SA.SourceSponsorLabel
WHERE NULLIF(TRIM(L.Sponsor), '') IS NOT NULL
  AND SA.SponsorAliasID IS NULL
  AND NOT EXISTS (
        SELECT 1
        FROM CapitalOutlay.Sponsor AS S
        WHERE TRIM(L.Sponsor) = S.LastName
           OR TRIM(L.Sponsor) = S.DisplayName
  )
GROUP BY
    TRIM(L.Sponsor)
ORDER BY
    AppropriationCount DESC,
    SourceSponsorLabel;


/* ------------------------------------------------------------
   5E. CREATE A MISSING SPONSOR WHEN REQUIRED
   ------------------------------------------------------------ */

/*
    Use these templates only after human review establishes that the
    source label represents a legitimate Sponsor who does not already
    exist in CapitalOutlay.Sponsor.

    PERSON TEMPLATE:

    INSERT INTO CapitalOutlay.Sponsor (
        GivenName, LastName, SponsorType, DisplayName
    )
    VALUES (
        'Given Name', 'Last Name', 'Person', 'Display Name'
    );

    INSTITUTIONAL TEMPLATE:

    INSERT INTO CapitalOutlay.Sponsor (
        GivenName, LastName, SponsorType, DisplayName
    )
    VALUES (
        NULL, NULL, 'Institutional', 'Institutional Sponsor Name'
    );
*/


/* ------------------------------------------------------------
   5F. CREATE APPROVED SPONSOR ALIASES
   ------------------------------------------------------------ */

/*
    Insert only human-reviewed mappings.

    SINGLE-ALIAS TEMPLATE:

    INSERT INTO CapitalOutlay.SponsorAlias (
        SourceSponsorLabel, SponsorID, IsAutoResolvable
    )
    VALUES (
        'SOURCE LABEL', 123, 1
    );

    MULTIPLE-ALIAS TEMPLATE:

    INSERT INTO CapitalOutlay.SponsorAlias (
        SourceSponsorLabel, SponsorID, IsAutoResolvable
    )
    VALUES
        ('SOURCE LABEL 1', 123, 1),
        ('SOURCE LABEL 2', 456, 1);

    IsAutoResolvable = 0 may retain a reviewed relationship without
    allowing automatic SponsorID assignment.
*/


/* ------------------------------------------------------------
   5G. VERIFY REMAINING UNMAPPED SPONSOR LABELS
   ------------------------------------------------------------ */

/*
    Remaining rows do not block the appropriation load. The source
    label is retained and SponsorID remains NULL until an approved
    mapping becomes available.
*/

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
   5H. APPLY NEWLY APPROVED ALIASES TO EXISTING APPROPRIATIONS
   ------------------------------------------------------------ */

/*
    Needed only when aliases are approved AFTER appropriations have
    already been loaded.

    Safe to rerun:
        - only NULL SponsorID values are populated;
        - existing Sponsor assignments are not overwritten;
        - only IsAutoResolvable = 1 aliases are applied.

    During a clean annual load, aliases established here are used by
    08_load_appropriations.sql, so this UPDATE may affect zero rows.
*/

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

/*
    Read-only summary of normalized appropriation Sponsor status.
*/

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
