USE NMCapitalOutlay;
GO

/* ============================================================
   2024 SPONSOR ROSTER RESOLUTIONS

   Records reviewed identity resolutions required by
   04_load_legislator for the 2024 legislative roster.

   SponsorIDs are looked up from Sponsor rather than hard-coded
   because identity values may differ between database builds.

   Script is safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   Miguel P. García

   Incoming roster uses García while the canonical Sponsor
   record uses Garcia.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear,
    GivenName,
    LastName,
    NameInitial,
    OfficeType,
    District,
    ApprovedSponsorID,
    ApprovedBy,
    ApprovedDate,
    ResolutionNote
)
SELECT
    2024,
    'Miguel P.',
    N'García',
    'MP',
    'Representative',
    14,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as Miguel P. MP Garcia; incoming 2024 roster uses García while existing canonical Sponsor uses Garcia.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Miguel P. MP Garcia'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2024
        AND R.GivenName = 'Miguel P.'
        AND R.LastName = N'García'
        AND R.NameInitial = 'MP'
        AND R.OfficeType = 'Representative'
        AND R.District = 14
  );


/* ------------------------------------------------------------
   Linda M. López

   Incoming roster uses López while the canonical Sponsor
   record uses Lopez.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear,
    GivenName,
    LastName,
    NameInitial,
    OfficeType,
    District,
    ApprovedSponsorID,
    ApprovedBy,
    ApprovedDate,
    ResolutionNote
)
SELECT
    2024,
    'Linda M.',
    N'López',
    NULL,
    'Senator',
    11,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as Linda M. Lopez; incoming 2024 roster uses López while existing canonical Sponsor uses Lopez.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Linda M. Lopez'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2024
        AND R.GivenName = 'Linda M.'
        AND R.LastName = N'López'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 11
  );


/* ------------------------------------------------------------
   George K. Muñoz

   Incoming roster uses Muñoz while the canonical Sponsor
   record uses Munoz.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear,
    GivenName,
    LastName,
    NameInitial,
    OfficeType,
    District,
    ApprovedSponsorID,
    ApprovedBy,
    ApprovedDate,
    ResolutionNote
)
SELECT
    2024,
    'George K.',
    N'Muñoz',
    NULL,
    'Senator',
    4,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as George K. Munoz; incoming 2024 roster uses Muñoz while existing canonical Sponsor uses Munoz.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'George K. Munoz'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2024
        AND R.GivenName = 'George K.'
        AND R.LastName = N'Muñoz'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 4
  );


/* ------------------------------------------------------------
   Greg Nibert

   Existing Sponsor served as Representative District 59
   through 2023 and appears in the 2024 roster as
   Senator District 27.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear,
    GivenName,
    LastName,
    NameInitial,
    OfficeType,
    District,
    ApprovedSponsorID,
    ApprovedBy,
    ApprovedDate,
    ResolutionNote
)
SELECT
    2024,
    'Greg',
    'Nibert',
    NULL,
    'Senator',
    27,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as Greg Nibert; Representative District 59 through 2023 and Senator District 27 beginning in 2024.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Greg Nibert'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2024
        AND R.GivenName = 'Greg'
        AND R.LastName = 'Nibert'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 27
  );


/* ------------------------------------------------------------
   Cristina Parajón

   Incoming roster uses Parajón while the canonical Sponsor
   record uses Parajon.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear,
    GivenName,
    LastName,
    NameInitial,
    OfficeType,
    District,
    ApprovedSponsorID,
    ApprovedBy,
    ApprovedDate,
    ResolutionNote
)
SELECT
    2024,
    'Cristina',
    N'Parajón',
    NULL,
    'Representative',
    25,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as Cristina Parajon; incoming 2024 roster uses Parajón while existing canonical Sponsor uses Parajon.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Cristina Parajon'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2024
        AND R.GivenName = 'Cristina'
        AND R.LastName = N'Parajón'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Representative'
        AND R.District = 25
  );