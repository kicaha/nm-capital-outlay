USE NMCapitalOutlay;
GO

/* ============================================================
   2026 Sponsor Remediation

   Resolves known 2026 appropriation sponsor labels that cannot
   be safely resolved by the standard annual load process.

   All four labels below are historically/contextually ambiguous,
   so they are resolved only for the 2026 legislative year.

   This script is designed to be safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   1. Resolve "López"

   The 2026 source label identifies Linda M. Lopez.
   Do not add the surname-only label as a global alias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN
(
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = N'Linda M. Lopez'
) AS S
WHERE LP.LegislativeYear = 2026
  AND AP.SourceSponsorLabel = N'López'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   2. Resolve "Armstrong"

   Multiple Armstrong sponsors exist historically.

   Gail G. Armstrong is the applicable Armstrong for 2026.
   Do not add "Armstrong" as a global alias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN
(
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = N'Gail G. Armstrong'
) AS S
WHERE LP.LegislativeYear = 2026
  AND AP.SourceSponsorLabel = N'Armstrong'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   3. Resolve "Garcia"

   Multiple Garcia sponsors served in 2026.

   Review of the 15 affected 2026 project WebIDs confirms that
   this source label identifies Martha Garcia.

   Do not add "Garcia" as a global alias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN
(
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = N'Martha Garcia'
) AS S
WHERE LP.LegislativeYear = 2026
  AND AP.SourceSponsorLabel = N'Garcia'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   4. Resolve "Montoya"

   Multiple Montoya sponsors exist historically.

   Rod RD Montoya is the applicable Montoya for 2026.
   Do not add "Montoya" as a global alias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = S.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN
(
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = N'Rod RD Montoya'
) AS S
WHERE LP.LegislativeYear = 2026
  AND AP.SourceSponsorLabel = N'Montoya'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   5. Verify no nonblank 2026 sponsor labels remain unresolved

   Expected result: 0 rows
   ------------------------------------------------------------ */

SELECT
    AP.SourceSponsorLabel,
    COUNT(*) AS UnresolvedCount
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2026
  AND AP.SponsorID IS NULL
  AND NULLIF(TRIM(AP.SourceSponsorLabel), '') IS NOT NULL
GROUP BY
    AP.SourceSponsorLabel
ORDER BY
    AP.SourceSponsorLabel;