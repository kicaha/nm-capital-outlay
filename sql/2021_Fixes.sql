USE NMCapitalOutlay;
GO

/* ============================================================
   2021 Sponsor Remediation

   Resolves known 2021 sponsor labels that cannot be safely
   resolved by the standard annual load process.

   This script is designed to be safely rerunnable.
   ============================================================ */


/* ------------------------------------------------------------
   1. Add sponsors missing from the standard source data
   ------------------------------------------------------------ */

INSERT INTO CapitalOutlay.Sponsor
    (GivenName, LastName, SponsorType, DisplayName)
SELECT
    V.GivenName,
    V.LastName,
    V.SponsorType,
    V.DisplayName
FROM (
    VALUES
        (NULL,             NULL,        'Institutional', 'Statewide'),
        (NULL,             NULL,        'Institutional', 'House/Senate Cap'),
        ('Melanie',        'Stansbury', 'Person',        'Melanie Stansbury'),
        ('Sheryl Williams','Stapleton', 'Person',        'Sheryl Williams Stapleton')
) AS V (GivenName, LastName, SponsorType, DisplayName)
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.Sponsor AS S
    WHERE S.DisplayName = V.DisplayName
);

/* ------------------------------------------------------------
   2. Add verified sponsor aliases

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
        ('Statewide',       'Statewide'),
        ('Armstrong D.',    'Deborah A. D. Armstrong'),
        ('Armstrong G.',    'Gail G. Armstrong'),
        ('Gallegos',        'Doreen Y. Gallegos'),
        ('Gallegos DM',     'David M. DM Gallegos'),
        ('Garcia H.',       'Harry H. Garcia'),
        ('Garcia MP',       'Miguel P. MP Garcia'),
        (N'Martínez J.',    N'Javier Martínez'),
        ('Pope, Jr.',       'Harold Pope'),
        ('Romero A.',       'Andrea A. Romero'),
        ('Romero GA',       N'G. Andrés GA Romero'),
        ('Stansbury',       'Melanie Stansbury'),
        ('Stapleton',       'Sheryl Williams Stapleton'),
        ('Trujillo C.',     'Christine Trujillo')
) AS V (SourceSponsorLabel, DisplayName)
JOIN CapitalOutlay.Sponsor AS S
    ON S.DisplayName = V.DisplayName
WHERE NOT EXISTS (
    SELECT 1
    FROM CapitalOutlay.SponsorAlias AS SA
    WHERE SA.SourceSponsorLabel = V.SourceSponsorLabel
);


/* ------------------------------------------------------------
   3. Apply verified aliases to unresolved 2021 appropriations
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID = SA.SponsorID
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.SponsorAlias AS SA
    ON AP.SourceSponsorLabel = SA.SourceSponsorLabel
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2021
  AND AP.SponsorID IS NULL
  AND SA.IsAutoResolvable = 1;


/* ------------------------------------------------------------
   4. Resolve ambiguous "Montoya" source labels

   The 2021 source uses "Montoya" for two different sponsors:

     Rod Montoya
       House District 1
       San Juan County

     Roger Montoya
       House District 40
       Colfax, Mora, Rio Arriba, and San Miguel Counties

   WebID 678 (New Mexico School for the Arts) was separately
   verified as Roger Montoya.

   Because "Montoya" represents more than one Sponsor, it must
   NOT be added as a global SponsorAlias.
   ------------------------------------------------------------ */

UPDATE AP
SET AP.SponsorID =
    CASE
        WHEN LP.County = 'San Juan'
            THEN Rod.SponsorID

        WHEN LP.County IN
            ('Colfax', 'Mora', 'Rio Arriba', 'San Miguel')
            THEN Roger.SponsorID

        WHEN LP.WebID = 678
            THEN Roger.SponsorID
    END
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
CROSS JOIN (
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = 'Rod RD Montoya'
) AS Rod
CROSS JOIN (
    SELECT SponsorID
    FROM CapitalOutlay.Sponsor
    WHERE DisplayName = 'Roger E. RE Montoya'
) AS Roger
WHERE LP.LegislativeYear = 2021
  AND AP.SourceSponsorLabel = 'Montoya'
  AND AP.SponsorID IS NULL
  AND (
        LP.County IN
            ('San Juan', 'Colfax', 'Mora', 'Rio Arriba', 'San Miguel')
        OR LP.WebID = 678
      );


/* ------------------------------------------------------------
   5. Verify no nonblank 2021 sponsor labels remain unresolved

   Expected result: 0 rows
   ------------------------------------------------------------ */

SELECT
    AP.SourceSponsorLabel,
    COUNT(*) AS UnresolvedCount
FROM CapitalOutlay.Appropriation AS AP
JOIN CapitalOutlay.LegislativeProject AS LP
    ON AP.LegislativeProjectID = LP.LegislativeProjectID
WHERE LP.LegislativeYear = 2021
  AND AP.SponsorID IS NULL
  AND AP.SourceSponsorLabel IS NOT NULL
GROUP BY AP.SourceSponsorLabel
ORDER BY AP.SourceSponsorLabel;