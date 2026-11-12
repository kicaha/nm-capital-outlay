USE NMCapitalOutlay;
GO

/* ============================================================
   2022 Sponsor Remediation

   Resolves known 2022 sponsor labels that cannot be safely
   resolved by the standard annual load process.

   This script is designed to be safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   1. Add verified sponsor aliases
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.SponsorAlias
    (SourceSponsorLabel, SponsorID, IsAutoResolvable)
SELECT
    V.SourceSponsorLabel,
    S.SponsorID,
    1
FROM (
    VALUES
        ('Montoya RD', 'Rod RD Montoya'),
        ('Montoya RE', 'Roger E. RE Montoya')
) AS V (SourceSponsorLabel, DisplayName)
JOIN CapitalOutlay.Sponsor AS S
    ON S.DisplayName = V.DisplayName
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorAlias AS SA
    WHERE SA.SourceSponsorLabel = V.SourceSponsorLabel
);


/* ------------------------------------------------------------
   2. Apply verified aliases to unresolved 2022 appropriations
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = SA.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.SponsorAlias AS SA
    ON AP.SourceSponsorLabel = SA.SourceSponsorLabel
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2022
  AND AP.SponsorID IS NULL
  AND SA.IsAutoResolvable = 1;


/* ------------------------------------------------------------
   3. Verify no nonblank 2022 sponsor labels remain unresolved

   Expected result: 0 rows
   ------------------------------------------------------------ */

SELECT
    AP.SourceSponsorLabel,
    COUNT(*) AS UnresolvedCount
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2022
  AND AP.SponsorID IS NULL
  AND AP.SourceSponsorLabel IS NOT NULL
GROUP BY AP.SourceSponsorLabel
ORDER BY AP.SourceSponsorLabel;