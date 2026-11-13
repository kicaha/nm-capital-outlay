/* ============================================================
   2026 SPONSOR ROSTER RESOLUTIONS

   Annual remediation script for sponsor roster conflicts
   identified by 04_load_legislator_roster.sql.

   Replace the prior year's contents when beginning a new
   legislative-year load. Historical resolutions are retained
   in CapitalOutlay.SponsorRosterResolution.
   ============================================================ */

INSERT INTO CapitalOutlay.SponsorRosterResolution
(
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
    V.ServiceYear,
    V.GivenName,
    V.LastName,
    V.NameInitial,
    V.OfficeType,
    V.District,
    V.ApprovedSponsorID,
    V.ApprovedBy,
    CAST(GETDATE() AS date),
    V.ResolutionNote
FROM
(
    VALUES
        (
            2026,
            N'Miguel P.',
            N'García',
            NULL,
            N'Representative',
            14,
            78,
            N'Kim',
            N'Same sponsor; incoming source uses accented García while canonical sponsor record uses Garcia.'
        ),
        (
            2026,
            N'Linda M.',
            N'López',
            NULL,
            N'Senator',
            11,
            68,
            N'Kim',
            N'Same sponsor; incoming source uses accented López while canonical sponsor record uses Lopez.'
        ),
        (
            2026,
            N'George K.',
            N'Muñoz',
            NULL,
            N'Senator',
            4,
            39,
            N'Kim',
            N'Same sponsor; incoming source uses accented Muñoz while canonical sponsor record uses Munoz.'
        ),
        (
            2026,
            N'Cristina',
            N'Parajón',
            NULL,
            N'Representative',
            25,
            183,
            N'Kim',
            N'Same sponsor; incoming source uses accented Parajón while canonical sponsor record uses Parajon.'
        )
) AS V
(
    ServiceYear,
    GivenName,
    LastName,
    NameInitial,
    OfficeType,
    District,
    ApprovedSponsorID,
    ApprovedBy,
    ResolutionNote
)
WHERE NOT EXISTS
(
    SELECT 1
    FROM CapitalOutlay.SponsorRosterResolution AS R
    WHERE R.ServiceYear = V.ServiceYear
      AND R.GivenName COLLATE Latin1_General_100_CI_AI
          = V.GivenName COLLATE Latin1_General_100_CI_AI
      AND R.LastName COLLATE Latin1_General_100_CI_AI
          = V.LastName COLLATE Latin1_General_100_CI_AI
      AND ISNULL(R.NameInitial, N'') = ISNULL(V.NameInitial, N'')
      AND R.OfficeType = V.OfficeType
      AND R.District = V.District
);

INSERT INTO CapitalOutlay.SponsorRosterResolution
(
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
VALUES
(
    2026,
    N'Miguel P.',
    N'Garcia',
    N'MP',
    N'Representative',
    14,
    78,
    N'Kim',
    CAST(GETDATE() AS date),
    N'Same sponsor; incoming source includes NameInitial MP as a separate identity value.'
);