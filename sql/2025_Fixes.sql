USE NMCapitalOutlay;
GO

/* ============================================================
   2025 Sponsor Remediation

   Resolves known 2025 appropriation sponsor labels that cannot
   be safely resolved by the standard annual load process.

   Safe, uniquely identifying labels are added to SponsorAlias.
   Historically ambiguous labels are resolved only for 2025.

   This script is designed to be safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   1. Add verified sponsor aliases

   These source labels identify a specific canonical sponsor
   and are safe for automatic resolution in future loads.

   SponsorIDs are looked up from Sponsor rather than hard-coded
   because identity values may differ between database builds.
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorAlias
(
    SourceSponsorLabel,
    SponsorID,
    IsAutoResolvable
)
SELECT
    V.SourceSponsorLabel,
    S.SponsorID,
    1
FROM
(
    VALUES
        (N'House/Senate Cap', N'House/Senate Cap'),
        (N'Chavez N.',        N'Nicole N. Chavez'),
        (N'Chávez E.',        N'Eleanor Chávez'),
        (N'Hernandez JN',     N'Joshua N. Hernandez'),
        (N'Hernandez JF',     N'Joseph Franklin JF Hernandez')
) AS V
(
    SourceSponsorLabel,
    DisplayName
)
JOIN CapitalOutlay.Sponsor AS S
    ON S.DisplayName = V.DisplayName
WHERE NOT EXISTS
(
    SELECT 1
    FROM CapitalOutlay.SponsorAlias AS SA
    WHERE SA.SourceSponsorLabel = V.SourceSponsorLabel
);


/* ------------------------------------------------------------
   2. Apply verified aliases to unresolved 2025 appropriations
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = SA.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.SponsorAlias AS SA
    ON AP.SourceSponsorLabel = SA.SourceSponsorLabel
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2025
  AND AP.SponsorID IS NULL
  AND SA.IsAutoResolvable = 1;


/* ------------------------------------------------------------
   3. Resolve "López"

   Lopez is historically ambiguous.

   The 2025 source label "López" identifies Linda M. Lopez.
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
WHERE LP.LegislativeYear = 2025
  AND AP.SourceSponsorLabel = N'López'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   4. Resolve "Armstrong"

   Multiple Armstrong sponsors exist historically.

   Gail G. Armstrong is the applicable Armstrong for the
   2025 legislative year.

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
WHERE LP.LegislativeYear = 2025
  AND AP.SourceSponsorLabel = N'Armstrong'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   5. Resolve "Garcia"

   Multiple Garcia sponsors served in 2025.

   Review of the 14 affected 2025 project WebIDs confirms that
   this source label identifies Martha Garcia, Representative
   District 6.

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
WHERE LP.LegislativeYear = 2025
  AND AP.SourceSponsorLabel = N'Garcia'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   6. Resolve "Montoya"

   Multiple Montoya sponsors exist historically.

   Rod RD Montoya is the applicable Montoya for the 2025
   legislative year.

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
WHERE LP.LegislativeYear = 2025
  AND AP.SourceSponsorLabel = N'Montoya'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   7. Verify no nonblank 2025 sponsor labels remain unresolved

   Expected result: 0 rows
   ------------------------------------------------------------ */

SELECT
    AP.SourceSponsorLabel,
    COUNT(*) AS UnresolvedCount
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2025
  AND AP.SponsorID IS NULL
  AND NULLIF(TRIM(AP.SourceSponsorLabel), '') IS NOT NULL
GROUP BY
    AP.SourceSponsorLabel
ORDER BY
    AP.SourceSponsorLabel;