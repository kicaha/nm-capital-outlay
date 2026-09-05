USE NMCapitalOutlay;
GO

IF SCHEMA_ID('Staging') IS NULL
BEGIN
    EXEC('CREATE SCHEMA Staging');
END;
GO

CREATE TABLE Staging.Project (
    StageProjectID int IDENTITY(1,1),
    LegislativeYear smallint,
    Bill varchar(10),
    WebID int,
    ChapterSection varchar(50),
    ProjectTitle nvarchar(255),
    FundCode varchar(10),
    CityLocale nvarchar(50),
    County nvarchar(50),
    AgencyCode varchar(10),
    StatusFlag varchar(10),
    ProjectTotalAfterVetoes int,
    SourcePage int,
    CONSTRAINT PK_Staging_Project
        PRIMARY KEY (StageProjectID)
);

CREATE TABLE Staging.Appropriation (
    StageAppropriationID int IDENTITY(1,1),
    LegislativeYear smallint,
    Bill varchar(10),
    WebID int,
    Sponsor nvarchar(100),
    Amount int,
    SourcePage int,
    CONSTRAINT PK_Staging_Appropriation
        PRIMARY KEY (StageAppropriationID)
);