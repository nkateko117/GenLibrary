-- =============================================================================
-- GenLibrary Consolidated Database Setup Script
-- =============================================================================
-- This script consolidates all database setup into a single file.
-- Run sections in order: Database -> Tables -> Identity Procs -> Library Procs -> Seed Data
-- =============================================================================

-- =============================================================================
-- SECTION 1: DATABASE CREATION
-- =============================================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'netgen_library')
BEGIN
    CREATE DATABASE netgen_library;
END
GO

USE netgen_library;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================================================
-- SECTION 2: IDENTITY TABLES (Custom ASP.NET Identity)
-- =============================================================================

-- Users table (compatible with IdentityUser properties)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppUsers')
BEGIN
    CREATE TABLE AppUsers (
        Id UNIQUEIDENTIFIER NOT NULL 
            CONSTRAINT DF_AppUsers_Id DEFAULT NEWSEQUENTIALID(),
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
END
GO

-- Roles table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppRoles')
BEGIN
    CREATE TABLE AppRoles (
        Id UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWSEQUENTIALID(),
        Name NVARCHAR(256) NULL,
        NormalizedName NVARCHAR(256) NULL,
        ConcurrencyStamp NVARCHAR(MAX) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE UNIQUE INDEX UX_AppRoles_NormalizedName ON AppRoles (NormalizedName) WHERE NormalizedName IS NOT NULL;
END
GO

-- UserRoles (many-to-many)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppUserRoles')
BEGIN
    CREATE TABLE AppUserRoles (
        UserId UNIQUEIDENTIFIER NOT NULL,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        AssignedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        PRIMARY KEY (UserId, RoleId),
        CONSTRAINT FK_AppUserRoles_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id),
        CONSTRAINT FK_AppUserRoles_Role FOREIGN KEY (RoleId) REFERENCES AppRoles(Id)
    );
END
GO

-- UserClaims
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppUserClaims')
BEGIN
    CREATE TABLE AppUserClaims (
        Id INT IDENTITY PRIMARY KEY,
        UserId UNIQUEIDENTIFIER NOT NULL,
        ClaimType NVARCHAR(256) NULL,
        ClaimValue NVARCHAR(MAX) NULL,
        CONSTRAINT FK_AppUserClaims_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
    );
END
GO

-- RoleClaims
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppRoleClaims')
BEGIN
    CREATE TABLE AppRoleClaims (
        Id INT IDENTITY PRIMARY KEY,
        RoleId UNIQUEIDENTIFIER NOT NULL,
        ClaimType NVARCHAR(256) NULL,
        ClaimValue NVARCHAR(MAX) NULL,
        CONSTRAINT FK_AppRoleClaims_Role FOREIGN KEY (RoleId) REFERENCES AppRoles(Id)
    );
END
GO

-- UserLogins (external login providers)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppUserLogins')
BEGIN
    CREATE TABLE AppUserLogins (
        LoginProvider NVARCHAR(128) NOT NULL,
        ProviderKey NVARCHAR(256) NOT NULL,
        ProviderDisplayName NVARCHAR(256) NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        PRIMARY KEY (LoginProvider, ProviderKey),
        CONSTRAINT FK_AppUserLogins_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
    );
END
GO

-- UserTokens
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AppUserTokens')
BEGIN
    CREATE TABLE AppUserTokens (
        UserId UNIQUEIDENTIFIER NOT NULL,
        LoginProvider NVARCHAR(128) NOT NULL,
        Name NVARCHAR(128) NOT NULL,
        Value NVARCHAR(MAX) NULL,
        PRIMARY KEY (UserId, LoginProvider, Name),
        CONSTRAINT FK_AppUserTokens_User FOREIGN KEY (UserId) REFERENCES AppUsers(Id)
    );
END
GO

-- =============================================================================
-- SECTION 3: LIBRARY TABLES
-- =============================================================================

-- Authors
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Authors')
BEGIN
    CREATE TABLE Authors (
        AuthorId INT IDENTITY PRIMARY KEY,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NULL,
        Bio NVARCHAR(MAX) NULL,
        CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
        Active BIT NOT NULL DEFAULT 1
    );
END
GO

-- Books
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Books')
BEGIN
    CREATE TABLE Books (
        BookId INT IDENTITY PRIMARY KEY,
        Title NVARCHAR(250) NOT NULL,
        ISBN NVARCHAR(20) NULL,
        Summary NVARCHAR(MAX) NULL,
        PublishedYear INT NULL,
        TotalPages INT NULL,
        CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME(),
        Active BIT NOT NULL DEFAULT 1,
        Picture NVARCHAR(MAX) NULL
    );
END
GO

-- BookAuthors (many-to-many)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookAuthors')
BEGIN
    CREATE TABLE BookAuthors (
        BookId INT NOT NULL,
        AuthorId INT NOT NULL,
        PRIMARY KEY (BookId, AuthorId),
        CONSTRAINT FK_BookAuthors_Book FOREIGN KEY (BookId) REFERENCES Books(BookId),
        CONSTRAINT FK_BookAuthors_Author FOREIGN KEY (AuthorId) REFERENCES Authors(AuthorId)
    );
END
GO

-- BookCopies
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookCopies')
BEGIN
    CREATE TABLE BookCopies (
        CopyId INT IDENTITY PRIMARY KEY,
        BookId INT NOT NULL,
        Barcode NVARCHAR(50) NULL,
        AcquisitionDate DATETIME2 NULL,
        Condition NVARCHAR(50) DEFAULT 'Good',
        Status TINYINT NOT NULL DEFAULT 1, -- 0=CheckedOut, 1=Available, 2=Lost, 3=Maintenance
        CONSTRAINT FK_BookCopies_Book FOREIGN KEY (BookId) REFERENCES Books(BookId)
    );
END
GO

-- Checkouts
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Checkouts')
BEGIN
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
END
GO

-- =============================================================================
-- SECTION 4: INDEXES
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Books_Title')
    CREATE INDEX IX_Books_Title ON Books(Title);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Authors_LastName')
    CREATE INDEX IX_Authors_LastName ON Authors(LastName);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BookCopies_BookId')
    CREATE INDEX IX_BookCopies_BookId ON BookCopies(BookId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkouts_UserId')
    CREATE INDEX IX_Checkouts_UserId ON Checkouts(UserId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkouts_CopyId')
    CREATE INDEX IX_Checkouts_CopyId ON Checkouts(CopyId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkouts_DueDate')
    CREATE INDEX IX_Checkouts_DueDate ON Checkouts(DueDate);
GO

-- =============================================================================
-- SECTION 5: IDENTITY STORED PROCEDURES
-- =============================================================================

-- Create a user
CREATE OR ALTER PROCEDURE PROC_ID_CreateUser
    @UserName NVARCHAR(256),
    @NormalizedUserName NVARCHAR(256),
    @Email NVARCHAR(256),
    @NormalizedEmail NVARCHAR(256),
    @PasswordHash NVARCHAR(MAX),
    @FullName NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @NormalizedUserName IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM AppUsers WHERE NormalizedUserName = @NormalizedUserName)
        BEGIN
            RAISERROR('Username already exists',16,1);
            RETURN -1;
        END
    END

    INSERT INTO AppUsers (UserName, NormalizedUserName, Email, NormalizedEmail, PasswordHash, FullName, SecurityStamp, ConcurrencyStamp)
    VALUES (@UserName, @NormalizedUserName, @Email, @NormalizedEmail, @PasswordHash, @FullName, NEWID(), NEWID());

    SELECT Id FROM AppUsers WHERE NormalizedUserName = @NormalizedUserName;
    RETURN 0;
END
GO

-- Get user by normalized username
CREATE OR ALTER PROCEDURE PROC_ID_GetUserByNormalizedUserName
    @NormalizedUserName NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed,
        PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumber, PhoneNumberConfirmed,
        TwoFactorEnabled, LockoutEnd, LockoutEnabled, AccessFailedCount, FullName, CreatedAt
    FROM AppUsers
    WHERE NormalizedUserName = @NormalizedUserName;
END
GO

-- Get user by Id
CREATE OR ALTER PROCEDURE PROC_ID_GetUserById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed,
        PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumber, PhoneNumberConfirmed,
        TwoFactorEnabled, LockoutEnd, LockoutEnabled, AccessFailedCount, FullName, CreatedAt
    FROM AppUsers
    WHERE Id = @Id;
END
GO

-- Get user by normalized email
CREATE OR ALTER PROCEDURE PROC_ID_GetUserByNormalizedEmail
    @NormalizedEmail NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 Id, UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, PasswordHash, FullName
    FROM AppUsers
    WHERE NormalizedEmail = @NormalizedEmail;
END
GO

-- Update user
CREATE OR ALTER PROCEDURE PROC_ID_UpdateUser
    @Id UNIQUEIDENTIFIER,
    @UserName NVARCHAR(256),
    @NormalizedUserName NVARCHAR(256),
    @Email NVARCHAR(256),
    @NormalizedEmail NVARCHAR(256),
    @PasswordHash NVARCHAR(MAX),
    @FullName NVARCHAR(200),
    @ConcurrencyStamp NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE AppUsers
    SET UserName = @UserName,
        NormalizedUserName = @NormalizedUserName,
        Email = @Email,
        NormalizedEmail = @NormalizedEmail,
        PasswordHash = @PasswordHash,
        FullName = @FullName,
        ConcurrencyStamp = @ConcurrencyStamp
    WHERE Id = @Id;
    RETURN 0;
END
GO

-- Delete user
CREATE OR ALTER PROCEDURE PROC_ID_DeleteUser
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM AppUserRoles WHERE UserId = @Id;
    DELETE FROM AppUserClaims WHERE UserId = @Id;
    DELETE FROM AppUserLogins WHERE UserId = @Id;
    DELETE FROM AppUserTokens WHERE UserId = @Id;
    DELETE FROM AppUsers WHERE Id = @Id;
END
GO

-- Set password hash for user
CREATE OR ALTER PROCEDURE PROC_ID_SetPasswordHash
    @UserId UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE AppUsers SET PasswordHash = @PasswordHash WHERE Id = @UserId;
END
GO

-- Create a role
CREATE OR ALTER PROCEDURE PROC_ID_CreateRole
    @Id UNIQUEIDENTIFIER OUTPUT,
    @Name NVARCHAR(256),
    @NormalizedName NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM AppRoles WHERE NormalizedName = @NormalizedName)
    BEGIN
        RAISERROR('Role already exists',16,1);
        RETURN -1;
    END
    INSERT INTO AppRoles (Name, NormalizedName, ConcurrencyStamp)
    VALUES (@Name, @NormalizedName, NEWID());
    SELECT @Id = Id FROM AppRoles WHERE NormalizedName = @NormalizedName;
    RETURN 0;
END
GO

-- Get role by normalized name
CREATE OR ALTER PROCEDURE PROC_ID_GetRoleByNormalizedName
    @NormalizedName NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 Id, Name, NormalizedName, ConcurrencyStamp, CreatedAt FROM AppRoles WHERE NormalizedName = @NormalizedName;
END
GO

-- Get role by Id
CREATE OR ALTER PROCEDURE PROC_ID_GetRoleById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 Id, Name, NormalizedName, ConcurrencyStamp FROM AppRoles WHERE Id = @Id;
END
GO

-- Add user to role
CREATE OR ALTER PROCEDURE PROC_ID_AddUserToRole
    @UserId UNIQUEIDENTIFIER,
    @RoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM AppUserRoles WHERE UserId = @UserId AND RoleId = @RoleId)
    BEGIN
        INSERT INTO AppUserRoles (UserId, RoleId) VALUES (@UserId, @RoleId);
    END
END
GO

-- Remove user from role
CREATE OR ALTER PROCEDURE PROC_ID_RemoveUserFromRole
    @UserId UNIQUEIDENTIFIER,
    @RoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM AppUserRoles WHERE UserId = @UserId AND RoleId = @RoleId;
END
GO

-- Get roles for a user
CREATE OR ALTER PROCEDURE PROC_ID_GetRolesForUser
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.Id, r.Name, r.NormalizedName
    FROM AppRoles r
    JOIN AppUserRoles ur ON ur.RoleId = r.Id
    WHERE ur.UserId = @UserId;
END
GO

-- =============================================================================
-- SECTION 6: LIBRARY VIEWS
-- =============================================================================

-- DetailedBooks View
CREATE OR ALTER VIEW dbo.DetailedBooks
AS
SELECT 
    b.BookId,
    b.Title,
    b.ISBN,
    b.Summary,
    b.PublishedYear,
    b.TotalPages,
    b.CreatedAt,
    b.Active,
    STRING_AGG(a.FirstName + ' ' + a.LastName, ', ') AS Authors,
    COUNT(bc.CopyId) AS TotalCopies,
    COUNT(CASE WHEN bc.Status = 1 THEN 1 END) AS AvailableCopies
FROM dbo.Books b
LEFT JOIN dbo.BookAuthors ba ON ba.BookId = b.BookId
LEFT JOIN dbo.Authors a ON a.AuthorId = ba.AuthorId
LEFT JOIN dbo.BookCopies bc ON bc.BookId = b.BookId
GROUP BY 
    b.BookId,
    b.Title,
    b.ISBN,
    b.Summary,
    b.PublishedYear,
    b.TotalPages,
    b.CreatedAt,
    b.Active;
GO

-- BookCopyDetailed View
CREATE OR ALTER VIEW dbo.BookCopyDetailed
AS
SELECT 
    bc.CopyId,
    bc.BookId,
    bc.Barcode,
    bc.AcquisitionDate,
    bc.[Condition],
    bc.[Status],
    b.Title,
    c.CheckoutDate,
    c.DueDate,
    c.IsMarkedReturned,
    u.Id AS UserId,
    u.FullName AS MemberFullName,
    CASE 
        WHEN bc.[Status] = 1 THEN 'Available'
        WHEN bc.[Status] = 0 THEN 'Checked Out'
        WHEN bc.[Status] = 3 THEN 'Out of Commission'
        ELSE 'Unknown'
    END AS StatusName,
    CASE 
        WHEN c.DueDate IS NULL THEN NULL
        ELSE 
            CASE 
                WHEN DATEDIFF(DAY, GETDATE(), c.DueDate) < 0 THEN 0
                ELSE DATEDIFF(DAY, GETDATE(), c.DueDate)
            END
    END AS DaysLeft
FROM dbo.BookCopies bc
INNER JOIN dbo.Books b ON b.BookId = bc.BookId
OUTER APPLY (
    SELECT TOP 1 c_inner.*, u_inner.Id, u_inner.FullName
    FROM dbo.Checkouts c_inner
    INNER JOIN dbo.AppUsers u_inner ON c_inner.UserId = u_inner.Id
    WHERE c_inner.CopyId = bc.CopyId
      AND c_inner.ReturnDate IS NULL
      AND c_inner.IsMarkedReturned = 0
    ORDER BY c_inner.CheckoutDate DESC
) c
LEFT JOIN dbo.AppUsers u ON c.UserId = u.Id;
GO

-- =============================================================================
-- SECTION 7: LIBRARY STORED PROCEDURES
-- =============================================================================

-- Get All Authors
CREATE OR ALTER PROCEDURE [dbo].[PROC_Authors_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT AuthorId, FirstName, LastName, Bio, CreatedAt, Active
    FROM dbo.Authors;
END
GO

-- Get All BookAuthors
CREATE OR ALTER PROCEDURE [dbo].[PROC_BookAuthors_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BookId, AuthorId
    FROM dbo.BookAuthors;
END
GO

-- Get All BookCopies
CREATE OR ALTER PROCEDURE [dbo].[PROC_BookCopies_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CopyId, BookId, Barcode, AcquisitionDate, Condition, Status
    FROM dbo.BookCopies;
END
GO

-- Get All Books
CREATE OR ALTER PROCEDURE [dbo].[PROC_Books_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BookId, Title, ISBN, Summary, PublishedYear, TotalPages, CreatedAt, Active, Picture
    FROM dbo.Books;
END
GO

-- Get All Checkouts
CREATE OR ALTER PROCEDURE [dbo].[PROC_Checkouts_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CheckoutId, CopyId, UserId, CheckoutDate, DueDate, ReturnDate, IsMarkedReturned
    FROM dbo.Checkouts;
END
GO

-- Get Detailed Books
CREATE OR ALTER PROCEDURE dbo.PROC_GetDetailedBooks
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.DetailedBooks ORDER BY Title;
END
GO

-- Get Single Book by ID
CREATE OR ALTER PROCEDURE [dbo].[PROC_GetDetailedBook_ById]
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.DetailedBooks WHERE BookId = @BookId;
END
GO

-- Get Book Copies
CREATE OR ALTER PROCEDURE dbo.PROC_GetBookCopies
    @BookId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        CopyId, BookId, Barcode, AcquisitionDate, [Condition], [Status],
        Title, CheckoutDate, DueDate, IsMarkedReturned, UserId, MemberFullName,
        StatusName, DaysLeft
    FROM dbo.BookCopyDetailed
    WHERE (@BookId IS NULL OR BookId = @BookId)
    ORDER BY CopyId ASC;
END
GO

-- Get Available Copies for checkout
CREATE OR ALTER PROCEDURE PROC_GetAvailableCopies
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT bc.CopyId, bc.BookId, bc.Barcode, bc.Condition, b.Title
    FROM BookCopies bc
    INNER JOIN Books b ON bc.BookId = b.BookId
    WHERE bc.BookId = @BookId AND bc.Status = 1
    ORDER BY bc.Barcode;
END
GO

-- Update BookCopy
CREATE OR ALTER PROCEDURE [dbo].[PROC_BookCopy_Update]
    @CopyId INT,
    @Condition NVARCHAR(50),
    @Status INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.BookCopies
    SET Condition = @Condition, [Status] = @Status
    WHERE CopyId = @CopyId;
END
GO

-- Return Book
CREATE OR ALTER PROCEDURE [dbo].[PROC_Checkout_ReturnBook]
    @CopyId INT,
    @Condition NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.Checkouts
        SET ReturnDate = GETDATE(), IsMarkedReturned = 1
        WHERE CopyId = @CopyId AND ReturnDate IS NULL;

        DECLARE @checkoutRows INT = @@ROWCOUNT;
        IF @checkoutRows = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS Result;
            RETURN;
        END

        UPDATE dbo.BookCopies
        SET Condition = @Condition, [Status] = 1
        WHERE CopyId = @CopyId;

        DECLARE @copyRows INT = @@ROWCOUNT;
        IF @copyRows = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS Result;
            RETURN;
        END

        COMMIT TRANSACTION;
        SELECT 1 AS Result;

    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
        SELECT 0 AS Result;
    END CATCH
END
GO

-- Checkout Book
CREATE OR ALTER PROCEDURE [dbo].[PROC_Checkout_CheckoutBook]
    @CopyId INT,
    @UserId UNIQUEIDENTIFIER,
    @DueDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate member checkout limit (max 5 active)
        DECLARE @ActiveCount INT;
        SELECT @ActiveCount = COUNT(*)
        FROM dbo.Checkouts
        WHERE UserId = @UserId AND ReturnDate IS NULL;

        IF @ActiveCount >= 5
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT -1 AS Result; -- -1 = limit reached
            RETURN;
        END

        -- Ensure copy is available (Status = 1)
        DECLARE @IsAvailable INT;
        SELECT @IsAvailable = COUNT(*)
        FROM dbo.BookCopies
        WHERE CopyId = @CopyId AND Status = 1;

        IF @IsAvailable = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT -2 AS Result; -- -2 = copy not available
            RETURN;
        END

        INSERT INTO dbo.Checkouts (CopyId, UserId, CheckoutDate, DueDate, IsMarkedReturned)
        VALUES (@CopyId, @UserId, GETDATE(), @DueDate, 0);

        UPDATE dbo.BookCopies SET Status = 0 WHERE CopyId = @CopyId AND Status = 1;

        DECLARE @copyRows INT = @@ROWCOUNT;
        IF @copyRows = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT -2 AS Result;
            RETURN;
        END

        COMMIT TRANSACTION;
        SELECT 1 AS Result;

    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
        SELECT 0 AS Result;
    END CATCH
END
GO

-- Get current checkout count for a member
CREATE OR ALTER PROCEDURE PROC_GetCurrentCheckoutCount
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) AS CurrentCount
    FROM Checkouts
    WHERE UserId = @UserId AND ReturnDate IS NULL;
END
GO

-- Get current checkouts for a member
CREATE OR ALTER PROCEDURE PROC_GetCurrentCheckoutsByMember
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.CheckoutId, c.CopyId, bc.BookId, b.Title AS BookTitle, bc.Barcode,
        c.UserId, c.CheckoutDate, c.DueDate, c.ReturnDate,
        CASE WHEN GETUTCDATE() > c.DueDate THEN 1 ELSE 0 END AS IsOverdue,
        DATEDIFF(DAY, GETUTCDATE(), c.DueDate) AS DaysLeft
    FROM Checkouts c
    INNER JOIN BookCopies bc ON c.CopyId = bc.CopyId
    INNER JOIN Books b ON bc.BookId = b.BookId
    WHERE c.UserId = @UserId AND c.ReturnDate IS NULL
    ORDER BY c.DueDate;
END
GO

-- Get checkout history for a member (returned books)
CREATE OR ALTER PROCEDURE PROC_GetCheckoutHistoryByMember
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.CheckoutId, c.CopyId, bc.BookId, b.Title AS BookTitle, bc.Barcode,
        c.UserId, c.CheckoutDate, c.DueDate, c.ReturnDate,
        CASE WHEN c.ReturnDate > c.DueDate THEN 1 ELSE 0 END AS WasOverdue
    FROM Checkouts c
    INNER JOIN BookCopies bc ON c.CopyId = bc.CopyId
    INNER JOIN Books b ON bc.BookId = b.BookId
    WHERE c.UserId = @UserId AND c.ReturnDate IS NOT NULL
    ORDER BY c.ReturnDate DESC;
END
GO

-- Get all current checkouts (for librarian)
CREATE OR ALTER PROCEDURE PROC_GetAllCurrentCheckouts
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.CheckoutId, c.CopyId, bc.BookId, b.Title AS BookTitle, bc.Barcode,
        c.UserId, u.FullName AS MemberName, u.Email AS MemberEmail,
        c.CheckoutDate, c.DueDate, c.ReturnDate,
        CASE WHEN GETUTCDATE() > c.DueDate THEN 1 ELSE 0 END AS IsOverdue,
        DATEDIFF(DAY, GETUTCDATE(), c.DueDate) AS DaysLeft
    FROM Checkouts c
    INNER JOIN BookCopies bc ON c.CopyId = bc.CopyId
    INNER JOIN Books b ON bc.BookId = b.BookId
    INNER JOIN AppUsers u ON c.UserId = u.Id
    WHERE c.ReturnDate IS NULL
    ORDER BY c.DueDate;
END
GO

-- Get all overdue checkouts
CREATE OR ALTER PROCEDURE PROC_GetOverdueCheckouts
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        c.CheckoutId, c.CopyId, bc.BookId, b.Title AS BookTitle, bc.Barcode,
        c.UserId, u.FullName AS MemberName, u.Email AS MemberEmail,
        c.CheckoutDate, c.DueDate, c.ReturnDate,
        DATEDIFF(DAY, c.DueDate, GETUTCDATE()) AS DaysOverdue
    FROM Checkouts c
    INNER JOIN BookCopies bc ON c.CopyId = bc.CopyId
    INNER JOIN Books b ON bc.BookId = b.BookId
    INNER JOIN AppUsers u ON c.UserId = u.Id
    WHERE c.ReturnDate IS NULL AND GETUTCDATE() > c.DueDate
    ORDER BY c.DueDate;
END
GO

-- Checkout a book copy (with output params for service layer)
CREATE OR ALTER PROCEDURE PROC_CheckoutBook
    @CopyId INT,
    @UserId UNIQUEIDENTIFIER,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentCount INT;
    SELECT @CurrentCount = COUNT(*) FROM Checkouts WHERE UserId = @UserId AND ReturnDate IS NULL;
    
    IF @CurrentCount >= 5
    BEGIN
        SET @Success = 0;
        SET @Message = 'Member has reached the maximum checkout limit of 5 books.';
        RETURN;
    END
    
    DECLARE @CopyStatus INT;
    SELECT @CopyStatus = Status FROM BookCopies WHERE CopyId = @CopyId;
    
    IF @CopyStatus != 1
    BEGIN
        SET @Success = 0;
        SET @Message = 'This book copy is not available for checkout.';
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
    INSERT INTO Checkouts (CopyId, UserId, CheckoutDate, DueDate)
    VALUES (@CopyId, @UserId, GETUTCDATE(), DATEADD(DAY, 21, GETUTCDATE()));
    
    UPDATE BookCopies SET Status = 0 WHERE CopyId = @CopyId;
    
    COMMIT TRANSACTION;
    
    SET @Success = 1;
    SET @Message = 'Book checked out successfully. Due in 21 days.';
END
GO

-- Return a book (with output params for service layer)
CREATE OR ALTER PROCEDURE PROC_ReturnBook
    @CheckoutId INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CopyId INT;
    SELECT @CopyId = CopyId FROM Checkouts WHERE CheckoutId = @CheckoutId AND ReturnDate IS NULL;
    
    IF @CopyId IS NULL
    BEGIN
        SET @Success = 0;
        SET @Message = 'Checkout not found or already returned.';
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
    UPDATE Checkouts 
    SET ReturnDate = GETUTCDATE(), IsMarkedReturned = 1 
    WHERE CheckoutId = @CheckoutId;
    
    UPDATE BookCopies SET Status = 1 WHERE CopyId = @CopyId;
    
    COMMIT TRANSACTION;
    
    SET @Success = 1;
    SET @Message = 'Book returned successfully.';
END
GO

-- Get all members
CREATE OR ALTER PROCEDURE PROC_GetAllMembers
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        u.Id AS UserId, u.UserName, u.Email, u.FullName,
        (SELECT COUNT(*) FROM Checkouts c WHERE c.UserId = u.Id AND c.ReturnDate IS NULL) AS CurrentCheckouts
    FROM AppUsers u
    INNER JOIN AppUserRoles ur ON u.Id = ur.UserId
    INNER JOIN AppRoles r ON ur.RoleId = r.Id
    WHERE r.NormalizedName = 'MEMBER'
    ORDER BY u.FullName;
END
GO

-- Get all authors (active only)
CREATE OR ALTER PROCEDURE PROC_GetAllAuthors
AS
BEGIN
    SET NOCOUNT ON;
    SELECT AuthorId, FirstName, LastName, Bio
    FROM Authors
    WHERE Active = 1
    ORDER BY LastName, FirstName;
END
GO

-- Get dashboard stats for librarian
CREATE OR ALTER PROCEDURE PROC_GetLibrarianDashboardStats
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        (SELECT COUNT(*) FROM Books WHERE Active = 1) AS TotalBooks,
        (SELECT COUNT(*) FROM BookCopies) AS TotalCopies,
        (SELECT COUNT(*) FROM BookCopies WHERE Status = 1) AS AvailableCopies,
        (SELECT COUNT(*) FROM Checkouts WHERE ReturnDate IS NULL) AS ActiveCheckouts,
        (SELECT COUNT(*) FROM Checkouts WHERE ReturnDate IS NULL AND GETUTCDATE() > DueDate) AS OverdueCount,
        (SELECT COUNT(DISTINCT u.Id) 
         FROM AppUsers u
         INNER JOIN AppUserRoles ur ON u.Id = ur.UserId
         INNER JOIN AppRoles r ON ur.RoleId = r.Id
         WHERE r.NormalizedName = 'MEMBER') AS TotalMembers;
END
GO

-- =============================================================================
-- SECTION 8: SEED DATA
-- =============================================================================

-- Seed Roles
IF NOT EXISTS (SELECT 1 FROM AppRoles WHERE NormalizedName = 'LIBRARIAN')
    INSERT INTO AppRoles (Name, NormalizedName, ConcurrencyStamp)
    VALUES ('Librarian', 'LIBRARIAN', NEWID());

IF NOT EXISTS (SELECT 1 FROM AppRoles WHERE NormalizedName = 'MEMBER')
    INSERT INTO AppRoles (Name, NormalizedName, ConcurrencyStamp)
    VALUES ('Member', 'MEMBER', NEWID());
GO

-- Seed Authors
IF NOT EXISTS (SELECT 1 FROM Authors)
BEGIN
    INSERT INTO Authors (FirstName, LastName, Bio, CreatedAt, Active) VALUES 
        ('George', 'Orwell', 'English novelist and essayist', GETDATE(), 1),
        ('Jane', 'Austen', 'English novelist known for romance novels', GETDATE(), 1),
        ('J.K.', 'Rowling', 'British author of Harry Potter series', GETDATE(), 1),
        ('Stephen', 'King', 'American author of horror and suspense', GETDATE(), 1),
        ('Chinua', 'Achebe', 'Nigerian novelist', GETDATE(), 1),
        ('Mark', 'Twain', 'American writer and humorist', GETDATE(), 1);
END
GO

-- Seed Books
IF NOT EXISTS (SELECT 1 FROM Books)
BEGIN
    INSERT INTO Books (Title, ISBN, PublishedYear, Summary, TotalPages, CreatedAt, Active) VALUES
        ('1984', '9780451524935', 1949, 'A dystopian social science fiction novel', 328, GETDATE(), 1),
        ('Pride and Prejudice', '9780141439518', 1813, 'A romantic novel of manners', 432, GETDATE(), 1),
        ('Harry Potter and the Philosopher''s Stone', '9780747532699', 1997, 'The first book in the Harry Potter series', 309, GETDATE(), 1),
        ('The Shining', '9780385121675', 1977, 'A horror novel set in an isolated hotel', 447, GETDATE(), 1),
        ('Things Fall Apart', '9780385474542', 1958, 'A novel about pre-colonial life in Nigeria', 234, GETDATE(), 1),
        ('Adventures of Huckleberry Finn', '9780486280615', 1884, 'A novel about a young boy and a runaway slave', 366, GETDATE(), 1);
END
GO

-- Seed BookAuthors
IF NOT EXISTS (SELECT 1 FROM BookAuthors)
BEGIN
    INSERT INTO BookAuthors(BookId, AuthorId) VALUES
        (1, 1), -- 1984 - Orwell
        (2, 2), -- Pride and Prejudice - Austen
        (3, 3), -- Harry Potter - Rowling
        (4, 4), -- The Shining - King
        (5, 5), -- Things Fall Apart - Achebe
        (6, 6); -- Huckleberry Finn - Twain
END
GO

-- Seed BookCopies
IF NOT EXISTS (SELECT 1 FROM BookCopies)
BEGIN
    INSERT INTO BookCopies (BookId, Barcode, AcquisitionDate, Condition, [Status]) VALUES
        -- 1984 (3 copies)
        (1, 'BC-1984-001', '2021-11-01', 'New', 1),
        (1, 'BC-1984-002', '2021-11-01', 'Good', 1),
        (1, 'BC-1984-003', '2021-11-01', 'Fair', 1),
        -- Pride and Prejudice (2 copies)
        (2, 'BC-PRDP-001', '2021-11-01', 'New', 1),
        (2, 'BC-PRDP-002', '2021-11-01', 'Good', 1),
        -- Harry Potter (4 copies)
        (3, 'BC-HPPS-001', '2021-11-01', 'Excellent', 1),
        (3, 'BC-HPPS-002', '2021-11-01', 'Good', 1),
        (3, 'BC-HPPS-003', '2021-11-01', 'Good', 1),
        (3, 'BC-HPPS-004', '2021-11-01', 'New', 1),
        -- The Shining (2 copies)
        (4, 'BC-SHIN-001', '2021-11-01', 'Good', 1),
        (4, 'BC-SHIN-002', '2021-11-01', 'Fair', 1),
        -- Things Fall Apart (3 copies)
        (5, 'BC-TFAP-001', '2021-11-01', 'New', 1),
        (5, 'BC-TFAP-002', '2021-11-01', 'Good', 1),
        (5, 'BC-TFAP-003', '2021-11-01', 'Good', 1),
        -- Huckleberry Finn (2 copies)
        (6, 'BC-HCKF-001', '2021-11-01', 'Good', 1),
        (6, 'BC-HCKF-002', '2021-11-01', 'Fair', 1);
END
GO

PRINT '=============================================================================';
PRINT 'GenLibrary Database Setup Completed Successfully!';
PRINT '=============================================================================';
PRINT 'Tables Created: AppUsers, AppRoles, AppUserRoles, AppUserClaims, AppRoleClaims,';
PRINT '                AppUserLogins, AppUserTokens, Authors, Books, BookAuthors,';
PRINT '                BookCopies, Checkouts';
PRINT 'Views Created:  DetailedBooks, BookCopyDetailed';
PRINT 'Stored Procedures: Identity (12) + Library (20)';
PRINT 'Seed Data: 2 Roles, 6 Authors, 6 Books, 17 Book Copies';
PRINT '=============================================================================';
GO
