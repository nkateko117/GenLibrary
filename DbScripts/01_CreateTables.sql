CREATE DATABASE netgen_library;

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

use netgen_library
Go

-- ========== Identity-like tables (custom) ==========
-- Users table (compatible with IdentityUser properties)
CREATE TABLE AppUsers (
    Id UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_AspNetUsers_Id DEFAULT NEWSEQUENTIALID(),
    UserName NVARCHAR(256) NULL,
    NormalizedUserName NVARCHAR(256) NULL,
    Email NVARCHAR(256) NULL,
    NormalizedEmail NVARCHAR(256) NULL,
    EmailConfirmed BIT NOT NULL DEFAULT 0,
    PasswordHash NVARCHAR(MAX) NULL,
    SecurityStamp NVARCHAR(MAX) NULL,
    ConcurrencyStamp NVARCHAR(MAX) NULL,
    PhoneNumber NVARCHAR(50) NULL,
    PhoneNumberConfirmed BIT NOT NULL DEFAULT 0,
    TwoFactorEnabled BIT NOT NULL DEFAULT 0,
    LockoutEnd DATETIMEOFFSET NULL,
    LockoutEnabled BIT NOT NULL DEFAULT 0,
    AccessFailedCount INT NOT NULL DEFAULT 0,
    FullName NVARCHAR(200) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (Id)
);
CREATE UNIQUE INDEX UX_AppUsers_NormalizedUserName ON AppUsers (NormalizedUserName) WHERE NormalizedUserName IS NOT NULL;
CREATE UNIQUE INDEX UX_AppUsers_NormalizedEmail ON AppUsers (NormalizedEmail) WHERE NormalizedEmail IS NOT NULL;

-- Roles table
CREATE TABLE AppRoles (
    Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
    Name NVARCHAR(256) NULL,
    NormalizedName NVARCHAR(256) NULL,
    ConcurrencyStamp NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE UNIQUE INDEX UX_AppRoles_NormalizedName ON AppRoles (NormalizedName) WHERE NormalizedName IS NOT NULL;

-- UserRoles (many-to-many)
CREATE TABLE AppUserRoles (
    UserId UNIQUEIDENTIFIER NOT NULL,
    RoleId UNIQUEIDENTIFIER NOT NULL,
    AssignedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (UserId, RoleId),
    CONSTRAINT FK_AppUserRoles_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id),
    CONSTRAINT FK_AppUserRoles_Role FOREIGN KEY (RoleId) REFERENCES AppRoles(Id)
);

-- UserClaims
CREATE TABLE AppUserClaims (
    Id INT IDENTITY PRIMARY KEY,
    UserId UNIQUEIDENTIFIER NOT NULL,
    ClaimType NVARCHAR(256) NULL,
    ClaimValue NVARCHAR(MAX) NULL,
    CONSTRAINT FK_AppUserClaims_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
);

-- RoleClaims
CREATE TABLE AppRoleClaims (
    Id INT IDENTITY PRIMARY KEY,
    RoleId UNIQUEIDENTIFIER NOT NULL,
    ClaimType NVARCHAR(256) NULL,
    ClaimValue NVARCHAR(MAX) NULL,
    CONSTRAINT FK_AppRoleClaims_Role FOREIGN KEY (RoleId) REFERENCES AppRoles(Id)
);

-- UserLogins (external login providers - optional but included)
CREATE TABLE AppUserLogins (
    LoginProvider NVARCHAR(128) NOT NULL,
    ProviderKey NVARCHAR(256) NOT NULL,
    ProviderDisplayName NVARCHAR(256) NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    PRIMARY KEY (LoginProvider, ProviderKey),
    CONSTRAINT FK_AppUserLogins_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
);

-- UserTokens (optional)
CREATE TABLE AppUserTokens (
    UserId UNIQUEIDENTIFIER NOT NULL,
    LoginProvider NVARCHAR(128) NOT NULL,
    Name NVARCHAR(128) NOT NULL,
    Value NVARCHAR(MAX) NULL,
    PRIMARY KEY (UserId, LoginProvider, Name),
    CONSTRAINT FK_AppUserTokens_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
);

-- ========== Library tables ==========
CREATE TABLE Authors (
    AuthorId INT IDENTITY PRIMARY KEY,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NULL,
    Bio NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
    Active BIT NOT NULL DEFAULT 0,
);

CREATE TABLE Books (
    BookId INT IDENTITY PRIMARY KEY,
    Title NVARCHAR(250) NOT NULL,
    ISBN NVARCHAR(20) NULL,
    Summary NVARCHAR(MAX) NULL,
    PublishedYear INT NULL,
    TotalPages INT NULL,
    CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
    Active BIT NOT NULL DEFAULT 0,
    Picture NVARCHAR(MAX)
);

CREATE TABLE BookAuthors (
    BookId INT NOT NULL,
    AuthorId INT NOT NULL,
    PRIMARY KEY (BookId, AuthorId),
    CONSTRAINT FK_BookAuthors_Book FOREIGN KEY (BookId) REFERENCES Books(BookId),
    CONSTRAINT FK_BookAuthors_Author FOREIGN KEY (AuthorId) REFERENCES Authors(AuthorId)
);

CREATE TABLE BookCopies (
    CopyId INT IDENTITY PRIMARY KEY,
    BookId INT NOT NULL,
    Barcode NVARCHAR(50) NULL,
    AcquisitionDate DATETIME2 NULL,
    Condition NVARCHAR(50) DEFAULT 'Good',
    Status TINYINT NOT NULL DEFAULT 0, -- 0=Available,1=CheckedOut,2=Lost,3=Maintenance
    CONSTRAINT FK_BookCopies_Book FOREIGN KEY (BookId) REFERENCES Books(BookId)
);

CREATE TABLE Checkouts (
    CheckoutId INT IDENTITY PRIMARY KEY,
    CopyId INT NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    CheckoutDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    DueDate DATETIME2 NOT NULL,
    ReturnDate DATETIME2 NULL,
    IsMarkedReturned BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_Checkouts_Copy FOREIGN KEY (CopyId) REFERENCES BookCopies(CopyId),
    CONSTRAINT FK_Checkouts_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
);

-- Helpful indexes
CREATE INDEX IX_Books_Title ON Books(Title);
CREATE INDEX IX_Authors_LastName ON Authors(LastName);
CREATE INDEX IX_BookCopies_BookId ON BookCopies(BookId);
CREATE INDEX IX_Checkouts_UserId ON Checkouts(UserId);
CREATE INDEX IX_Checkouts_CopyId ON Checkouts(CopyId);
CREATE INDEX IX_Checkouts_DueDate ON Checkouts(DueDate);
GO
