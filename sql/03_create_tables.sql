USE NMCapitalOutlay;
GO

CREATE TABLE CIPReporting.Sponsor (
    SponsorID   int IDENTITY(1,1) NOT NULL,
    SponsorName nvarchar(100) NOT NULL,
    FirstName nvarchar(50) NULL,
    MiddleName nvarchar(50) NULL,
    LastName nvarchar(50) NULL,
    CONSTRAINT PK_CIPReporting_Sponsor
        PRIMARY KEY (SponsorID)
);

CREATE TABLE CIPReporting.LegislativeService (
    ServiceID int IDENTITY(1,1) NOT NULL,
    SponsorID int NOT NULL,
    StartYear smallint NOT NULL,
    EndYear smallint NULL,
    Chamber nvarchar(25) NULL,
    OfficeType nvarchar(25) NOT NULL,
    Party nvarchar(25) NOT NULL,
    District nvarchar(10) NULL,
    CONSTRAINT PK_CIPReporting_LegislativeService
        PRIMARY KEY (ServiceID),
    CONSTRAINT FK_CIPReporting_LegislativeService_Sponsor
        FOREIGN KEY (SponsorID)
            REFERENCES CIPReporting.Sponsor(SponsorID)
);

CREATE TABLE CIPReporting.Fund (
FundID int IDENTITY(1,1) NOT NULL,
FundCode varchar(10) NOT NULL,
FundName nvarchar(100) NULL,
CONSTRAINT PK_CIPReporting_Fund
    PRIMARY KEY (FundID),
CONSTRAINT UQ_CIPReporting_Fund_FundCode
    UNIQUE (FundCode)
);

CREATE TABLE CIPReporting.Agency (
    AgencyID int IDENTITY(1,1) NOT NULL,
    AgencyCode varchar(10) NOT NULL,
    AgencyName nvarchar(100) NULL,
    CONSTRAINT PK_CIPReporting_Agency
        PRIMARY KEY (AgencyID),
    CONSTRAINT UQ_CIPReporting_Agency_AgencyCode
        UNIQUE (AgencyCode)
);

CREATE TABLE CIPReporting.LegislativeProject (
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
    CONSTRAINT PK_CIPReporting_LegislativeProject
        PRIMARY KEY (LegislativeProjectID),
    CONSTRAINT UQ_CIPReporting_LegislativeProject_BusinessKey
        UNIQUE (LegislativeYear, Bill, WebID),
    CONSTRAINT FK_CIPReporting_LegislativeProject_Fund
        FOREIGN KEY (FundID)
            REFERENCES CIPReporting.Fund(FundID),
    CONSTRAINT FK_CIPReporting_LegislativeProject_Agency
        FOREIGN KEY (AgencyID)
            REFERENCES CIPReporting.Agency(AgencyID)
);

CREATE TABLE CIPReporting.Appropriation (
    LegislativeProjectID int NOT NULL,
    SponsorID int NOT NULL,
    Amount int NOT NULL,
    CONSTRAINT PK_CIPReporting_Appropriation
        PRIMARY KEY (LegislativeProjectID, SponsorID),
    CONSTRAINT FK_CIPReporting_Appropriation_LegislativeProject
        FOREIGN KEY (LegislativeProjectID)
            REFERENCES CIPReporting.LegislativeProject(LegislativeProjectID),
    CONSTRAINT FK_CIPReporting_Appropriation_Sponsor
        FOREIGN KEY (SponsorID)
            REFERENCES CIPReporting.Sponsor(SponsorID)
);