USE [netgen_library]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Get All Authors */
CREATE OR ALTER PROCEDURE [dbo].[PROC_Authors_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [AuthorId]
      ,[FirstName]
      ,[Bio]
      ,[CreatedAt]
      ,[Active]
      ,[LastName]
  FROM [netgen_library].[dbo].[Authors]
END

/* Get All BookAuthors */
CREATE OR ALTER PROCEDURE [dbo].[PROC_BookAuthors_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [BookId]
      ,[AuthorId]
  FROM [netgen_library].[dbo].[BookAuthors]
END

/* Get All BookCopies */
CREATE OR ALTER PROCEDURE [dbo].[PROC_BookCopies_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [CopyId]
      ,[BookId]
      ,[Barcode]
      ,[AcquisitionDate]
      ,[Condition]
      ,[Status]
  FROM [netgen_library].[dbo].[BookCopies]
END

/* Get All Books */
CREATE OR ALTER PROCEDURE [dbo].[PROC_Books_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [BookId]
      ,[Title]
      ,[ISBN]
      ,[Summary]
      ,[PublishedYear]
      ,[TotalPages]
      ,[CreatedAt]
      ,[Active]
      ,[Picture]
  FROM [netgen_library].[dbo].[Books]
END

/* Get All Checkouts */
CREATE OR ALTER PROCEDURE [dbo].[PROC_Checkouts_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT [CheckoutId]
      ,[CopyId]
      ,[UserId]
      ,[CheckoutDate]
      ,[DueDate]
      ,[ReturnDate]
      ,[IsMarkedReturned]
  FROM [netgen_library].[dbo].[Checkouts]
END

/* Update BookCopy */
CREATE OR ALTER PROCEDURE [dbo].[PROC_BookCopy_Update]
    @CopyId INT,
    @Condition NVARCHAR(50),
    @Status INT
AS
BEGIN
    SET NOCOUNT ON;
    Update dbo.BookCopies
    Set
    Condition = @Condition,
    [Status] = @Status
    Where CopyId = @CopyId
END

/* Return Book */
CREATE OR ALTER PROCEDURE [dbo].[PROC_Checkout_ReturnBook]
    @CopyId INT,
    @Condition NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Update ONLY the active checkout
        UPDATE dbo.Checkouts
        SET 
            ReturnDate = GETDATE(),
            IsMarkedReturned = 1
        WHERE 
            CopyId = @CopyId
            AND ReturnDate IS NULL;   -- prevents modifying historical records

        DECLARE @checkoutRows INT = @@ROWCOUNT;
        IF @checkoutRows = 0
        BEGIN
            -- nothing updated → invalid CopyId or no active checkout
            ROLLBACK TRANSACTION;
            SELECT 0 AS Result;
            RETURN;
        END

        -- Update book copy status
        UPDATE dbo.BookCopies
        SET
            Condition = @Condition,
            [Status] = 1
        WHERE 
            CopyId = @CopyId;

        DECLARE @copyRows INT = @@ROWCOUNT;
        IF @copyRows = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS Result;
            RETURN;
        END

        COMMIT TRANSACTION;
        SELECT 1 AS Result; -- success

    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0)
            ROLLBACK TRANSACTION;

        SELECT 0 AS Result; -- failure
    END CATCH
END

/* Return Book */
CREATE OR ALTER PROCEDURE [dbo].[PROC_Checkout_CheckoutBook]
    @CopyId INT,
    @UserId UNIQUEIDENTIFIER,
    @DueDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Validate member checkout limit (max 5 active)
        DECLARE @ActiveCount INT;
        SELECT @ActiveCount = COUNT(*)
        FROM dbo.Checkouts
        WHERE UserId = @UserId AND ReturnDate IS NULL;

        IF @ActiveCount >= 5
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT -1 AS Result;
            RETURN;
        END

        -- Ensure copy exists AND is available (Status = 1)
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

        INSERT INTO dbo.Checkouts
            (CopyId, UserId, CheckoutDate, DueDate, IsMarkedReturned)
        VALUES
            (@CopyId, @UserId, GETDATE(), @DueDate, 0);

        UPDATE dbo.BookCopies
        SET Status = 0
        WHERE CopyId = @CopyId AND Status = 1;

        DECLARE @copyRows INT = @@ROWCOUNT;
        IF @copyRows = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT -2 AS Result; -- still unavailable
            RETURN;
        END

        COMMIT TRANSACTION;
        SELECT 1 AS Result;

    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0)
            ROLLBACK TRANSACTION;

        SELECT 0 AS Result;
    END CATCH
END

/* Books View */
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

/* Get Detailed Books */
CREATE OR ALTER PROCEDURE dbo.PROC_GetDetailedBooks
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.DetailedBooks
    ORDER BY Title;
END

/* Get Single Book */
CREATE PROCEDURE [dbo].[PROC_GetDetailedBook_ById]
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT *
    FROM dbo.DetailedBooks
    Where BookId = @BookId
END

/* Book Copy Detailed Rows */
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
    
    -- New column: StatusName
    CASE 
        WHEN bc.[Status] = 1 THEN 'Available'
        WHEN bc.[Status] = 0 THEN 'Checked Out'
        WHEN bc.[Status] = 3 THEN 'Out of Commission'
        ELSE 'Unknown'
    END AS StatusName,
    
    -- New column: DaysLeft (0 minimum)
    CASE 
        WHEN c.DueDate IS NULL THEN NULL
        ELSE 
            CASE 
                WHEN DATEDIFF(DAY, GETDATE(), c.DueDate) < 0 THEN 0
                ELSE DATEDIFF(DAY, GETDATE(), c.DueDate)
            END
    END AS DaysLeft

FROM dbo.BookCopies bc
INNER JOIN dbo.Books b 
    ON b.BookId = bc.BookId
OUTER APPLY (
    SELECT TOP 1 c_inner.*, u_inner.Id, u_inner.FullName
    FROM dbo.Checkouts c_inner
    INNER JOIN dbo.AppUsers u_inner
        ON c_inner.UserId = u_inner.Id
    WHERE c_inner.CopyId = bc.CopyId
      AND c_inner.ReturnDate IS NULL
      AND c_inner.IsMarkedReturned = 0
    ORDER BY c_inner.CheckoutDate DESC
) c
LEFT JOIN dbo.AppUsers u
    ON c.UserId = u.Id;


/* Get Detailed Book Copies */
CREATE OR ALTER PROCEDURE dbo.PROC_GetBookCopies
    @BookId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CopyId,
        BookId,
        Barcode,
        AcquisitionDate,
        [Condition],
        [Status],
        Title,
        CheckoutDate,
        DueDate,
        IsMarkedReturned,
        UserId,
        MemberFullName,
        StatusName,
        DaysLeft
    FROM dbo.BookCopyDetailed
    WHERE (@BookId IS NULL OR BookId = @BookId)
    ORDER BY CopyId ASC;
END
