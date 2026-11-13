USE NMCapitalOutlay;
GO

/* ============================================================
   2023 Sponsor Remediation

   Resolves known 2023 sponsor labels that cannot be safely
   resolved by the standard annual load process.

   This script is designed to be safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   1. Add verified sponsor aliases

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
        (N'García MP',   'Miguel P. MP Garcia'),
        (N'Muñoz',       'George K. Munoz'),
        ('Martinez A.',  'Alan T. A. Martinez')
) AS V (SourceSponsorLabel, DisplayName)
JOIN CapitalOutlay.Sponsor AS S
    ON S.DisplayName = V.DisplayName
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorAlias AS SA
    WHERE SA.SourceSponsorLabel = V.SourceSponsorLabel
);


/* ------------------------------------------------------------
   2. Apply verified aliases to unresolved 2023 appropriations
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = SA.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.SponsorAlias AS SA
    ON AP.SourceSponsorLabel = SA.SourceSponsorLabel
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2023
  AND AP.SponsorID IS NULL
  AND SA.IsAutoResolvable = 1;


/* ------------------------------------------------------------
   3. Resolve ambiguous "Armstrong" source labels

   The Sponsor table contains two Armstrong sponsors:

     Deborah A. Armstrong
       House District 17
       Served through 2022

     Gail Armstrong
       House District 49
       Served in 2023

   Gail Armstrong is the only Armstrong with a 2023
   SponsorService record.

   Because "Armstrong" can represent more than one Sponsor,
   it must NOT be added as a global SponsorAlias.
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
WHERE LP.LegislativeYear = 2023
  AND AP.SourceSponsorLabel = 'Armstrong'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   4. Resolve ambiguous "Montoya" source labels

   The Sponsor table contains multiple Montoya sponsors.

   Roger Montoya served through 2022.
   Rod Montoya, House District 1, is the only Montoya with
   a 2023 SponsorService record.

   Because "Montoya" can represent more than one Sponsor,
   it must NOT be added as a global SponsorAlias.
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
WHERE LP.LegislativeYear = 2023
  AND AP.SourceSponsorLabel = 'Montoya'
  AND AP.SponsorID IS NULL;


/* ------------------------------------------------------------
   5. Verify no nonblank 2023 sponsor labels remain unresolved

   Expected result: 0 rows
   ------------------------------------------------------------ */

SELECT
    AP.SourceSponsorLabel,
    COUNT(*) AS UnresolvedCount
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2023
  AND AP.SponsorID IS NULL
  AND AP.SourceSponsorLabel IS NOT NULL
GROUP BY AP.SourceSponsorLabel
ORDER BY AP.SourceSponsorLabel;