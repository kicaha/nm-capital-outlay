USE NMCapitalOutlay;
GO

/* ============================================================
   2026 SPONSOR ROSTER RESOLUTIONS

   Records reviewed identity resolutions required by
   04_load_legislator for the 2026 legislative roster.

   SponsorIDs are looked up from Sponsor rather than hard-coded
   because identity values may differ between database builds.

   Script is safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   Miguel P. García
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorRosterResolution (
    ServiceYear, GivenName, LastName, NameInitial,
    OfficeType, District, ApprovedSponsorID,
    ApprovedBy, ApprovedDate, ResolutionNote
)
SELECT
    2026, 'Miguel P.', N'García', 'MP',
    'Representative', 14, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Miguel P. MP Garcia; incoming 2026 roster uses García while existing canonical Sponsor uses Garcia.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Miguel P. MP Garcia'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2026
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
    2026, 'Linda M.', N'López', NULL,
    'Senator', 11, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Linda M. Lopez; incoming 2026 roster uses López while existing canonical Sponsor uses Lopez.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Linda M. Lopez'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2026
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
    2026, 'George K.', N'Muñoz', NULL,
    'Senator', 4, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as George K. Munoz; incoming 2026 roster uses Muñoz while existing canonical Sponsor uses Munoz.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'George K. Munoz'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2026
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
    2026, 'Cristina', N'Parajón', NULL,
    'Representative', 25, S.SponsorID,
    'Kim', CAST(GETDATE() AS date),
    'Verified as same person as Cristina Parajon; incoming 2026 roster uses Parajón while existing canonical Sponsor uses Parajon.'
FROM CapitalOutlay.Sponsor AS S
WHERE S.DisplayName = 'Cristina Parajon'
  AND NOT EXISTS (
      SELECT 1
      FROM CapitalOutlay.SponsorRosterResolution AS R
      WHERE R.ServiceYear = 2026
        AND R.GivenName = 'Cristina'
        AND R.LastName = N'Parajón'
        AND R.NameInitial IS NULL
        AND R.OfficeType = 'Representative'
        AND R.District = 25
  );