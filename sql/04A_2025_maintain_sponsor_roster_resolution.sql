USE NMCapitalOutlay;
GO

/* ============================================================
   2025 SPONSOR ROSTER RESOLUTIONS

   Records reviewed identity resolutions required by
   04_load_legislator for the 2025 legislative roster.

   SponsorIDs are looked up from Sponsor rather than hard-coded
   because identity values may differ between database builds.

   Script is safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   Candy Spence Ezzell

   Existing Sponsor served as Representative District 58
   through 2024 and appears in the 2025 roster as
   Senator District 32.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Candy Spence', 'Ezzell', NULL,
    'Senator', 32, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Candy Spence Ezzell; Representative District 58 through 2024 and Senator District 32 beginning in 2025.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Candy Spence Ezzell'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Candy Spence'
        AND R.LastName = 'Ezzell'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 32
  );


/* ------------------------------------------------------------
   Natalie Figueroa

   Existing Sponsor served as Representative District 30
   through 2024 and appears in the 2025 roster as
   Senator District 18.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Natalie', 'Figueroa', NULL,
    'Senator', 18, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Natalie Figueroa; Representative District 30 through 2024 and Senator District 18 beginning in 2025.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Natalie Figueroa'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Natalie'
        AND R.LastName = 'Figueroa'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 18
  );


/* ------------------------------------------------------------
   Miguel P. García

   Incoming roster uses García while the canonical Sponsor
   record uses Garcia. Incoming initial is MP.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Miguel P.', N'García', 'MP',
    'Representative', 14, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Miguel P. MP Garcia; incoming 2025 roster uses García while existing canonical Sponsor uses Garcia.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Miguel P. MP Garcia'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Miguel P.'
        AND R.LastName = N'García'
        AND R.NameInitial = 'MP'
        AND R.OfficeType = 'Representative'
        AND R.District = 14
  );


/* ------------------------------------------------------------
   Linda M. López
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Linda M.', N'López', NULL,
    'Senator', 11, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Linda M. Lopez; incoming 2025 roster uses López while existing canonical Sponsor uses Lopez.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Linda M. Lopez'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Linda M.'
        AND R.LastName = N'López'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 11
  );


/* ------------------------------------------------------------
   George K. Muñoz
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'George K.', N'Muñoz', NULL,
    'Senator', 4, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as George K. Munoz; incoming 2025 roster uses Muñoz while existing canonical Sponsor uses Munoz.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'George K. Munoz'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'George K.'
        AND R.LastName = N'Muñoz'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 4
  );


/* ------------------------------------------------------------
   Cristina Parajón
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Cristina', N'Parajón', NULL,
    'Representative', 25, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Cristina Parajon; incoming 2025 roster uses Parajón while existing canonical Sponsor uses Parajon.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Cristina Parajon'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Cristina'
        AND R.LastName = N'Parajón'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Representative'
        AND R.District = 25
  );


/* ------------------------------------------------------------
   Joshua A. Sanchez

   Existing Sponsor served as Senator District 30 in 2024
   and appears in the 2025 roster as Senator District 29.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Joshua A.', 'Sanchez', NULL,
    'Senator', 29, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Joshua A. Sanchez; Senator District 30 in 2024 and Senator District 29 beginning in 2025.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Joshua A. Sanchez'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Joshua A.'
        AND R.LastName = 'Sanchez'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 29
  );


/* ------------------------------------------------------------
   Larry R. Scott

   Existing Sponsor served as Representative District 62
   through 2024 and appears in the 2025 roster as
   Senator District 42.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'Larry R.', 'Scott', NULL,
    'Senator', 42, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Larry R. Scott; Representative District 62 through 2024 and Senator District 42 beginning in 2025.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Larry R. Scott'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'Larry R.'
        AND R.LastName = 'Scott'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 42
  );


/* ------------------------------------------------------------
   James G. Townsend

   Existing Sponsor served as Representative District 54
   through 2024 and appears in the 2025 roster as
   Senator District 34.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2025, 'James G.', 'Townsend', NULL,
    'Senator', 34, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as James G. Townsend; Representative District 54 through 2024 and Senator District 34 beginning in 2025.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'James G. Townsend'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2025
        AND R.GivenName = 'James G.'
        AND R.LastName = 'Townsend'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 34
  );