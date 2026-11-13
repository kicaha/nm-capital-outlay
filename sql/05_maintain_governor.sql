USE NMCapitalOutlay;
GO

/*
    05 - Maintain Governor

    The Governor is not included in the annual legislator roster and
    must be maintained manually.

    Each year:
    1. Verify the Governor's information using an official source.
    2. Search Sponsor for possible name variations before running this
       script. A Governor may already exist from legislative service.
    3. Update the INPUT VALUES below.
    4. Run the script and review the verification result.
*/


/* ============================================================
   1. INPUT VALUES
   ============================================================ */

DECLARE @ServiceYear smallint = 2026;
DECLARE @GivenName nvarchar(100) = N'Michelle';
DECLARE @LastName nvarchar(100) = N'Lujan Grisham';
DECLARE @DisplayName nvarchar(200) = N'Michelle Lujan Grisham';
DECLARE @Party varchar(25) = 'D';
DECLARE @StartYear smallint = 2019;


/* ============================================================
   2. MAINTAIN GOVERNOR SPONSOR
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.Sponsor
    WHERE GivenName = @GivenName
      AND LastName = @LastName
      AND SponsorType = 'Person'
)
BEGIN
    INSERT INTO CapitalOutlay.Sponsor (
        GivenName, LastName, SponsorType, DisplayName
    )
    VALUES (
        @GivenName, @LastName, 'Person', @DisplayName
    );
END;


/* ============================================================
   3. GET GOVERNOR SPONSOR ID
   ============================================================ */

DECLARE @SponsorID int;

SELECT @SponsorID = SponsorID
FROM CapitalOutlay.Sponsor
WHERE GivenName = @GivenName
  AND LastName = @LastName
  AND SponsorType = 'Person';

/* ============================================================
   4. MAINTAIN GOVERNOR SERVICE
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorService
    WHERE SponsorID = @SponsorID
      AND ServiceYear = @ServiceYear
      AND OfficeType = 'Governor'
)
BEGIN
    INSERT INTO CapitalOutlay.SponsorService (
        SponsorID, ServiceYear, OfficeType, Party,
        District, NameInitial, StartYear, PreferredEmail
    )
    VALUES (
        @SponsorID, @ServiceYear, 'Governor', @Party,
        NULL, NULL, @StartYear, NULL
    );
END;

/* ============================================================
   5. VERIFY
   ============================================================ */

SELECT
    S.SponsorID,
    S.DisplayName,
    SS.ServiceYear,
    SS.OfficeType,
    SS.Party,
    SS.District,
    SS.StartYear
FROM CapitalOutlay.Sponsor AS S
INNER JOIN CapitalOutlay.SponsorService AS SS
    ON S.SponsorID = SS.SponsorID
WHERE S.SponsorID = @SponsorID
  AND SS.OfficeType = 'Governor'
ORDER BY SS.ServiceYear;