USE NMCapitalOutlay;
GO

/* ============================================================
   2024 Sponsor Remediation

   Resolves known 2024 sponsor labels that cannot be safely
   resolved by the standard annual load process.

   This script is designed to be safely rerunnable.
   ============================================================ */

   USE NMCapitalOutlay;
GO

/* ============================================================
   2024 Sponsor Remediation

   Resolves known 2024 sponsor labels that cannot be safely
   resolved by the standard annual load process.

   This script is designed to be safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   1. Add verified sponsor aliases

   These source labels identify a specific sponsor and are safe
   for automatic resolution in future loads.

   SponsorIDs are looked up from Sponsor rather than hard-coded
   because identity values may differ between database builds.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorAlias
    (SourceSponsorLabel, SponsorID, IsAutoResolvable)
SELECT
    V.SourceSponsorLabel,
    S.SponsorID,
    1
FROM (
    VALUES
        (N'Parajón',          'Cristina Parajon'),
        ('Diamond Brantley',  'Crystal Diamond Brantley')
) AS V (SourceSponsorLabel, DisplayName)
JOIN CapitalOutlay.Sponsor AS S
    ON S.DisplayName = V.DisplayName
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorAlias AS SA
    WHERE SA.SourceSponsorLabel = V.SourceSponsorLabel
);


/* ------------------------------------------------------------
   2. Apply verified aliases to unresolved 2024 appropriations
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = SA.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.SponsorAlias AS SA
    ON AP.SourceSponsorLabel = SA.SourceSponsorLabel
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2024
  AND AP.SponsorID IS NULL
  AND SA.IsAutoResolvable = 1;


/* ------------------------------------------------------------
   3. Resolve "López"

   Both Linda M. Lopez and Antoinette Sedillo Lopez served
   during 2024, so "López" must NOT be added as a global
   auto-resolvable SponsorAlias.

   The 2024 Legislative Council Service capital outlay source
   distinguishes the two sponsors:
       Linda M. Lopez       -> López
       Antoinette S. Lopez  -> Sedillo Lopez

   Therefore 2024 "López" appropriations resolve to
   Linda M. Lopez.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN (
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = 'Linda M. Lopez'
) AS S
WHERE LP.LegislativeYear = 2024
  AND AP.SourceSponsorLabel = N'López'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   4. Resolve "Armstrong"

   Multiple Armstrong sponsors exist historically.

   Gail Armstrong served as Representative District 49 in
   2024 and is the Armstrong identified in the 2024 capital
   outlay source.

   Because "Armstrong" is not globally unique, it must NOT be
   added as a global auto-resolvable SponsorAlias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN (
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = 'Gail G. Armstrong'
) AS S
WHERE LP.LegislativeYear = 2024
  AND AP.SourceSponsorLabel = 'Armstrong'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   5. Resolve "Montoya"

   Multiple Montoya sponsors exist historically.

   Rod Montoya is the applicable Montoya for the 2024
   legislative year.

   Because "Montoya" is not globally unique, it must NOT be
   added as a global auto-resolvable SponsorAlias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN (
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = 'Rod RD Montoya'
) AS S
WHERE LP.LegislativeYear = 2024
  AND AP.SourceSponsorLabel = 'Montoya'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   6. Verify no nonblank 2024 sponsor labels remain unresolved

   Expected result: 0 rows
   ------------------------------------------------------------ */

SELECT
    AP.SourceSponsorLabel,
    COUNT(*) AS UnresolvedCount
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2024
  AND AP.SponsorID IS NULL
  AND NULLIF(TRIM(AP.SourceSponsorLabel), '') IS NOT NULL
GROUP BY AP.SourceSponsorLabel
ORDER BY AP.SourceSponsorLabel;