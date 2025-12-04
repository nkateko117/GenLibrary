Use netgen_library
Go

SET NOCOUNT ON;
GO

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

-- Update user (basic fields and concurrencystamp)
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

-- Find role by Id
CREATE OR ALTER PROCEDURE PROC_ID_GetRoleById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 Id, Name, NormalizedName, ConcurrencyStamp FROM AppRoles WHERE Id = @Id;
END
GO

-- Set password hash for user (update)
CREATE OR ALTER PROCEDURE PROC_ID_SetPasswordHash
    @UserId UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE AppUsers SET PasswordHash = @PasswordHash WHERE Id = @UserId;
END
GO

-- Optional: Get user by normalized email
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