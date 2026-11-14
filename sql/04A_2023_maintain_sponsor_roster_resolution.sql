USE NMCapitalOutlay;
GO

/* ============================================================
   2023 SPONSOR ROSTER RESOLUTIONS

   Records reviewed identity resolutions required by
   04_load_legislator for the 2023 legislative roster.

   SponsorIDs are looked up from Sponsor rather than hard-coded
   because identity values may differ between database builds.

   Script is safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   Antonio Maestas

   Existing Sponsor served as Representative District 16
   through 2022 and appears in the 2023 roster as
   Senator District 26.
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
    2023,
    'Antonio',
    'Maestas',
    NULL,
    'Senator',
    26,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as Antonio Maestas; Representative District 16 through 2022 and Senator District 26 beginning in 2023.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Antonio Maestas'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2023
        AND R.GivenName = 'Antonio'
        AND R.LastName = 'Maestas'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 26
  );


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
    2023,
    'Miguel P.',
    N'García',
    'MP',
    'Representative',
    14,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as Miguel P. MP Garcia; incoming 2023 roster uses García while existing canonical Sponsor uses Garcia.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Miguel P. MP Garcia'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2023
        AND R.GivenName = 'Miguel P.'
        AND R.LastName = N'García'
        AND R.NameInitial = 'MP'
        AND R.OfficeType = 'Representative'
        AND R.District = 14
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
    2023,
    'George K.',
    N'Muñoz',
    NULL,
    'Senator',
    4,
    S.SponsorID,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as George K. Munoz; incoming 2023 roster uses Muñoz while existing canonical Sponsor uses Munoz.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'George K. Munoz'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2023
        AND R.GivenName = 'George K.'
        AND R.LastName = N'Muñoz'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Senator'
        AND R.District = 4
  );