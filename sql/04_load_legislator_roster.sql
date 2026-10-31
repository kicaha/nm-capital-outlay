/*
    Project: New Mexico Capital Outlay Analysis
    Script:  04_load_legislator_roster.sql
    Purpose: Load and validate one year's official NMLegis legislator roster.
*/

USE NMCapitalOutlay;

DECLARE @ServiceYear smallint = 2026;


/* ============================================================
   1. LAND ROSTER DATA
   ============================================================ */

/*
    The landing table is intentionally permissive.

    Its purpose is to receive the source CSV faithfully before
    validation or transformation. All source fields are loaded
    as nullable text so invalid source values can be identified
    and reported rather than causing the initial import to fail.
*/
CREATE TABLE #SponsorRosterLanding (
    Title nvarchar(25) NULL,
    LastName nvarchar(100) NULL,
    FirstName nvarchar(100) NULL,
    NameInitial nvarchar(20) NULL,
    Party nvarchar(25) NULL,
    District nvarchar(20) NULL,
    StartYear nvarchar(20) NULL,
    PreferredEmail nvarchar(255) NULL
);


/*
    Load the annual NMLegis roster from CSV.

    The CSV header is skipped. UTF-8 encoding preserves Unicode
    characters in legislator names. The source file uses LF line
    endings.

    BULK INSERT maps CSV fields to the landing table by position,
    not by the CSV header names.
*/
BULK INSERT #SponsorRosterLanding
FROM 'C:\SQLData\2026Legislators.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    ROWTERMINATOR = '0x0a'
);


/* ============================================================
   2. VALIDATE ROSTER DATA
   ============================================================ 

    Required-name validation.

    EXISTS determines whether at least one invalid row exists.
    If so, the offending rows are displayed and THROW stops
    further execution of the roster load.
*/

IF EXISTS (
    SELECT *
    FROM #SponsorRosterLanding
    WHERE NULLIF(TRIM(LastName), '') IS NULL
       OR NULLIF(TRIM(FirstName), '') IS NULL
)
BEGIN
    SELECT *
    FROM #SponsorRosterLanding
    WHERE NULLIF(TRIM(LastName), '') IS NULL
       OR NULLIF(TRIM(FirstName), '') IS NULL;

    THROW 50001, 'Roster validation failed: missing required name.', 1;
END;

/*
    Required-title validation.

    EXISTS determines whether at least one invalid row exists.
    If so, the offending rows are displayed and THROW stops
    further execution of the roster load.
*/
IF EXISTS (
    SELECT *
    FROM #SponsorRosterLanding
    WHERE Title NOT IN ('Representative', 'Senator')
       OR Title IS NULL
)
BEGIN
    SELECT *
    FROM #SponsorRosterLanding
    WHERE Title NOT IN ('Representative', 'Senator')
       OR Title IS NULL;

    THROW 50002, 'Roster validation failed: invalid or missing Title.', 1;
END;

/*
    Required-district validation.

    District must contain a value that can be converted to
    smallint. Leading and trailing whitespace is acceptable.
*/
IF EXISTS (
    SELECT *
    FROM #SponsorRosterLanding
    WHERE NULLIF(TRIM(District), '') IS NULL
       OR TRY_CONVERT(smallint, TRIM(District)) IS NULL
)
BEGIN
    SELECT *
    FROM #SponsorRosterLanding
    WHERE NULLIF(TRIM(District), '') IS NULL
       OR TRY_CONVERT(smallint, TRIM(District)) IS NULL;

    THROW 50003, 'Roster validation failed: missing or invalid District.', 1;
END;

IF EXISTS (
    SELECT *
    FROM #SponsorRosterLanding
    WHERE NULLIF(TRIM(StartYear), '') IS NOT NULL
      AND TRY_CONVERT(smallint, TRIM(StartYear)) IS NULL
  )
  BEGIN
    SELECT *
    FROM #SponsorRosterLanding
    WHERE NULLIF(TRIM(StartYear), '') IS NOT NULL
      AND TRY_CONVERT(smallint, TRIM(StartYear)) IS NULL;

    THROW 50004, 'Roster validation failed: invalid StartYear.',1;
END;

IF EXISTS (
    SELECT *
    FROM #SponsorRosterLanding
    WHERE Party IS NOT NULL
      AND TRIM(Party) NOT IN ('D', 'R', 'X')
)
BEGIN
SELECT *
FROM #SponsorRosterLanding
WHERE Party IS NOT NULL
  AND TRIM(Party) NOT IN ('D', 'R', 'X');
  
THROW 50005, 'Roster validation failed: invalid Party',1;
END;

IF EXISTS (
    SELECT
        Title,
        LastName,
        FirstName,
        NameInitial,
        Party,
        District,
        StartYear,
        PreferredEmail,
        COUNT(*) AS NumberRowCount
    FROM #SponsorRosterLanding
    GROUP BY
        Title,
        LastName,
        FirstName,
        NameInitial,
        Party,
        District,
        StartYear,
        PreferredEmail
    HAVING COUNT(*) > 1
)
BEGIN
    SELECT
        Title,
        LastName,
        FirstName,
        NameInitial,
        Party,
        District,
        StartYear,
        PreferredEmail,
        COUNT(*) AS NumberRowCount
    FROM #SponsorRosterLanding
    GROUP BY
        Title,
        LastName,
        FirstName,
        NameInitial,
        Party,
        District,
        StartYear,
        PreferredEmail
    HAVING COUNT(*) > 1;
  
    THROW 50006, 'Roster validation failed: identical duplicate rows.', 1;
END;

/* ============================================================
   3. IDENTITY RESOLUTION

   Match each validated roster person to an existing Person
   sponsor when the identity can be resolved safely.

   Agreed resolution rules:

       0 exact FirstName + LastName Sponsor candidates:
           New

       1 exact FirstName + LastName Sponsor candidate:
           Existing, unless available supporting evidence
           contradicts the match.

       2+ exact FirstName + LastName Sponsor candidates:
           Use supporting evidence (such as NameInitial and
           PreferredEmail) to attempt an unambiguous resolution.

           If one candidate can be identified safely:
               Existing

           If identity remains ambiguous:
               NeedsReview and STOP the load.

       Any contradictory evidence that makes identity uncertain:
           NeedsReview and STOP the load.

   Robustness boundary:
       The process does not need to automatically solve every
       identity edge case. It must detect uncertainty and refuse
       to guess.

   No persistent data is changed in this section.
   ============================================================ */

/*
    Working table for one resolution result per roster person.

    CandidateCount records the number of existing Person sponsors
    that match the roster person's exact FirstName + LastName.

    NOTE: The SQL that populates this table under the new rules
    has not been written yet. This is the current development
    checkpoint.
*/
CREATE TABLE #SponsorResolution (
    FirstName nvarchar(100) NOT NULL,
    LastName nvarchar(100) NOT NULL,
    NameInitial nvarchar(20) NULL,
    PreferredEmail nvarchar(255) NULL,
    SponsorID int NULL,
    ResolutionStatus varchar(20) NOT NULL,
    CandidateCount smallint NOT NULL
);


/* ============================================================
   PHASE 3: RESOLVE SPONSOR IDENTITY
   ============================================================

   Identity-resolution rules:

   1. FirstName + LastName establishes the pool of possible
      existing Person sponsors.

   2. Evidence is interpreted as follows:

      NameInitial
        - same non-NULL value: supporting
        - different non-NULL value: review required
        - missing value: neutral

      OfficeType
        - same value: supporting
        - different value: review required

      District
        - same value: supporting
        - different value: review required

      StartYear
        - same non-NULL value: supporting
        - different non-NULL value: review required
        - missing value: neutral

      PreferredEmail
        - same non-NULL value: supporting
        - different value: neutral
        - missing value: neutral

   3. One existing exact-name candidate:
        - resolve automatically only when no review-worthy
          historical evidence conflicts with the incoming row.

   4. Multiple existing exact-name candidates:
        - resolve only when positive evidence uniquely identifies
          one candidate.
        - otherwise NeedsReview.

   5. No existing exact-name candidate:
        - one incoming person with that name = New
        - multiple incoming people with that name = NeedsReview

   NeedsReview does not mean the records are different people.
   It means the automated process does not have enough evidence
   to make the identity decision safely.
   ============================================================ */


WITH IncomingNameCounts AS (
    /*
        Detect duplicate exact names within the incoming roster.

        This matters when no existing Sponsor is available:
        the current 5A/5B process cannot safely create and reconnect
        multiple new Sponsors having the same exact name.
    */
    SELECT
        FirstName,
        LastName,
        COUNT(*) AS IncomingNameCount
    FROM #SponsorRosterLanding
    GROUP BY
        FirstName,
        LastName
),

CandidateMatches AS (
    /*
        Count existing Person sponsors having the same exact
        FirstName + LastName as each incoming roster person.

        CandidateSponsorID is useful only when CandidateCount = 1.
        MAX(SponsorID) does NOT resolve identity when more than
        one candidate exists.
    */
    SELECT
        L.FirstName,
        L.LastName,
        COUNT(S.SponsorID) AS CandidateCount,
        MAX(S.SponsorID) AS CandidateSponsorID
    FROM #SponsorRosterLanding AS L
    LEFT JOIN CapitalOutlay.Sponsor AS S
        ON L.FirstName = S.GivenName
        AND L.LastName = S.LastName
        AND S.SponsorType = 'Person'
    GROUP BY
        L.FirstName,
        L.LastName
),

SingleCandidateReview AS (
    /*
        For an exact name having one existing Sponsor candidate,
        determine whether historical service evidence contains a
        review-worthy change.

        PreferredEmail is deliberately NOT treated as contradictory.
        The real roster data demonstrated that this contact value can
        legitimately change between years.

        Historical evidence from the immediately preceding service
        year is used when available so that older legitimate changes
        do not permanently make a Sponsor unresolvable.
    */
    SELECT DISTINCT
    L.FirstName,
    L.LastName,
    C.CandidateSponsorID AS SponsorID
FROM #SponsorRosterLanding AS L
INNER JOIN CandidateMatches AS C
    ON L.FirstName = C.FirstName
    AND L.LastName = C.LastName
    AND C.CandidateCount = 1
WHERE EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorService AS SS
    WHERE SS.SponsorID = C.CandidateSponsorID
      AND SS.ServiceYear = @ServiceYear - 1
      AND (
            (
                SS.NameInitial IS NOT NULL
                AND L.NameInitial IS NOT NULL
                AND SS.NameInitial <> L.NameInitial
            )
            OR
            SS.OfficeType <> L.Title
            OR
            SS.District <> TRY_CONVERT(smallint, L.District)
          )
)
),

SupportedCandidates AS (
    /*
        This CTE is used only when multiple existing Sponsors have
        the same exact FirstName + LastName.

        Positive evidence may distinguish one candidate:
            - matching NameInitial
            - matching OfficeType + District
            - matching StartYear
            - matching PreferredEmail

        Review-worthy conflicting evidence prevents a candidate
        from being automatically selected:
            - conflicting non-NULL NameInitial
            - different OfficeType
            - different District
            - conflicting non-NULL StartYear

        A changed PreferredEmail is neutral, not contradictory.

        A candidate must have at least one piece of positive evidence
        and no review-worthy conflicting evidence.
    */
    SELECT
        L.FirstName,
        L.LastName,
        L.NameInitial,
        L.PreferredEmail,
        COUNT(DISTINCT S.SponsorID) AS SupportedCandidateCount,
        MAX(S.SponsorID) AS SupportedSponsorID
    FROM #SponsorRosterLanding AS L
    INNER JOIN CapitalOutlay.Sponsor AS S
        ON L.FirstName = S.GivenName
        AND L.LastName = S.LastName
        AND S.SponsorType = 'Person'
    INNER JOIN CandidateMatches AS C
        ON L.FirstName = C.FirstName
        AND L.LastName = C.LastName
        AND C.CandidateCount > 1
    WHERE
        EXISTS (
            SELECT 1
            FROM CapitalOutlay.SponsorService AS SS
            WHERE SS.SponsorID = S.SponsorID

              /* Positive supporting evidence */
              AND (
                    (
                        L.NameInitial IS NOT NULL
                        AND SS.NameInitial IS NOT NULL
                        AND L.NameInitial = SS.NameInitial
                    )
                    OR
                    (
                        SS.OfficeType = L.Title
                        AND SS.District =
                            TRY_CONVERT(smallint, L.District)
                    )
                    OR
                    (
                        NULLIF(TRIM(L.StartYear), '') IS NOT NULL
                        AND SS.StartYear IS NOT NULL
                        AND SS.StartYear =
                            TRY_CONVERT(smallint, TRIM(L.StartYear))
                    )
                    OR
                    (
                        L.PreferredEmail IS NOT NULL
                        AND SS.PreferredEmail IS NOT NULL
                        AND L.PreferredEmail = SS.PreferredEmail
                    )
                  )
        )

        AND NOT EXISTS (
            SELECT 1
            FROM CapitalOutlay.SponsorService AS SS
            WHERE SS.SponsorID = S.SponsorID
              AND SS.ServiceYear = @ServiceYear - 1

              /* Review-worthy conflicting evidence */
              AND (
                    (
                        L.NameInitial IS NOT NULL
                        AND SS.NameInitial IS NOT NULL
                        AND L.NameInitial <> SS.NameInitial
                    )
                    OR
                    SS.OfficeType <> L.Title
                    OR
                    SS.District <>
                        TRY_CONVERT(smallint, L.District)
                    OR
                    (
                        NULLIF(TRIM(L.StartYear), '') IS NOT NULL
                        AND SS.StartYear IS NOT NULL
                        AND SS.StartYear <>
                            TRY_CONVERT(smallint, TRIM(L.StartYear))
                    )
                  )
        )
    GROUP BY
        L.FirstName,
        L.LastName,
        L.NameInitial,
        L.PreferredEmail
)

INSERT INTO #SponsorResolution (
    FirstName,
    LastName,
    NameInitial,
    PreferredEmail,
    SponsorID,
    ResolutionStatus,
    CandidateCount
)
SELECT
    L.FirstName,
    L.LastName,
    L.NameInitial,
    L.PreferredEmail,

    CASE
    /* One safe existing candidate */
    WHEN C.CandidateCount = 1
         AND SCR.SponsorID IS NULL
        THEN C.CandidateSponsorID

    /* Multiple candidates, but evidence identifies exactly one */
    WHEN C.CandidateCount > 1
         AND M.SupportedCandidateCount = 1
        THEN M.SupportedSponsorID

    /* Automatic resolution could not decide, but a human has approved the match */
    WHEN SRR.ApprovedSponsorID IS NOT NULL
        THEN SRR.ApprovedSponsorID

    ELSE NULL
END AS SponsorID,

CASE
    /*
        Nobody with this name exists yet, and this is the only
        incoming person with the name.
    */
    WHEN C.CandidateCount = 0
         AND INC.IncomingNameCount = 1
        THEN 'New'

    /*
        Multiple new people with the same exact name cannot
        safely be created/reconnected by the current process.
    */
    WHEN C.CandidateCount = 0
         AND INC.IncomingNameCount > 1
         AND SRR.ApprovedSponsorID IS NULL
        THEN 'NeedsReview'

    /*
        One existing candidate with no review-worthy conflict.
    */
    WHEN C.CandidateCount = 1
         AND SCR.SponsorID IS NULL
        THEN 'Existing'

    /*
        Multiple candidates where exactly one is uniquely
        supported.
    */
    WHEN C.CandidateCount > 1
         AND M.SupportedCandidateCount = 1
        THEN 'Existing'

    /*
        Automatic resolution could not decide, but a human
        has approved the match.
    */
    WHEN SRR.ApprovedSponsorID IS NOT NULL
        THEN 'Existing'

    /*
        Anything the rules above cannot safely resolve.
    */
    ELSE 'NeedsReview'
END AS ResolutionStatus,

    C.CandidateCount

FROM #SponsorRosterLanding AS L

INNER JOIN IncomingNameCounts AS INC
    ON L.FirstName = INC.FirstName
    AND L.LastName = INC.LastName

LEFT JOIN CandidateMatches AS C
    ON L.FirstName = C.FirstName
    AND L.LastName = C.LastName

LEFT JOIN SingleCandidateReview AS SCR
    ON L.FirstName = SCR.FirstName
    AND L.LastName = SCR.LastName

LEFT JOIN SupportedCandidates AS M
    ON L.FirstName = M.FirstName
    AND L.LastName = M.LastName
    AND (
        L.NameInitial = M.NameInitial
        OR (L.NameInitial IS NULL AND M.NameInitial IS NULL)
    )
    AND (
        L.PreferredEmail = M.PreferredEmail
        OR (L.PreferredEmail IS NULL AND M.PreferredEmail IS NULL)
    )

LEFT JOIN CapitalOutlay.SponsorRosterResolution AS SRR
    ON SRR.ServiceYear = @ServiceYear
    AND SRR.GivenName = L.FirstName
    AND SRR.LastName = L.LastName
    AND (
        SRR.NameInitial = L.NameInitial
        OR (SRR.NameInitial IS NULL AND L.NameInitial IS NULL)
    )
    AND SRR.OfficeType =
        CASE
            WHEN L.Title = 'Senator' THEN 'Senator'
            WHEN L.Title = 'Representative' THEN 'Representative'
        END
    AND SRR.District = TRY_CONVERT(smallint, L.District);


/* Review the resolution results before the Phase 4 gate. */

SELECT *
FROM #SponsorResolution
ORDER BY LastName, FirstName;

SELECT
    ResolutionStatus,
    CandidateCount,
    COUNT(*) AS ResolutionCount
FROM #SponsorResolution
GROUP BY
    ResolutionStatus,
    CandidateCount
ORDER BY
    ResolutionStatus,
    CandidateCount;


  /* ============================================================
   PHASE 4: ENSURE EVERY ROSTER ROW IS PROCESSABLE
   ============================================================ */

IF EXISTS (
    SELECT 1
    FROM #SponsorResolution
    WHERE ResolutionStatus NOT IN ('New', 'Existing')
)
BEGIN
/*
    Show the incoming roster row beside the most recent known
    service history for each possible existing Sponsor.

    This output is intended for troubleshooting. Review the
    differences before changing source data or identity rules.
*/
SELECT
    /* Incoming roster information */
    L.FirstName AS IncomingFirstName,
    L.LastName AS IncomingLastName,
    L.Title AS IncomingOffice,
    TRY_CONVERT(smallint, L.District) AS IncomingDistrict,
    L.NameInitial AS IncomingInitial,
    TRY_CONVERT(smallint, NULLIF(TRIM(L.StartYear), ''))
        AS IncomingStartYear,
    L.PreferredEmail AS IncomingContact,

    /* Resolution information */
    R.CandidateCount,

    /* Possible existing Sponsor */
    S.SponsorID AS CandidateSponsorID,
    S.DisplayName AS CandidateName,

    /* Most recent service information for that Sponsor */
    SS.ServiceYear AS PreviousServiceYear,
    SS.OfficeType AS PreviousOffice,
    SS.District AS PreviousDistrict,
    SS.NameInitial AS PreviousInitial,
    SS.StartYear AS PreviousStartYear,
    SS.PreferredEmail AS PreviousContact

FROM #SponsorResolution AS R

INNER JOIN #SponsorRosterLanding AS L
    ON R.FirstName = L.FirstName
    AND R.LastName = L.LastName

LEFT JOIN CapitalOutlay.Sponsor AS S
    ON R.FirstName = S.GivenName
    AND R.LastName = S.LastName
    AND S.SponsorType = 'Person'

LEFT JOIN CapitalOutlay.SponsorService AS SS
    ON S.SponsorID = SS.SponsorID
    AND SS.ServiceYear = (
        SELECT MAX(SS2.ServiceYear)
        FROM CapitalOutlay.SponsorService AS SS2
        WHERE SS2.SponsorID = S.SponsorID
          AND SS2.ServiceYear < @ServiceYear
    )

WHERE R.ResolutionStatus = 'NeedsReview'

ORDER BY
    L.LastName,
    L.FirstName,
    S.SponsorID;

    THROW 50007,
        'Roster identity resolution failed: one or more people require review.',
        1;
END;


IF EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorService AS SS
    WHERE SS.ServiceYear = @ServiceYear
)
BEGIN
    THROW 50008, 'This year has already been uploaded.', 1;
END;


/* ============================================================
   PHASE 5: WRITE PERSISTENT DATA
   ============================================================ */

BEGIN TRANSACTION;


/* ------------------------------------------------------------
   5A: CREATE NEW SPONSORS
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.Sponsor (
    GivenName,
    LastName,
    SponsorType,
    DisplayName
)
SELECT
    R.FirstName,
    R.LastName,
    'Person',
    CONCAT(
        R.FirstName,
        ' ',
        CASE
            WHEN NULLIF(TRIM(R.NameInitial), '') IS NOT NULL
                THEN CONCAT(TRIM(R.NameInitial), ' ')
            ELSE ''
        END,
        R.LastName
    )
FROM #SponsorResolution AS R
WHERE R.ResolutionStatus = 'New';

/* ------------------------------------------------------------
   5B: CONNECT NEW SPONSORS TO RESOLUTION
   ------------------------------------------------------------ */

UPDATE R
SET R.SponsorID = S.SponsorID
FROM #SponsorResolution AS R
INNER JOIN CapitalOutlay.Sponsor AS S
    ON R.FirstName = S.GivenName
    AND R.LastName = S.LastName
    AND S.SponsorType = 'Person'
WHERE R.ResolutionStatus = 'New';

/* ------------------------------------------------------------
   5C: CREATE ANNUAL SPONSOR SERVICE RECORDS
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorService (
    SponsorID,
    ServiceYear,
    OfficeType,
    Party,
    District,
    NameInitial,
    StartYear,
    PreferredEmail
)
SELECT
    R.SponsorID,
    @ServiceYear,
    TRIM(L.Title),
    NULLIF(TRIM(L.Party), ''),
    TRY_CONVERT(smallint, TRIM(L.District)),
    NULLIF(TRIM(L.NameInitial), ''),
    TRY_CONVERT(smallint, NULLIF(TRIM(L.StartYear), '')),
    NULLIF(TRIM(L.PreferredEmail), '')
FROM #SponsorRosterLanding AS L
INNER JOIN #SponsorResolution AS R
    ON L.FirstName = R.FirstName
    AND L.LastName = R.LastName;


  /* ============================================================
   PHASE 6: VERIFY AND FINISH
   ============================================================ */

/*
    Every processable roster person must now have a SponsorID.
    If not, undo all persistent changes made during this run.
*/
IF EXISTS (
    SELECT 1
    FROM #SponsorResolution
    WHERE SponsorID IS NULL
)
BEGIN
    ROLLBACK;

    THROW 50009,
        'Roster load failed: one or more resolved people do not have a SponsorID.',
        1;
END;


/*
    The number of SponsorService records created for this service
    year must equal the number of validated roster rows.
*/
IF (
    SELECT COUNT(*)
    FROM CapitalOutlay.SponsorService AS SS
    WHERE SS.ServiceYear = @ServiceYear
) <> (
    SELECT COUNT(*)
    FROM #SponsorRosterLanding
)
BEGIN
    ROLLBACK;

    THROW 50010,
        'Roster load failed: SponsorService count does not match the validated roster.',
        1;
END;


/*
    Each validated roster person must resolve to a different Sponsor
    for this service year. This prevents two roster rows from being
    assigned to the same SponsorID.
*/
IF (
    SELECT COUNT(DISTINCT SS.SponsorID)
    FROM CapitalOutlay.SponsorService AS SS
    WHERE SS.ServiceYear = @ServiceYear
) <> (
    SELECT COUNT(*)
    FROM #SponsorRosterLanding
)
BEGIN
    ROLLBACK;

    THROW 50011,
        'Roster load failed: multiple roster rows resolved to the same Sponsor.',
        1;
END;


/*
    All verification checks passed.
    Make the transaction permanent.
*/
COMMIT;