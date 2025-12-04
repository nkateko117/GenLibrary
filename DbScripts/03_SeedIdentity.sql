Use netgen_library
Go

SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM AppRoles WHERE NormalizedName = 'LIBRARIAN')
    INSERT INTO AppRoles (Name, NormalizedName, ConcurrencyStamp)
    VALUES ('Librarian', 'LIBRARIAN', NEWID());

IF NOT EXISTS (SELECT 1 FROM AppRoles WHERE NormalizedName = 'MEMBER')
    INSERT INTO AppRoles (Name, NormalizedName, ConcurrencyStamp)
    VALUES ('Member', 'MEMBER', NEWID());
GO