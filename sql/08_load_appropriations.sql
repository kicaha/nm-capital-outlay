/*
    Project: New Mexico Capital Outlay Analysis
    Script:  08_load_appropriations.sql
    Purpose: Load and validate one year's official NMLegis Capital Outlay appropriations.
*/

/* ============================================================
   08 - LOAD APPROPRIATIONS
   ============================================================

   Purpose:
   Loads annual appropriation data from the source CSV into
   CapitalOutlay.Appropriation.

   Process:
   1. Clear appropriation-related intermediate records.
   2. Land source data for the selected legislative year.
   3. Validate source values.
   4. Hold records that fail validation.
   5. Load valid records to Staging.Appropriation.
   6. Resolve LegislativeProject and Sponsor relationships.
   7. Load validated appropriations to the normalized table.

   Notes:
      Notes:
   - Blank source Sponsor values are valid.
   - Unresolved nonblank Sponsor labels are preserved in
     SourceSponsorLabel and may load with SponsorID = NULL.
   - SponsorID is populated only when a source label has an alias
     approved for automatic resolution.
   - SourceSponsorLabel preserves the original source value.
   ============================================================ */

USE NMCapitalOutlay;

DECLARE @LegislativeYear smallint = 2022;

/* ============================================================
   0. CLEAR INTERMEDIATE TABLES
   ============================================================ */
/*  Staging and held-record tables are intermediate
    workspaces for the current annual load.

    Remove records from the previous appropriation load before processing
    the next source file. ValidationIssue may also contain
    project issues, so only appropriation-related issues are removed.
*/

/* ============================================================
   CLEAR PRIOR HELD APPROPRIATION RESULTS FOR THIS YEAR
   ============================================================ */

/*
    Held records are persistent exception history.

    When a year is rerun, replace only that year's held appropriation
    results. Exceptions from other legislative years are retained.

    ValidationIssue must be deleted first because it references
    HeldAppropriation.
*/

DELETE VI
FROM Staging.ValidationIssue AS VI
INNER JOIN Staging.HeldAppropriation AS HA
    ON VI.HeldAppropriationID = HA.HeldAppropriationID
WHERE TRY_CONVERT(smallint, HA.LegislativeYear) = @LegislativeYear;

DELETE FROM Staging.HeldAppropriation
WHERE TRY_CONVERT(smallint, LegislativeYear) = @LegislativeYear;
/* ============================================================
   1. LAND APPROPRIATION DATA
   ============================================================ */

/*
    The landing table is intentionally permissive.

    Its purpose is to receive the source CSV faithfully before
    validation or transformation. All source fields are loaded
    as nullable text so invalid source values can be identified
    and reported rather than causing the initial import to fail.
*/
CREATE TABLE #AppropriationLanding (
    LegislativeYear nvarchar(20) NULL,
    Bill nvarchar(20) NULL,
    WebID nvarchar(20) NULL,
    Sponsor nvarchar(255) NULL,
    Amount nvarchar(50) NULL,
    SourcePage nvarchar(20) NULL
);

/*
    Load the annual Capital Outlay list from CSV.

    The CSV header is skipped. UTF-8 encoding preserves Unicode
    characters in source text. The source file uses LF line endings.

    BULK INSERT maps CSV fields to the landing table by position,
    not by the CSV header names.
*/
BULK INSERT #AppropriationLanding
FROM 'C:\SQLData\SB212_2022_Statewide_appropriations.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);

/* ============================================================
   2. PREPARE APPROPRIATIONS FOR VALIDATION
   ============================================================ */

/*
    #AppropriationValidation assigns a temporary processing ID to each
    landed source row.

    The source business key cannot be used to identify rows during
    validation because the business key itself may be missing,
    malformed, or duplicated.

    Source values remain as nullable text so they can be validated
    before conversion to the typed Staging.Appropriation table.
*/
CREATE TABLE #AppropriationValidation (
    ValidationAppropriationID int IDENTITY(1,1) NOT NULL,
    LegislativeYear nvarchar(20) NULL,
    Bill nvarchar(20) NULL,
    WebID nvarchar(20) NULL,
    Sponsor nvarchar(255) NULL,
    Amount nvarchar(50) NULL,
    SourcePage nvarchar(20) NULL
);

INSERT INTO #AppropriationValidation (
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
    REPLACE(SourcePage, CHAR(13), '')
FROM #AppropriationLanding;

/* ============================================================
   3. IDENTIFY AND HOLD APPROPRIATIONS THAT FAIL VALIDATION
   ============================================================ */

/*
    #AppropriationIssues records each validation problem found in the
    incoming appropriation data.

    An appropriation may have more than one issue. ValidationAppropriationID
    connects each issue to the source row in #AppropriationValidation.
*/
CREATE TABLE #AppropriationIssues (
    ValidationAppropriationID int NOT NULL,
    Issue nvarchar(250) NOT NULL,
    FieldName varchar(50) NULL,
    OriginalValue nvarchar(500) NULL
);

/* ------------------------------------------------------------
   3A. IDENTIFY VALIDATION ISSUES
   ------------------------------------------------------------ */

/* Missing business-key values */

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'LegislativeYear is missing.',
    'LegislativeYear',
    LegislativeYear
FROM #AppropriationValidation
WHERE NULLIF(TRIM(LegislativeYear), '') IS NULL;

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'Bill is missing.',
    'Bill',
    Bill
FROM #AppropriationValidation
WHERE NULLIF(TRIM(Bill), '') IS NULL;

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'WebID is missing.',
    'WebID',
    WebID
FROM #AppropriationValidation
WHERE NULLIF(TRIM(WebID), '') IS NULL;

/* Can values for LegislativeYear and WebID be correctly converted?*/

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'LegislativeYear cannot be converted to smallint.',
    'LegislativeYear',
    LegislativeYear
FROM #AppropriationValidation
WHERE NULLIF(TRIM(LegislativeYear), '') IS NOT NULL
  AND TRY_CONVERT(smallint, LegislativeYear) IS NULL;

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'WebID cannot be converted to int.',
    'WebID',
    WebID
FROM #AppropriationValidation
WHERE NULLIF(TRIM(WebID), '') IS NOT NULL
  AND TRY_CONVERT(int, WebID) IS NULL;

/* Bill must fit their destination column */
INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'Bill exceeds the 10-character destination limit.',
    'Bill',
    Bill
FROM #AppropriationValidation
WHERE LEN(Bill) > 10;

/* Are there appropriations with no matching business key in LegislativeProject? */
INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    V.ValidationAppropriationID,
    N'Project business key does not resolve to LegislativeProject.',
    'Business Key',
    CONCAT(V.LegislativeYear, ' | ', V.Bill, ' | ', V.WebID)
FROM #AppropriationValidation AS V
LEFT JOIN CapitalOutlay.LegislativeProject AS P
    ON TRY_CONVERT(smallint, V.LegislativeYear) = P.LegislativeYear
   AND V.Bill = P.Bill
   AND TRY_CONVERT(int, V.WebID) = P.WebID
WHERE P.LegislativeProjectID IS NULL;

/* Are there appropriations with missing amounts? */

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'Amount is missing.',
    'Amount',
    Amount
FROM #AppropriationValidation
WHERE NULLIF(TRIM(Amount), '') IS NULL;


/* Can supplied Amount values be converted to int? */

INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'Amount cannot be converted to int.',
    'Amount',
    Amount
FROM #AppropriationValidation
WHERE NULLIF(TRIM(Amount), '') IS NOT NULL
  AND TRY_CONVERT(int, Amount) IS NULL;

/* Sponsor must fit their destination column */
INSERT INTO #AppropriationIssues (
    ValidationAppropriationID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationAppropriationID,
    N'Sponsor exceeds the 100-character destination limit.',
    'Sponsor',
    Sponsor
FROM #AppropriationValidation
WHERE LEN(Sponsor) > 100;

/* ------------------------------------------------------------
   3B. HOLD INVALID APPROPRIATIONS
   ------------------------------------------------------------ */

/*
    This temporary map connects the processing ID used during this
    import to the permanent HeldAppropriationID generated by SQL Server.
*/
CREATE TABLE #HeldAppropriationMap (
    ValidationAppropriationID int NOT NULL,
    HeldAppropriationID int NOT NULL
);

/*
    Only appropriations appearing in #AppropriationIssues are held.

    MERGE is used here because its OUTPUT clause can retain both the
    source ValidationAppropriationID and the newly generated
    HeldAppropriationID.

    The ON condition is intentionally always false because every
    source row supplied to this statement must be inserted.
*/
MERGE INTO Staging.HeldAppropriation AS H
USING (
    SELECT V.*
    FROM #AppropriationValidation AS V
    WHERE EXISTS (
        SELECT 1
        FROM #AppropriationIssues AS I
        WHERE I.ValidationAppropriationID = V.ValidationAppropriationID
    )
) AS V
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        LegislativeYear,
        Bill,
        WebID,
        Amount,
        SourcePage,
        Sponsor
    )
    VALUES (
        V.LegislativeYear,
        V.Bill,
        V.WebID,
        V.Amount,
        V.SourcePage,
        V.Sponsor
    )
OUTPUT
    V.ValidationAppropriationID,
    inserted.HeldAppropriationID
INTO #HeldAppropriationMap (
    ValidationAppropriationID,
    HeldAppropriationID
);

/* ------------------------------------------------------------
   3C. RECORD VALIDATION ISSUES
   ------------------------------------------------------------ */

INSERT INTO Staging.ValidationIssue (
    HeldProjectID,
    HeldAppropriationID,
    Issue,
    FieldName,
    OriginalValue
)
SELECT
    NULL,
    M.HeldAppropriationID,
    I.Issue,
    I.FieldName,
    I.OriginalValue
FROM #AppropriationIssues AS I
INNER JOIN #HeldAppropriationMap AS M
    ON I.ValidationAppropriationID = M.ValidationAppropriationID;

/* ============================================================
   4. LOAD VALID APPROPRIATIONS TO STAGING
   ============================================================ */

/*
    Load appropriations that passed all validation rules into the
    typed staging table.

    NOT EXISTS excludes any source row with one or more recorded
    validation issues. Values are converted from the permissive
    text representation used during landing and validation to the
    data types required by Staging.Appropriation.
*/
INSERT INTO Staging.Appropriation (
    LegislativeYear,
    Bill,
    WebID,
    Sponsor,
    Amount,
    SourcePage
)
SELECT
    TRY_CONVERT(smallint, V.LegislativeYear),
    V.Bill,
    TRY_CONVERT(int, V.WebID),
    NULLIF(TRIM(V.Sponsor), ''),
    TRY_CONVERT(int, V.Amount),
    TRY_CONVERT(int, NULLIF(TRIM(V.SourcePage), ''))
FROM #AppropriationValidation AS V
WHERE NOT EXISTS (
    SELECT 1
    FROM #AppropriationIssues AS I
    WHERE I.ValidationAppropriationID = V.ValidationAppropriationID
);

/* ============================================================
   5. LOAD APPROPRIATIONS TO NORMALIZED TABLE
   ============================================================ */

/*
    Load validated staged appropriations into the normalized
    appropriation table.

    LegislativeYear, Bill, and WebID are used together to resolve
    the corresponding LegislativeProjectID.

    SourceSponsorLabel preserves the sponsor value supplied by the
    source. SponsorID is populated only when that source label has
    an alias approved for automatic resolution.

    Blank sponsor labels and sponsor labels that cannot be
    automatically resolved do not prevent the appropriation from
    loading. In those cases, SponsorID remains NULL.
*/
INSERT INTO CapitalOutlay.Appropriation (
    LegislativeProjectID,
    SponsorID,
    SourceSponsorLabel,
    Amount
)
SELECT
    P.LegislativeProjectID,
    SA.SponsorID,
    A.Sponsor,
    A.Amount
FROM Staging.Appropriation AS A
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON A.LegislativeYear = P.LegislativeYear
   AND A.Bill = P.Bill
   AND A.WebID = P.WebID
LEFT JOIN CapitalOutlay.SponsorAlias AS SA
    ON A.Sponsor = SA.SourceSponsorLabel
   AND SA.IsAutoResolvable = 1
WHERE A.LegislativeYear = @LegislativeYear;