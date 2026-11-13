/* ============================================================
   2025 SPONSOR ROSTER RESOLUTIONS

   Annual remediation script for sponsor roster conflicts
   identified by 04_load_legislator.sql.

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

    /* House -> Senate transition */
    (
        2025,
        N'Candy Spence',
        N'Ezzell',
        NULL,
        N'Senator',
        32,
        15,
        N'Kim',
        N'Same sponsor; transitioned from Representative District 58 to Senator District 32 beginning in 2025.'
    ),

    /* House -> Senate transition */
    (
        2025,
        N'Natalie',
        N'Figueroa',
        NULL,
        N'Senator',
        18,
        81,
        N'Kim',
        N'Same sponsor; transitioned from Representative District 30 to Senator District 18 beginning in 2025.'
    ),

    /* Diacritic difference */
    (
        2025,
        N'Miguel P.',
        N'García',
        NULL,
        N'Representative',
        14,
        78,
        N'Kim',
        N'Same sponsor; incoming source uses accented García while canonical sponsor record uses Garcia.'
    ),

    /* Diacritic difference */
    (
        2025,
        N'Linda M.',
        N'López',
        NULL,
        N'Senator',
        11,
        68,
        N'Kim',
        N'Same sponsor; incoming source uses accented López while canonical sponsor record uses Lopez.'
    ),

    /* Diacritic difference */
    (
        2025,
        N'George K.',
        N'Muñoz',
        NULL,
        N'Senator',
        4,
        39,
        N'Kim',
        N'Same sponsor; incoming source uses accented Muñoz while canonical sponsor record uses Munoz.'
    ),

    /* Diacritic difference */
    (
        2025,
        N'Cristina',
        N'Parajón',
        NULL,
        N'Representative',
        25,
        183,
        N'Kim',
        N'Same sponsor; incoming source uses accented Parajón while canonical sponsor record uses Parajon.'
    ),

    /* Senate redistricting */
    (
        2025,
        N'Joshua A.',
        N'Sanchez',
        NULL,
        N'Senator',
        29,
        58,
        N'Kim',
        N'Same sponsor; Senate district changed from District 30 to District 29 beginning in 2025.'
    ),

    /* House -> Senate transition */
    (
        2025,
        N'Larry R.',
        N'Scott',
        NULL,
        N'Senator',
        42,
        65,
        N'Kim',
        N'Same sponsor; transitioned from Representative District 62 to Senator District 42 beginning in 2025.'
    ),

    /* House -> Senate transition */
    (
        2025,
        N'James G.',
        N'Townsend',
        NULL,
        N'Senator',
        34,
        49,
        N'Kim',
        N'Same sponsor; transitioned from Representative District 54 to Senator District 34 beginning in 2025.'
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
      AND R.GivenName = V.GivenName
      AND R.LastName = V.LastName
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
    2025,
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