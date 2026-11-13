/*
    Project: New Mexico Capital Outlay Analysis
    Script:  09_verify_complete_load.sql
    Purpose: Verify that the historical Capital Outlay database
             loaded completely and consistently.

    This script is READ-ONLY.

    It does not modify data. Its purpose is to answer:

        "Did this whole damn thing work?"

    Historical verification scope:
        2021-2026

    The 2026 data is intentionally excluded because it is reserved
    as an out-of-sample test of the completed ETL process.
*/

USE NMCapitalOutlay;
GO

SET NOCOUNT ON;

/* ============================================================
   0. EXPECTED HISTORICAL COUNTS
   ============================================================ */

/*
    Expected counts are based on the historical source files after
    accounting for records intentionally held because they failed
    validation.

    Source total =
        normalized records + held records
*/

DECLARE @Expected TABLE (
    LegislativeYear smallint PRIMARY KEY,
    ExpectedProjects int NOT NULL,
    ExpectedHeldProjects int NOT NULL,
    ExpectedAppropriations int NOT NULL,
    ExpectedHeldAppropriations int NOT NULL
);

INSERT INTO @Expected (
    LegislativeYear,
    ExpectedProjects,
    ExpectedHeldProjects,
    ExpectedAppropriations,
    ExpectedHeldAppropriations
)
VALUES
    (2021, 1208, 0, 2419, 0),
    (2022, 1313, 0, 2589, 0),
    (2023, 1496, 0, 2884, 0),
    (2024, 1438, 0, 2850, 0),
    (2025, 1423, 0, 3019, 0),
    (2026, 1340, 0, 2773, 0);


/* ============================================================
   1. PROJECT LOAD VERIFICATION
   ============================================================ */

PRINT '============================================================';
PRINT '1. PROJECT LOAD VERIFICATION';
PRINT '============================================================';

SELECT
    E.LegislativeYear,
    E.ExpectedProjects,
    COUNT(P.LegislativeProjectID) AS ActualProjects,
    E.ExpectedHeldProjects,
    (
        SELECT COUNT(*)
        FROM Staging.HeldProject AS HP
        WHERE TRY_CONVERT(smallint, HP.LegislativeYear)
              = E.LegislativeYear
    ) AS ActualHeldProjects,
    E.ExpectedProjects + E.ExpectedHeldProjects
        AS ExpectedSourceProjects,
    COUNT(P.LegislativeProjectID)
        + (
            SELECT COUNT(*)
            FROM Staging.HeldProject AS HP
            WHERE TRY_CONVERT(smallint, HP.LegislativeYear)
                  = E.LegislativeYear
          ) AS AccountedSourceProjects,
    CASE
        WHEN COUNT(P.LegislativeProjectID) = E.ExpectedProjects
         AND (
                SELECT COUNT(*)
                FROM Staging.HeldProject AS HP
                WHERE TRY_CONVERT(smallint, HP.LegislativeYear)
                      = E.LegislativeYear
             ) = E.ExpectedHeldProjects
        THEN 'PASS'
        ELSE 'FAIL'
    END AS VerificationStatus
FROM @Expected AS E
LEFT JOIN CapitalOutlay.LegislativeProject AS P
    ON P.LegislativeYear = E.LegislativeYear
GROUP BY
    E.LegislativeYear,
    E.ExpectedProjects,
    E.ExpectedHeldProjects
ORDER BY E.LegislativeYear;


/* ============================================================
   2. APPROPRIATION LOAD VERIFICATION
   ============================================================ */

PRINT '============================================================';
PRINT '2. APPROPRIATION LOAD VERIFICATION';
PRINT '============================================================';

SELECT
    E.LegislativeYear,
    E.ExpectedAppropriations,
    COUNT(A.AppropriationID) AS ActualAppropriations,
    E.ExpectedHeldAppropriations,
    (
        SELECT COUNT(*)
        FROM Staging.HeldAppropriation AS HA
        WHERE TRY_CONVERT(smallint, HA.LegislativeYear)
              = E.LegislativeYear
    ) AS ActualHeldAppropriations,
    E.ExpectedAppropriations + E.ExpectedHeldAppropriations
        AS ExpectedSourceAppropriations,
    COUNT(A.AppropriationID)
        + (
            SELECT COUNT(*)
            FROM Staging.HeldAppropriation AS HA
            WHERE TRY_CONVERT(smallint, HA.LegislativeYear)
                  = E.LegislativeYear
          ) AS AccountedSourceAppropriations,
    CASE
        WHEN COUNT(A.AppropriationID) = E.ExpectedAppropriations
         AND (
                SELECT COUNT(*)
                FROM Staging.HeldAppropriation AS HA
                WHERE TRY_CONVERT(smallint, HA.LegislativeYear)
                      = E.LegislativeYear
             ) = E.ExpectedHeldAppropriations
        THEN 'PASS'
        ELSE 'FAIL'
    END AS VerificationStatus
FROM @Expected AS E
LEFT JOIN CapitalOutlay.LegislativeProject AS P
    ON P.LegislativeYear = E.LegislativeYear
LEFT JOIN CapitalOutlay.Appropriation AS A
    ON A.LegislativeProjectID = P.LegislativeProjectID
GROUP BY
    E.LegislativeYear,
    E.ExpectedAppropriations,
    E.ExpectedHeldAppropriations
ORDER BY E.LegislativeYear;


/* ============================================================
   3. HELD RECORDS AND VALIDATION ISSUES
   ============================================================ */

PRINT '============================================================';
PRINT '3A. HELD PROJECTS';
PRINT '============================================================';

SELECT
    HP.HeldProjectID,
    HP.HeldDate,
    HP.LegislativeYear,
    HP.Bill,
    HP.WebID,
    HP.ProjectTitle,
    HP.SourcePage,
    VI.Issue,
    VI.FieldName,
    VI.OriginalValue,
    VI.IsResolved
FROM Staging.HeldProject AS HP
LEFT JOIN Staging.ValidationIssue AS VI
    ON VI.HeldProjectID = HP.HeldProjectID
ORDER BY
    TRY_CONVERT(smallint, HP.LegislativeYear),
    HP.HeldProjectID,
    VI.ValidationIssueID;


PRINT '============================================================';
PRINT '3B. HELD APPROPRIATIONS';
PRINT '============================================================';

SELECT
    HA.HeldAppropriationID,
    HA.HeldDate,
    HA.LegislativeYear,
    HA.Bill,
    HA.WebID,
    HA.Sponsor,
    HA.Amount,
    HA.SourcePage,
    VI.Issue,
    VI.FieldName,
    VI.OriginalValue,
    VI.IsResolved
FROM Staging.HeldAppropriation AS HA
LEFT JOIN Staging.ValidationIssue AS VI
    ON VI.HeldAppropriationID = HA.HeldAppropriationID
ORDER BY
    TRY_CONVERT(smallint, HA.LegislativeYear),
    HA.HeldAppropriationID,
    VI.ValidationIssueID;


/* ============================================================
   4. VALIDATION-ISSUE INTEGRITY
   ============================================================ */

PRINT '============================================================';
PRINT '4. VALIDATION-ISSUE INTEGRITY';
PRINT 'Expected result: 0 rows';
PRINT '============================================================';

/*
    Every held record should have at least one ValidationIssue.
*/

SELECT
    'HeldProject without ValidationIssue' AS Problem,
    HP.HeldProjectID AS HeldRecordID,
    HP.LegislativeYear,
    HP.Bill,
    HP.WebID
FROM Staging.HeldProject AS HP
LEFT JOIN Staging.ValidationIssue AS VI
    ON VI.HeldProjectID = HP.HeldProjectID
WHERE VI.ValidationIssueID IS NULL

UNION ALL

SELECT
    'HeldAppropriation without ValidationIssue',
    HA.HeldAppropriationID,
    HA.LegislativeYear,
    HA.Bill,
    HA.WebID
FROM Staging.HeldAppropriation AS HA
LEFT JOIN Staging.ValidationIssue AS VI
    ON VI.HeldAppropriationID = HA.HeldAppropriationID
WHERE VI.ValidationIssueID IS NULL;


/* ============================================================
   5. DUPLICATE PROJECT BUSINESS KEYS
   ============================================================ */

PRINT '============================================================';
PRINT '5. DUPLICATE PROJECT BUSINESS KEYS';
PRINT 'Expected result: 0 rows';
PRINT '============================================================';

SELECT
    LegislativeYear,
    Bill,
    WebID,
    COUNT(*) AS DuplicateCount
FROM CapitalOutlay.LegislativeProject
GROUP BY
    LegislativeYear,
    Bill,
    WebID
HAVING COUNT(*) > 1
ORDER BY
    LegislativeYear,
    Bill,
    WebID;


/* ============================================================
   6. PROJECT / APPROPRIATION RELATIONSHIP
   ============================================================ */

PRINT '============================================================';
PRINT '6. NORMALIZED PROJECTS WITH NO APPROPRIATIONS';
PRINT 'Review any returned rows';
PRINT '============================================================';

/*
    This is a diagnostic rather than an automatic failure.

    A project with no appropriation may be legitimate, but should
    be visible during final verification.
*/

SELECT
    P.LegislativeProjectID,
    P.LegislativeYear,
    P.Bill,
    P.WebID,
    P.ProjectTitle,
    P.StatusFlag,
    P.ProjectTotalAfterVetoes
FROM CapitalOutlay.LegislativeProject AS P
LEFT JOIN CapitalOutlay.Appropriation AS A
    ON A.LegislativeProjectID = P.LegislativeProjectID
WHERE A.AppropriationID IS NULL
ORDER BY
    P.LegislativeYear,
    P.Bill,
    P.WebID;


/* ============================================================
   7. SPONSOR RESOLUTION SUMMARY
   ============================================================ */

PRINT '============================================================';
PRINT '7. SPONSOR RESOLUTION SUMMARY';
PRINT '============================================================';

/*
    SponsorID NULL is not automatically an error.

    Nonblank unresolved source labels are intentionally retained
    when sponsor identity cannot safely be resolved.

    Blank source sponsor values are also valid.
*/

SELECT
    P.LegislativeYear,
    COUNT(*) AS TotalAppropriations,

    SUM(
        CASE
            WHEN A.SponsorID IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS ResolvedSponsor,

    SUM(
        CASE
            WHEN A.SponsorID IS NULL
             AND NULLIF(TRIM(A.SourceSponsorLabel), '') IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS UnresolvedSponsor,

    SUM(
        CASE
            WHEN A.SponsorID IS NULL
             AND NULLIF(TRIM(A.SourceSponsorLabel), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS BlankSourceSponsor

FROM CapitalOutlay.Appropriation AS A
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeProjectID = P.LegislativeProjectID
GROUP BY P.LegislativeYear
ORDER BY P.LegislativeYear;


/* ============================================================
   8. UNRESOLVED NONBLANK SPONSOR LABELS
   ============================================================ */

PRINT '============================================================';
PRINT '8. UNRESOLVED NONBLANK SPONSOR LABELS';
PRINT 'Informational - unresolved sponsors are permitted';
PRINT '============================================================';

SELECT
    P.LegislativeYear,
    A.SourceSponsorLabel,
    COUNT(*) AS AppropriationCount,
    SUM(A.Amount) AS AppropriationAmount
FROM CapitalOutlay.Appropriation AS A
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeProjectID = P.LegislativeProjectID
WHERE A.SponsorID IS NULL
  AND NULLIF(TRIM(A.SourceSponsorLabel), '') IS NOT NULL
GROUP BY
    P.LegislativeYear,
    A.SourceSponsorLabel
ORDER BY
    P.LegislativeYear,
    A.SourceSponsorLabel;


/* ============================================================
   9. BLANK SOURCE SPONSORS
   ============================================================ */

PRINT '============================================================';
PRINT '9. BLANK SOURCE SPONSORS';
PRINT 'Informational - blank source sponsors are valid';
PRINT '============================================================';

SELECT
    P.LegislativeYear,
    COUNT(*) AS BlankSponsorCount,
    SUM(A.Amount) AS AppropriationAmount
FROM CapitalOutlay.Appropriation AS A
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeProjectID = P.LegislativeProjectID
WHERE NULLIF(TRIM(A.SourceSponsorLabel), '') IS NULL
GROUP BY P.LegislativeYear
ORDER BY P.LegislativeYear;


/* ============================================================
   10. SPONSOR ALIAS INTEGRITY
   ============================================================ */

PRINT '============================================================';
PRINT '10. SPONSOR ALIAS INTEGRITY';
PRINT 'Expected result: 0 rows';
PRINT '============================================================';

/*
    Any appropriation resolved to a Sponsor through a source label
    should agree with the auto-resolvable SponsorAlias mapping for
    that exact label.

    This detects contradictory sponsor resolution.
*/

SELECT
    A.AppropriationID,
    P.LegislativeYear,
    A.SourceSponsorLabel,
    A.SponsorID AS AppropriationSponsorID,
    SA.SponsorID AS AliasSponsorID
FROM CapitalOutlay.Appropriation AS A
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeProjectID = P.LegislativeProjectID
INNER JOIN CapitalOutlay.SponsorAlias AS SA
    ON A.SourceSponsorLabel = SA.SourceSponsorLabel
   AND SA.IsAutoResolvable = 1
WHERE A.SponsorID IS NOT NULL
  AND A.SponsorID <> SA.SponsorID
ORDER BY
    P.LegislativeYear,
    A.AppropriationID;


/* ============================================================
   11. REFERENCE-TABLE INTEGRITY
   ============================================================ */

PRINT '============================================================';
PRINT '11. REFERENCE-TABLE INTEGRITY';
PRINT 'Expected result: 0 rows';
PRINT '============================================================';

/*
    Foreign-key constraints already protect these relationships.
    This query makes that integrity visible in the verification
    output.
*/

SELECT
    'Missing Fund reference' AS Problem,
    P.LegislativeProjectID,
    P.LegislativeYear,
    P.Bill,
    P.WebID
FROM CapitalOutlay.LegislativeProject AS P
LEFT JOIN CapitalOutlay.Fund AS F
    ON P.FundID = F.FundID
WHERE P.FundID IS NOT NULL
  AND F.FundID IS NULL

UNION ALL

SELECT
    'Missing Agency reference',
    P.LegislativeProjectID,
    P.LegislativeYear,
    P.Bill,
    P.WebID
FROM CapitalOutlay.LegislativeProject AS P
LEFT JOIN CapitalOutlay.Agency AS AG
    ON P.AgencyID = AG.AgencyID
WHERE P.AgencyID IS NOT NULL
  AND AG.AgencyID IS NULL;


/* ============================================================
   12. APPROPRIATION REFERENTIAL INTEGRITY
   ============================================================ */

PRINT '============================================================';
PRINT '12. APPROPRIATION REFERENTIAL INTEGRITY';
PRINT 'Expected result: 0 rows';
PRINT '============================================================';

SELECT
    'Missing LegislativeProject' AS Problem,
    A.AppropriationID,
    A.LegislativeProjectID,
    A.SponsorID
FROM CapitalOutlay.Appropriation AS A
LEFT JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeProjectID = P.LegislativeProjectID
WHERE P.LegislativeProjectID IS NULL

UNION ALL

SELECT
    'Missing Sponsor',
    A.AppropriationID,
    A.LegislativeProjectID,
    A.SponsorID
FROM CapitalOutlay.Appropriation AS A
LEFT JOIN CapitalOutlay.Sponsor AS S
    ON A.SponsorID = S.SponsorID
WHERE A.SponsorID IS NOT NULL
  AND S.SponsorID IS NULL;


/* ============================================================
   13. ANNUAL APPROPRIATION TOTALS
   ============================================================ */

PRINT '============================================================';
PRINT '13. ANNUAL APPROPRIATION TOTALS';
PRINT 'Informational';
PRINT '============================================================';

SELECT
    P.LegislativeYear,
    COUNT(DISTINCT P.LegislativeProjectID) AS Projects,
    COUNT(A.AppropriationID) AS Appropriations,
    SUM(CAST(A.Amount AS bigint)) AS TotalAppropriationAmount
FROM CapitalOutlay.LegislativeProject AS P
LEFT JOIN CapitalOutlay.Appropriation AS A
    ON A.LegislativeProjectID = P.LegislativeProjectID
GROUP BY P.LegislativeYear
ORDER BY P.LegislativeYear;


/* ============================================================
   14. FINAL HISTORICAL LOAD STATUS
   ============================================================ */

PRINT '============================================================';
PRINT '14. FINAL HISTORICAL LOAD STATUS';
PRINT '============================================================';

;WITH ActualProjects AS (
    SELECT
        LegislativeYear,
        COUNT(*) AS ActualProjects
    FROM CapitalOutlay.LegislativeProject
    WHERE LegislativeYear BETWEEN 2021 AND 2026
    GROUP BY LegislativeYear
),
ActualAppropriations AS (
    SELECT
        P.LegislativeYear,
        COUNT(*) AS ActualAppropriations
    FROM CapitalOutlay.Appropriation AS A
    INNER JOIN CapitalOutlay.LegislativeProject AS P
        ON A.LegislativeProjectID = P.LegislativeProjectID
    WHERE P.LegislativeYear BETWEEN 2021 AND 2026
    GROUP BY P.LegislativeYear
),
ActualHeldProjects AS (
    SELECT
        TRY_CONVERT(smallint, LegislativeYear) AS LegislativeYear,
        COUNT(*) AS ActualHeldProjects
    FROM Staging.HeldProject
    WHERE TRY_CONVERT(smallint, LegislativeYear)
          BETWEEN 2021 AND 2026
    GROUP BY TRY_CONVERT(smallint, LegislativeYear)
),
ActualHeldAppropriations AS (
    SELECT
        TRY_CONVERT(smallint, LegislativeYear) AS LegislativeYear,
        COUNT(*) AS ActualHeldAppropriations
    FROM Staging.HeldAppropriation
    WHERE TRY_CONVERT(smallint, LegislativeYear)
          BETWEEN 2021 AND 2026
    GROUP BY TRY_CONVERT(smallint, LegislativeYear)
)
SELECT
    E.LegislativeYear,

    CASE
        WHEN ISNULL(P.ActualProjects, 0)
                = E.ExpectedProjects
         AND ISNULL(A.ActualAppropriations, 0)
                = E.ExpectedAppropriations
         AND ISNULL(HP.ActualHeldProjects, 0)
                = E.ExpectedHeldProjects
         AND ISNULL(HA.ActualHeldAppropriations, 0)
                = E.ExpectedHeldAppropriations
        THEN 'PASS'
        ELSE 'FAIL'
    END AS AnnualLoadStatus,

    E.ExpectedProjects,
    ISNULL(P.ActualProjects, 0) AS ActualProjects,

    E.ExpectedAppropriations,
    ISNULL(A.ActualAppropriations, 0)
        AS ActualAppropriations,

    E.ExpectedHeldProjects,
    ISNULL(HP.ActualHeldProjects, 0)
        AS ActualHeldProjects,

    E.ExpectedHeldAppropriations,
    ISNULL(HA.ActualHeldAppropriations, 0)
        AS ActualHeldAppropriations

FROM @Expected AS E
LEFT JOIN ActualProjects AS P
    ON E.LegislativeYear = P.LegislativeYear
LEFT JOIN ActualAppropriations AS A
    ON E.LegislativeYear = A.LegislativeYear
LEFT JOIN ActualHeldProjects AS HP
    ON E.LegislativeYear = HP.LegislativeYear
LEFT JOIN ActualHeldAppropriations AS HA
    ON E.LegislativeYear = HA.LegislativeYear
ORDER BY E.LegislativeYear;


/* ============================================================
   END OF VERIFICATION
   ============================================================ */

PRINT '============================================================';
PRINT '09 VERIFY COMPLETE LOAD FINISHED';
PRINT 'Review all FAIL results and any unexpected diagnostic rows.';
PRINT 'No data was modified by this script.';
PRINT '============================================================';