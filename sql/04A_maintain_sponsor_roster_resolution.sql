/* ============================================================
   2024 SPONSOR ROSTER RESOLUTIONS

   Annual remediation script for sponsor roster conflicts
   identified by 04_load_legislator.sql.

   Replace the prior year's contents when beginning a new
   legislative-year load. Historical resolutions are retained
   in CapitalOutlay.SponsorRosterResolution.
   ============================================================ */

/* Miguel P. García
   Incoming roster spelling uses the accent in García.
   Existing canonical Sponsor uses Garcia.
   Existing service history confirms Representative District 14.
*/

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
VALUES (
    2024,
    'Miguel P.',
    N'García',
    'MP',
    'Representative',
    14,
    78,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 78; Representative District 14 in 2021-2023 and incoming 2024 roster uses García while canonical Sponsor uses Garcia.'
);

/* Linda M. López
   Incoming roster spelling uses the accent in López.
   Existing canonical Sponsor uses Lopez.
   Existing service history confirms Senator District 11.
*/

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
VALUES (
    2024,
    'Linda M.',
    N'López',
    NULL,
    'Senator',
    11,
    68,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 68; Senator District 11 in 2021-2023 and incoming 2024 roster uses López while canonical Sponsor uses Lopez.'
);

/* George K. Muñoz
   Incoming roster spelling uses the accent in Muñoz.
   Existing canonical Sponsor uses Munoz.
   Existing service history confirms Senator District 4.
*/

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
VALUES (
    2024,
    'George K.',
    N'Muñoz',
    NULL,
    'Senator',
    4,
    39,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 39; Senator District 4 in 2021-2023 and incoming 2024 roster uses Muñoz while canonical Sponsor uses Munoz.'
);

/* Greg Nibert
   Existing Sponsor changed from Representative District 59
   to Senator District 27.
*/

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
VALUES (
    2024,
    'Greg',
    'Nibert',
    NULL,
    'Senator',
    27,
    42,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 42; Representative District 59 through 2023 and Senator District 27 beginning in 2024.'
);

/* Cristina Parajón
   Incoming roster spelling uses the accent in Parajón.
   Existing canonical Sponsor uses Parajon.
   Existing service history confirms Representative District 25.
*/

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
VALUES (
    2024,
    'Cristina',
    N'Parajón',
    NULL,
    'Representative',
    25,
    183,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 183; Representative District 25 in 2023 and incoming 2024 roster uses Parajón while canonical Sponsor uses Parajon.'
);