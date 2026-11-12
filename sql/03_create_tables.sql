/*
    Project: New Mexico Capital Outlay Analysis
    Script:  03_create_tables.sql
    Purpose: Create the normalized, staging, and holding data tables.
*/

-- Set the database to NMCapitalOutlay
USE NMCapitalOutlay;

/* ============================================================
   1. CREATE CAPITAL OUTLAY TABLES
   ============================================================ */

/*
This table contains the individual and institutional sponsors identified from the annual NMLegis.gov legislator lists.
Constraints include that the primary key is the SponsorID and that SponsorType must be one of the two identified values.
nvarchar is used for names so diacritics can be included - they are common in many NM names.
*/
CREATE TABLE CapitalOutlay.Sponsor (
    SponsorID   int IDENTITY(1,1) NOT NULL,
    GivenName nvarchar(100) NULL,
    LastName nvarchar(100) NULL,
    SponsorType varchar(20) NOT NULL,
    DisplayName nvarchar(200) NOT NULL,
    CONSTRAINT PK_CapitalOutlay_Sponsor
        PRIMARY KEY (SponsorID),
    CONSTRAINT CK_CapitalOutlay_SponsorType
        CHECK (SponsorType IN ('Person', 'Institutional'))
);

/*
    This table records annual observations of legislative and gubernatorial service.

    Legislator service is based on the annual published NMLegis roster. Governor
    service records are maintained separately because the Governor is not included
    in the legislator roster.

    NameInitial, StartYear, and PreferredEmail preserve selected roster attributes
    that may provide supporting evidence when resolving sponsor identity. StartYear
    does not determine whether a sponsor served in a particular year.

    ServiceID is the primary key. SponsorID is a foreign key to
    CapitalOutlay.Sponsor.
*/
CREATE TABLE CapitalOutlay.SponsorService (
    ServiceID int IDENTITY(1,1) NOT NULL,
    SponsorID int NOT NULL,
    ServiceYear smallint NOT NULL,
    OfficeType varchar(25) NOT NULL,
    Party varchar(25) NULL,
    District smallint NULL,
    NameInitial nvarchar(20) NULL,
    StartYear smallint NULL,
    PreferredEmail varchar(255) NULL,
    CONSTRAINT PK_CapitalOutlay_SponsorService
        PRIMARY KEY (ServiceID),
    CONSTRAINT FK_CapitalOutlay_SponsorService_Sponsor
        FOREIGN KEY (SponsorID)
            REFERENCES CapitalOutlay.Sponsor(SponsorID),
    CONSTRAINT CK_CapitalOutlay_SponsorService_OfficeType
        CHECK (OfficeType IN ('Senator', 'Representative', 'Governor')),
    CONSTRAINT CK_CapitalOutlay_SponsorService_District
        CHECK ((OfficeType = 'Governor' AND District IS NULL)
            OR (OfficeType IN ('Representative', 'Senator') AND District IS NOT NULL))
);

/*
This is a reference table of fund codes and their plain language names.
The FundName is NULL until an authoritative list of plain language names is identified.
Constraints include that the primary key is the FundID, and that duplication of a FundCode is not allowed.
*/
CREATE TABLE CapitalOutlay.Fund (
    FundID int IDENTITY(1,1) NOT NULL,
    FundCode varchar(10) NOT NULL,
    FundName nvarchar(100) NULL,
    CONSTRAINT PK_CapitalOutlay_Fund
        PRIMARY KEY (FundID),
    CONSTRAINT UQ_CapitalOutlay_Fund_FundCode
        UNIQUE (FundCode)
);

/*
This is a reference table of Agency codes and their plain language names.
The AgencyName is NULL until an authoritative list of plain language names is identified.
Constraints include that the primary key is the AgencyID, and that duplication of an AgencyCode is not allowed.
*/
CREATE TABLE CapitalOutlay.Agency (
    AgencyID int IDENTITY(1,1) NOT NULL,
    AgencyCode varchar(10) NOT NULL,
    AgencyName nvarchar(100) NULL,
    CONSTRAINT PK_CapitalOutlay_Agency
        PRIMARY KEY (AgencyID),
    CONSTRAINT UQ_CapitalOutlay_Agency_AgencyCode
        UNIQUE (AgencyCode)
);

/*
This table captures the individual capital projects and the information specific to them for each year.
Appropriations for these projects are not included here; instead, they are in the Appropriation table.

Constraints include that the primary key is the LegislativeProjectID, the unique business key is
(LegislativeYear, Bill, WebID) to account for repeating WebIDs across years and/or bills,
or the potential for multiple appropriation bills in a single legislative year. FundID is the foreign
key allowing the join to the Fund table, and AgencyID is the foreign key allowing the join to the Agency table.

ProjectTotalAfterVetoes was added to address what happens if a StatusFlag shows 'VETO' or 'LV'. When this happens,
the actual appropriation is reduced/zero, but the individual appropriations do not change. In these cases,
ProjectTotalAfterVetoes is not necessarily equal to SUM(Appropriation.Amount).
*/
CREATE TABLE CapitalOutlay.LegislativeProject (
    LegislativeProjectID int IDENTITY(1,1) NOT NULL,
    ProjectTitle nvarchar(255) NOT NULL,
    LegislativeYear smallint NOT NULL,
    Bill varchar(10) NOT NULL,
    WebID int NOT NULL,
    ChapterSection varchar(50) NULL,
    CityLocale nvarchar(50) NULL,
    County nvarchar(50) NULL,
    StatusFlag varchar(10) NULL,
    ProjectTotalAfterVetoes int NULL,
    FundID int NULL,
    AgencyID int NULL,
    CONSTRAINT PK_CapitalOutlay_LegislativeProject
        PRIMARY KEY (LegislativeProjectID),
    CONSTRAINT UQ_CapitalOutlay_LegislativeProject_BusinessKey
        UNIQUE (LegislativeYear, Bill, WebID),
    CONSTRAINT FK_CapitalOutlay_LegislativeProject_Fund
        FOREIGN KEY (FundID)
            REFERENCES CapitalOutlay.Fund(FundID),
    CONSTRAINT FK_CapitalOutlay_LegislativeProject_Agency
        FOREIGN KEY (AgencyID)
            REFERENCES CapitalOutlay.Agency(AgencyID)
);

/*
This table captures the individual appropriations for the projects in the LegislativeProject table.
SponsorID is allowed to be NULL because some source sponsor labels may require manual reconciliation
and may not uniquely identify a single Sponsor. A SponsorID should not be assigned until the identity
of the Sponsor has been confirmed.

SourceSponsorLabel preserves the sponsor label as it appears in the source Capital Appropriations
document and provides a starting point for researching unresolved SponsorIDs.

Constraints include the primary key of AppropriationID and foreign keys of LegislativeProjectID
and SponsorID.
*/
CREATE TABLE CapitalOutlay.Appropriation (
    AppropriationID int IDENTITY(1,1) NOT NULL,
    LegislativeProjectID int NOT NULL,
    SponsorID int NULL,
    SourceSponsorLabel nvarchar(100) NULL,
    Amount int NOT NULL,
    CONSTRAINT PK_CapitalOutlay_Appropriation
        PRIMARY KEY (AppropriationID),
    CONSTRAINT FK_CapitalOutlay_Appropriation_LegislativeProject
        FOREIGN KEY (LegislativeProjectID)
            REFERENCES CapitalOutlay.LegislativeProject(LegislativeProjectID),
    CONSTRAINT FK_CapitalOutlay_Appropriation_Sponsor
        FOREIGN KEY (SponsorID)
            REFERENCES CapitalOutlay.Sponsor(SponsorID)
);

/*
This table provides a way to map source Sponsor labels to resolved Sponsors, ensuring that
variations of a Sponsor's name can be associated with a single SponsorID.

This may include Sponsors with potentially ambiguous names (e.g. Baca), Sponsors whose names
change over time (Brantley --> Crystal Brantley), or variations in spelling
(Munoz --> Muñoz).

Aliases are only added to this table once the SponsorID associated with the source label has
been resolved.

IsAutoResolvable is a binary flag indicating whether the alias can be safely resolved by the
ETL process or whether an occurrence should be flagged for manual review. The default is 0
(manual review required).

SourceSponsorLabel is unique because each exact source label has only one current resolution.
If a resolution becomes questionable, IsAutoResolvable should be reset to 0 while the mapping
is reviewed.

The primary key is SponsorAliasID.
*/
CREATE TABLE CapitalOutlay.SponsorAlias (
    SponsorAliasID int IDENTITY(1,1) NOT NULL,
    SourceSponsorLabel nvarchar(100) NOT NULL,
    SponsorID int NOT NULL,
    IsAutoResolvable bit NOT NULL
        CONSTRAINT DF_CapitalOutlay_SponsorAlias_IsAutoResolvable DEFAULT 0,
    CONSTRAINT PK_CapitalOutlay_SponsorAlias
        PRIMARY KEY (SponsorAliasID),
    CONSTRAINT FK_CapitalOutlay_SponsorAlias_Sponsor
        FOREIGN KEY (SponsorID)
            REFERENCES CapitalOutlay.Sponsor(SponsorID),
    CONSTRAINT UQ_CapitalOutlay_SponsorAlias_SourceSponsorLabel
        UNIQUE(SourceSponsorLabel)
);

CREATE TABLE CapitalOutlay.SponsorRosterResolution (
    ResolutionID int IDENTITY(1,1) NOT NULL,
    ServiceYear smallint NOT NULL,
    GivenName nvarchar(100) NOT NULL,
    LastName nvarchar(100) NOT NULL,
    NameInitial nvarchar(20) NULL,
    OfficeType varchar(25) NOT NULL,
    District smallint NOT NULL,
    ApprovedSponsorID int NOT NULL,
    ApprovedBy nvarchar(100) NOT NULL,
    ApprovedDate date NOT NULL,
    ResolutionNote nvarchar(255) NOT NULL,
    CONSTRAINT PK_CapitalOutlay_SponsorRosterResolution
        PRIMARY KEY (ResolutionID),
    CONSTRAINT FK_CapitalOutlay_SponsorRosterResolution_Sponsor
        FOREIGN KEY (ApprovedSponsorID)
            REFERENCES CapitalOutlay.Sponsor(SponsorID),
    CONSTRAINT UK_CapitalOutlay_SponsorRosterResolution
        UNIQUE (ServiceYear, GivenName, LastName,NameInitial, OfficeType, District)
);

/* ============================================================
   2. CREATE STAGING TABLES
   ============================================================ */

/*
This table is an intermediate step for importing project information from the original source
into the normalized tables.

Staging.Project requires the business key attributes (LegislativeYear, Bill, WebID) and ProjectTitle
to be NOT NULL, but the remainder of the table is more permissive to accommodate the messy
nature of real-world data.

Duplicate business keys are permitted in Staging so that conflicting source records can be
preserved and evaluated. Duplicate business keys will be checked during data validation before
records are moved to the normalized tables.

SourcePage is retained to help locate problematic data in the original source during review
and is not carried forward to the normalized tables.

The primary key is StageProjectID.
*/
CREATE TABLE Staging.Project (
    StageProjectID int IDENTITY(1,1) NOT NULL,
    LegislativeYear smallint NOT NULL,
    Bill varchar(10) NOT NULL,
    WebID int NOT NULL,
    ProjectTitle nvarchar(255) NOT NULL,
    ChapterSection varchar(50) NULL,
    FundCode varchar(10) NULL,
    CityLocale nvarchar(50) NULL,
    County nvarchar(50) NULL,
    AgencyCode varchar(10) NULL,
    StatusFlag varchar(10) NULL,
    ProjectTotalAfterVetoes int NULL,
    SourcePage int NULL,
    CONSTRAINT PK_Staging_Project
        PRIMARY KEY (StageProjectID)
);

/*
This table is an intermediate step for importing project appropriations from the original source
into the normalized tables.

Staging.Appropriation requires the project business key (LegislativeYear, Bill, WebID), 
and Amount to be NOT NULL. Only SourcePage and Sponsor are allowed to be NULL in this table.

Sponsor preserves the sponsor label from the source data. Sponsor identity does not need to be
resolved before a record enters Staging; SponsorID resolution occurs when records are moved to
the normalized tables.

Multiple appropriation records for the same project and Sponsor are permitted in Staging so that
potential duplicate or conflicting source records can be preserved and evaluated. These records
will be checked during data validation before they are moved to the normalized tables.

SourcePage is retained to help locate problematic data in the original source during review and
is not carried forward to the normalized tables.

The primary key is StageAppropriationID.
*/
CREATE TABLE Staging.Appropriation (
    StageAppropriationID int IDENTITY(1,1) NOT NULL,
    LegislativeYear smallint NOT NULL,
    Bill varchar(10) NOT NULL,
    WebID int NOT NULL,
    Sponsor nvarchar(100) NULL,
    Amount int NOT NULL,
    SourcePage int NULL,
    CONSTRAINT PK_Staging_Appropriation
        PRIMARY KEY (StageAppropriationID)
);

/*
This is a holding table for projects that are ambiguous or fail validation. Projects can be moved here
from either the #Landing or Staging phases when they cannot safely proceed to the next ETL stage.

The reason a project is held is recorded in the ValidationIssue table.

Projects in this table will undergo validation again once they have been manually reviewed and resolved.

Primary key is HeldProjectID.
*/
CREATE TABLE Staging.HeldProject (
    HeldProjectID int IDENTITY(1,1) NOT NULL,
    HeldDate date NOT NULL
        CONSTRAINT DF_Staging_HeldProject_HeldDate DEFAULT GETDATE(),
    LegislativeYear nvarchar(50) NULL,
    Bill nvarchar(50) NULL,
    WebID nvarchar(50) NULL,
    ChapterSection nvarchar(50) NULL,
    FundCode nvarchar(50) NULL,
    AgencyCode nvarchar(50) NULL,
    StatusFlag nvarchar(50) NULL,
    ProjectTotalAfterVetoes nvarchar(50) NULL,
    SourcePage nvarchar(50) NULL,
    CityLocale nvarchar(250) NULL,
    County nvarchar(250) NULL,
    ProjectTitle nvarchar(500) NULL,
    CONSTRAINT PK_Staging_HeldProject
        PRIMARY KEY (HeldProjectID)
);

/*
This is a holding table for appropriations that are ambiguous or fail validation. Appropriations can be moved here
from either the #Landing or Staging phases when they cannot safely proceed to the next ETL stage.

The reason an appropriation is held is recorded in the ValidationIssue table.

Appropriations in this table will undergo validation again once they have been manually reviewed and resolved.

Primary key is HeldAppropriationID, HeldDate is auto-generated with the current date when a row is added.
*/
CREATE TABLE Staging.HeldAppropriation (
    HeldAppropriationID int IDENTITY(1,1) NOT NULL,
    HeldDate date NOT NULL
        CONSTRAINT DF_Staging_HeldAppropriation_HeldDate DEFAULT GETDATE(),
    LegislativeYear nvarchar(50) NULL,
    Bill nvarchar(50) NULL,
    WebID nvarchar(50) NULL,
    Amount nvarchar(50) NULL,
    SourcePage nvarchar(50) NULL,
    Sponsor nvarchar(250) NULL,
    CONSTRAINT  PK_Staging_HeldAppropriation
        PRIMARY KEY (HeldAppropriationID),
);

/*
This table stores the specific validation issues with records from an import as an active problem-management table.

Primary key is ValidationIssueID. Constraints include Foreign Key links to the two holding tables, and
the requirement that only one of the foreign keys be NOT NULL.
*/
CREATE TABLE Staging.ValidationIssue (
    ValidationIssueID int IDENTITY(1,1) NOT NULL,
    HeldProjectID int NULL,
    HeldAppropriationID int NULL,
    Issue nvarchar(250) NOT NULL,
    FieldName varchar(50) NULL,
    OriginalValue nvarchar(500) NULL,
    IsResolved bit NOT NULL
        CONSTRAINT DF_Staging_ValidationIssue_IsResolved DEFAULT 0,
    CONSTRAINT PK_Staging_ValidationIssue
        PRIMARY KEY (ValidationIssueID),
    CONSTRAINT FK_Staging_ValidationIssue_HeldProject
        FOREIGN KEY (HeldProjectID)
            REFERENCES Staging.HeldProject(HeldProjectID),
    CONSTRAINT FK_Staging_ValidationIssue_HeldAppropriation
        FOREIGN KEY (HeldAppropriationID)
            REFERENCES Staging.HeldAppropriation(HeldAppropriationID),
    CONSTRAINT CK_Staging_ValidationIssue_HeldRecord
        CHECK ((HeldProjectID IS NULL AND HeldAppropriationID IS NOT NULL) OR
            (HeldProjectID IS NOT NULL AND HeldAppropriationID IS NULL))
);
