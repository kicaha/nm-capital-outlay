/*
    Project: New Mexico Capital Outlay Analysis
    Script:  07_load_projects.sql
    Purpose: Load and validate one year's official NMLegis Capital Outlay projects.
*/

USE NMCapitalOutlay;

DECLARE @LegislativeYear smallint = 2025;

/* ============================================================
   0. CLEAR INTERMEDIATE TABLES
   ============================================================ */
/*  Project staging and held-record tables are intermediate
    workspaces for the current annual load.

    Remove records from the previous project load before processing
    the next source file. ValidationIssue may also contain
    appropriation issues, so only project-related issues are removed.
*/

/* ============================================================
   CLEAR PRIOR HELD PROJECT RESULTS FOR THIS YEAR
   ============================================================ */

/*
    Held records are persistent exception history.

    When a year is rerun, replace only that year's held project
    results. Exceptions from other legislative years are retained.

    ValidationIssue must be deleted first because it references
    HeldProject.
*/
TRUNCATE TABLE Staging.Project;

DELETE VI
FROM Staging.ValidationIssue AS VI
INNER JOIN Staging.HeldProject AS HP
    ON VI.HeldProjectID = HP.HeldProjectID
WHERE HP.LegislativeYear = @LegislativeYear;

DELETE FROM Staging.HeldProject
WHERE LegislativeYear = @LegislativeYear;

/* ============================================================
   1. LAND PROJECT DATA
   ============================================================ */

/*
    The landing table is intentionally permissive.

    Its purpose is to receive the source CSV faithfully before
    validation or transformation. All source fields are loaded
    as nullable text so invalid source values can be identified
    and reported rather than causing the initial import to fail.
*/
CREATE TABLE #ProjectLanding (
    LegislativeYear nvarchar(20) NULL,
    Bill nvarchar(20) NULL,
    WebID nvarchar(20) NULL,
    ChapterSection nvarchar(50) NULL,
    ProjectTitle nvarchar(500) NULL,
    FundCode nvarchar(20) NULL,
    CityLocale nvarchar(50) NULL,
    County nvarchar(255) NULL,
    AgencyCode nvarchar(20) NULL,
    StatusFlag nvarchar(20) NULL,
    ProjectTotalAfterVetoes nvarchar(20) NULL,
    SourcePage nvarchar(20) NULL
);

/*
    Load the annual Capital Outlay list from CSV.

    The CSV header is skipped. UTF-8 encoding preserves Unicode
    characters in source text. The source file uses LF line endings.

    BULK INSERT maps CSV fields to the landing table by position,
    not by the CSV header names.
*/
BULK INSERT #ProjectLanding
FROM 'C:\SQLData\HB450_2025_Statewide_projects.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);


/* ============================================================
   2. PREPARE PROJECTS FOR VALIDATION
   ============================================================ */

/*
    #ProjectValidation assigns a temporary processing ID to each
    landed source row.

    The source business key cannot be used to identify rows during
    validation because the business key itself may be missing,
    malformed, or duplicated.

    Source values remain as nullable text so they can be validated
    before conversion to the typed Staging.Project table.
*/
CREATE TABLE #ProjectValidation (
    ValidationProjectID int IDENTITY(1,1) NOT NULL,
    LegislativeYear nvarchar(20) NULL,
    Bill nvarchar(20) NULL,
    WebID nvarchar(20) NULL,
    ChapterSection nvarchar(50) NULL,
    ProjectTitle nvarchar(500) NULL,
    FundCode nvarchar(20) NULL,
    CityLocale nvarchar(50) NULL,
    County nvarchar(255) NULL,
    AgencyCode nvarchar(20) NULL,
    StatusFlag nvarchar(20) NULL,
    ProjectTotalAfterVetoes nvarchar(20) NULL,
    SourcePage nvarchar(20) NULL
);

INSERT INTO #ProjectValidation (
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
    REPLACE(SourcePage, CHAR(13), '')
FROM #ProjectLanding;


/* ============================================================
   3. IDENTIFY AND HOLD PROJECTS THAT FAIL VALIDATION
   ============================================================ */

/*
    #ProjectIssues records each validation problem found in the
    incoming project data.

    A project may have more than one issue. ValidationProjectID
    connects each issue to the source row in #ProjectValidation.
*/
CREATE TABLE #ProjectIssues (
    ValidationProjectID int NOT NULL,
    Issue nvarchar(250) NOT NULL,
    FieldName varchar(50) NULL,
    OriginalValue nvarchar(500) NULL
);


/* ------------------------------------------------------------
   3A. IDENTIFY VALIDATION ISSUES
   ------------------------------------------------------------ */

/* Missing business-key values */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'LegislativeYear is missing.',
    'LegislativeYear',
    LegislativeYear
FROM #ProjectValidation
WHERE NULLIF(TRIM(LegislativeYear), '') IS NULL;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'Bill is missing.',
    'Bill',
    Bill
FROM #ProjectValidation
WHERE NULLIF(TRIM(Bill), '') IS NULL;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'WebID is missing.',
    'WebID',
    WebID
FROM #ProjectValidation
WHERE NULLIF(TRIM(WebID), '') IS NULL;


/* Invalid business-key values */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'LegislativeYear cannot be converted to smallint.',
    'LegislativeYear',
    LegislativeYear
FROM #ProjectValidation
WHERE NULLIF(TRIM(LegislativeYear), '') IS NOT NULL
  AND TRY_CONVERT(smallint, LegislativeYear) IS NULL;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'WebID cannot be converted to int.',
    'WebID',
    WebID
FROM #ProjectValidation
WHERE NULLIF(TRIM(WebID), '') IS NOT NULL
  AND TRY_CONVERT(int, WebID) IS NULL;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'Bill exceeds the 10-character destination limit.',
    'Bill',
    Bill
FROM #ProjectValidation
WHERE LEN(Bill) > 10;


/* Duplicate business keys within the incoming source */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    V.ValidationProjectID,
    N'Duplicate project business key exists in the incoming source.',
    NULL,
    CONCAT(V.LegislativeYear, ' | ', V.Bill, ' | ', V.WebID)
FROM #ProjectValidation AS V
INNER JOIN (
    SELECT
        LegislativeYear,
        Bill,
        WebID
    FROM #ProjectValidation
    GROUP BY
        LegislativeYear,
        Bill,
        WebID
    HAVING COUNT(*) > 1
) AS D
    ON V.LegislativeYear = D.LegislativeYear
   AND V.Bill = D.Bill
   AND V.WebID = D.WebID;


/* Business key already exists in the normalized table */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    V.ValidationProjectID,
    N'Project business key already exists in LegislativeProject.',
    NULL,
    CONCAT(V.LegislativeYear, ' | ', V.Bill, ' | ', V.WebID)
FROM #ProjectValidation AS V
INNER JOIN CapitalOutlay.LegislativeProject AS P
    ON TRY_CONVERT(smallint, V.LegislativeYear) = P.LegislativeYear
   AND V.Bill = P.Bill
   AND TRY_CONVERT(int, V.WebID) = P.WebID;


/* ProjectTitle validation */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'ProjectTitle is missing.',
    'ProjectTitle',
    ProjectTitle
FROM #ProjectValidation
WHERE NULLIF(TRIM(ProjectTitle), '') IS NULL;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'ProjectTitle exceeds the 255-character destination limit.',
    'ProjectTitle',
    ProjectTitle
FROM #ProjectValidation
WHERE LEN(ProjectTitle) > 255;


/* FundCode must resolve to the Fund reference table */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    V.ValidationProjectID,
    N'FundCode does not resolve to the Fund reference table.',
    'FundCode',
    V.FundCode
FROM #ProjectValidation AS V
LEFT JOIN CapitalOutlay.Fund AS F
    ON V.FundCode = F.FundCode
WHERE F.FundCode IS NULL;


/* AgencyCode must resolve to the Agency reference table */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    V.ValidationProjectID,
    N'AgencyCode does not resolve to the Agency reference table.',
    'AgencyCode',
    V.AgencyCode
FROM #ProjectValidation AS V
LEFT JOIN CapitalOutlay.Agency AS A
    ON V.AgencyCode = A.AgencyCode
WHERE A.AgencyCode IS NULL;


/* ProjectTotalAfterVetoes may be blank, but must be an int if supplied */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'ProjectTotalAfterVetoes cannot be converted to int.',
    'ProjectTotalAfterVetoes',
    ProjectTotalAfterVetoes
FROM #ProjectValidation
WHERE NULLIF(TRIM(ProjectTotalAfterVetoes), '') IS NOT NULL
  AND TRY_CONVERT(int, ProjectTotalAfterVetoes) IS NULL;


/* Nullable descriptive fields must fit their destination columns */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'ChapterSection exceeds the 50-character destination limit.',
    'ChapterSection',
    ChapterSection
FROM #ProjectValidation
WHERE LEN(ChapterSection) > 50;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'CityLocale exceeds the 50-character destination limit.',
    'CityLocale',
    CityLocale
FROM #ProjectValidation
WHERE LEN(CityLocale) > 50;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'County exceeds the 50-character destination limit.',
    'County',
    County
FROM #ProjectValidation
WHERE LEN(County) > 50;

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'StatusFlag exceeds the 10-character destination limit.',
    'StatusFlag',
    StatusFlag
FROM #ProjectValidation
WHERE LEN(StatusFlag) > 10;


/* SourcePage may be blank, but must be an int if supplied */

INSERT INTO #ProjectIssues (
    ValidationProjectID, Issue, FieldName, OriginalValue
)
SELECT
    ValidationProjectID,
    N'SourcePage cannot be converted to int.',
    'SourcePage',
    SourcePage
FROM #ProjectValidation
WHERE NULLIF(TRIM(SourcePage), '') IS NOT NULL
  AND TRY_CONVERT(int, SourcePage) IS NULL;


/* ------------------------------------------------------------
   3B. HOLD INVALID PROJECTS
   ------------------------------------------------------------ */

/*
    This temporary map connects the processing ID used during this
    import to the permanent HeldProjectID generated by SQL Server.
*/
CREATE TABLE #HeldProjectMap (
    ValidationProjectID int NOT NULL,
    HeldProjectID int NOT NULL
);

/*
    Only projects appearing in #ProjectIssues are held.

    MERGE is used here because its OUTPUT clause can retain both the
    source ValidationProjectID and the newly generated HeldProjectID.
    The ON condition is intentionally always false because every
    source row supplied to this statement must be inserted.
*/
MERGE INTO Staging.HeldProject AS H
USING (
    SELECT V.*
    FROM #ProjectValidation AS V
    WHERE EXISTS (
        SELECT 1
        FROM #ProjectIssues AS I
        WHERE I.ValidationProjectID = V.ValidationProjectID
    )
) AS V
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        LegislativeYear,
        Bill,
        WebID,
        ChapterSection,
        FundCode,
        AgencyCode,
        StatusFlag,
        ProjectTotalAfterVetoes,
        SourcePage,
        CityLocale,
        County,
        ProjectTitle
    )
    VALUES (
        V.LegislativeYear,
        V.Bill,
        V.WebID,
        V.ChapterSection,
        V.FundCode,
        V.AgencyCode,
        V.StatusFlag,
        V.ProjectTotalAfterVetoes,
        V.SourcePage,
        V.CityLocale,
        V.County,
        V.ProjectTitle
    )
OUTPUT
    V.ValidationProjectID,
    inserted.HeldProjectID
INTO #HeldProjectMap (
    ValidationProjectID,
    HeldProjectID
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
    M.HeldProjectID,
    NULL,
    I.Issue,
    I.FieldName,
    I.OriginalValue
FROM #ProjectIssues AS I
INNER JOIN #HeldProjectMap AS M
    ON I.ValidationProjectID = M.ValidationProjectID;


/* ============================================================
   4. LOAD VALID PROJECTS TO STAGING
   ============================================================ */

/*
    Load projects that passed all validation rules into the typed
    staging table.

    NOT EXISTS excludes any source row with one or more recorded
    validation issues. Values are converted from the permissive
    text representation used during landing and validation to the
    data types required by Staging.Project.
*/
INSERT INTO Staging.Project (
    LegislativeYear,
    Bill,
    WebID,
    ProjectTitle,
    ChapterSection,
    FundCode,
    CityLocale,
    County,
    AgencyCode,
    StatusFlag,
    ProjectTotalAfterVetoes,
    SourcePage
)
SELECT
    TRY_CONVERT(smallint, V.LegislativeYear),
    V.Bill,
    TRY_CONVERT(int, V.WebID),
    V.ProjectTitle,
    NULLIF(TRIM(V.ChapterSection), ''),
    V.FundCode,
    NULLIF(TRIM(V.CityLocale), ''),
    NULLIF(TRIM(V.County), ''),
    V.AgencyCode,
    NULLIF(TRIM(V.StatusFlag), ''),
    TRY_CONVERT(int, NULLIF(TRIM(V.ProjectTotalAfterVetoes), '')),
    TRY_CONVERT(int, NULLIF(TRIM(V.SourcePage), ''))
FROM #ProjectValidation AS V
WHERE NOT EXISTS (
    SELECT 1
    FROM #ProjectIssues AS I
    WHERE I.ValidationProjectID = V.ValidationProjectID
);


/* ============================================================
   5. LOAD PROJECTS TO NORMALIZED TABLE
   ============================================================ */

/*
    Load validated staged projects into the normalized project
    table.

    FundCode and AgencyCode are translated to their corresponding
    foreign-key IDs through the reference tables. SourcePage is
    retained only in staging and is not loaded to the normalized
    project table.

    Projects already present in LegislativeProject were identified
    during validation and therefore are not present in the current
    valid staged set.
*/
INSERT INTO CapitalOutlay.LegislativeProject (
    ProjectTitle,
    LegislativeYear,
    Bill,
    WebID,
    ChapterSection,
    CityLocale,
    County,
    StatusFlag,
    ProjectTotalAfterVetoes,
    FundID,
    AgencyID
)
SELECT
    P.ProjectTitle,
    P.LegislativeYear,
    P.Bill,
    P.WebID,
    P.ChapterSection,
    P.CityLocale,
    P.County,
    P.StatusFlag,
    P.ProjectTotalAfterVetoes,
    F.FundID,
    A.AgencyID
FROM Staging.Project AS P
INNER JOIN CapitalOutlay.Fund AS F
    ON P.FundCode = F.FundCode
INNER JOIN CapitalOutlay.Agency AS A
    ON P.AgencyCode = A.AgencyCode
WHERE P.LegislativeYear = @LegislativeYear;