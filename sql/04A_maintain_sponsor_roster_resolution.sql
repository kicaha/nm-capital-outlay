/* ============================================================
   2023 SPONSOR ROSTER RESOLUTIONS
   ============================================================ */


/* Antonio Maestas
   Existing Sponsor changed from Representative District 16
   to Senator District 26.
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
    2023,
    'Antonio',
    'Maestas',
    NULL,
    'Senator',
    26,
    7,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 7; Representative District 16 through 2022 and Senator District 26 beginning in 2023.'
);


/* Miguel P. García
   Incoming roster spelling adds the accent to García.
   Existing canonical Sponsor uses Garcia.
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
    2023,
    'Miguel P.',
    N'García',
    'MP',
    'Representative',
    14,
    78,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 78; incoming 2023 roster uses García while existing canonical Sponsor uses Garcia.'
);


/* George K. Muñoz
   Incoming roster spelling adds the accent to Muñoz.
   Existing canonical Sponsor uses Munoz.
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
    2023,
    'George K.',
    N'Muñoz',
    NULL,
    'Senator',
    4,
    39,
    'Kim',
    CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 39; incoming 2023 roster uses Muñoz while existing canonical Sponsor uses Munoz.'
);