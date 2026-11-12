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
VALUES
(
    2025, 'Candy Spence', 'Ezzell', NULL, 'Senator', 32,
    15, 'Kim', CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 15; Representative through 2024 and Senator beginning in 2025.'
),
(
    2025, 'Natalie', 'Figueroa', NULL, 'Senator', 18,
    81, 'Kim', CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 81; Representative through 2024 and Senator beginning in 2025.'
),
(
    2025, 'Joshua A.', 'Sanchez', NULL, 'Senator', 29,
    58, 'Kim', CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 58; continued Senate service in District 29 following the 2025 Senate district changes.'
),
(
    2025, 'Larry R.', 'Scott', NULL, 'Senator', 42,
    65, 'Kim', CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 65; Representative through 2024 and Senator beginning in 2025.'
),
(
    2025, 'James G.', 'Townsend', NULL, 'Senator', 34,
    49, 'Kim', CAST(GETDATE() AS date),
    'Verified as same person as existing SponsorID 49; Representative through 2024 and Senator beginning in 2025.'
);