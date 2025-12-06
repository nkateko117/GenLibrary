-- =============================================================================
-- GenLibrary Database Setup Script
-- Run this script to create all required tables and stored procedures
-- =============================================================================

-- =============================================================================
-- SECTION 1: TABLES
-- =============================================================================

-- Authors Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Authors')
BEGIN
    CREATE TABLE Authors (
        AuthorId INT IDENTITY(1,1) PRIMARY KEY,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        Bio NVARCHAR(MAX) NULL,
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        Active BIT DEFAULT 1
    );
END
GO

-- Books Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Books')
BEGIN
    CREATE TABLE Books (
        BookId INT IDENTITY(1,1) PRIMARY KEY,
        Title NVARCHAR(255) NOT NULL,
        ISBN NVARCHAR(20) NULL,
        Summary NVARCHAR(MAX) NULL,
        PublishedYear INT NULL,
        TotalPages INT NULL,
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        Active BIT DEFAULT 1
    );
END
GO

-- BookAuthors Junction Table (Many-to-Many)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookAuthors')
BEGIN
    CREATE TABLE BookAuthors (
        BookId INT NOT NULL,
        AuthorId INT NOT NULL,
        PRIMARY KEY (BookId, AuthorId),
        FOREIGN KEY (BookId) REFERENCES Books(BookId),
        FOREIGN KEY (AuthorId) REFERENCES Authors(AuthorId)
    );
END
GO

-- CopyStatuses Lookup Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CopyStatuses')
BEGIN
    CREATE TABLE CopyStatuses (
        StatusId INT PRIMARY KEY,
        StatusName NVARCHAR(50) NOT NULL
    );

    INSERT INTO CopyStatuses (StatusId, StatusName) VALUES
        (1, 'Available'),
        (0, 'Checked Out'),
        (-1, 'Out of Commission');
END
GO

-- BookCopies Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BookCopies')
BEGIN
    CREATE TABLE BookCopies (
        CopyId INT IDENTITY(1,1) PRIMARY KEY,
        BookId INT NOT NULL,
        Barcode NVARCHAR(50) NOT NULL UNIQUE,
        AcquisitionDate DATE DEFAULT GETUTCDATE(),
        Condition NVARCHAR(50) DEFAULT 'Good',
        Status INT DEFAULT 1,
        FOREIGN KEY (BookId) REFERENCES Books(BookId),
        FOREIGN KEY (Status) REFERENCES CopyStatuses(StatusId)
    );
END
GO

-- Checkouts Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Checkouts')
BEGIN
    CREATE TABLE Checkouts (
        CheckoutId INT IDENTITY(1,1) PRIMARY KEY,
        CopyId INT NOT NULL,
        UserId UNIQUEIDENTIFIER NOT NULL,
        CheckoutDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        DueDate DATETIME2 NOT NULL,
        ReturnDate DATETIME2 NULL,
        IsMarkedReturned BIT DEFAULT 0,
        FOREIGN KEY (CopyId) REFERENCES BookCopies(CopyId),
        FOREIGN KEY (UserId) REFERENCES AspNetUsers(Id)
    );
END
GO

-- Create indexes for performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkouts_UserId')
    CREATE INDEX IX_Checkouts_UserId ON Checkouts(UserId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Checkouts_CopyId')
    CREATE INDEX IX_Checkouts_CopyId ON Checkouts(CopyId);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_BookCopies_BookId')
    CREATE INDEX IX_BookCopies_BookId ON BookCopies(BookId);
GO

-- =============================================================================
-- SECTION 2: STORED PROCEDURES
-- =============================================================================

-- Get Detailed Books with Author info and copy counts
CREATE OR ALTER PROCEDURE PROC_GetDetailedBooks
AS
BEGIN
    SET NOCOUNT ON;
    
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
        (SELECT COUNT(*) FROM BookCopies bc WHERE bc.BookId = b.BookId) AS TotalCopies,
        (SELECT COUNT(*) FROM BookCopies bc WHERE bc.BookId = b.BookId AND bc.Status = 1) AS AvailableCopies
    FROM Books b
    LEFT JOIN BookAuthors ba ON b.BookId = ba.BookId
    LEFT JOIN Authors a ON ba.AuthorId = a.AuthorId
    WHERE b.Active = 1
    GROUP BY b.BookId, b.Title, b.ISBN, b.Summary, b.PublishedYear, b.TotalPages, b.CreatedAt, b.Active
    ORDER BY b.Title;
END
GO

-- Get Detailed Book by ID
CREATE OR ALTER PROCEDURE PROC_GetDetailedBook_ById
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
        (SELECT COUNT(*) FROM BookCopies bc WHERE bc.BookId = b.BookId) AS TotalCopies,
        (SELECT COUNT(*) FROM BookCopies bc WHERE bc.BookId = b.BookId AND bc.Status = 1) AS AvailableCopies
    FROM Books b
    LEFT JOIN BookAuthors ba ON b.BookId = ba.BookId
    LEFT JOIN Authors a ON ba.AuthorId = a.AuthorId
    WHERE b.BookId = @BookId AND b.Active = 1
    GROUP BY b.BookId, b.Title, b.ISBN, b.Summary, b.PublishedYear, b.TotalPages, b.CreatedAt, b.Active;
END
GO

-- Get Book Copies with checkout info
CREATE OR ALTER PROCEDURE PROC_GetBookCopies
    @BookId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        bc.CopyId,
        bc.BookId,
        bc.Barcode,
        bc.AcquisitionDate,
        bc.Condition,
        bc.Status,
        cs.StatusName,
        b.Title,
        c.CheckoutDate,
        c.DueDate,
        c.IsMarkedReturned,
        c.UserId,
        u.FullName AS MemberFullName,
        CASE 
            WHEN c.CheckoutId IS NOT NULL AND c.ReturnDate IS NULL 
            THEN DATEDIFF(DAY, GETUTCDATE(), c.DueDate) 
            ELSE NULL 
        END AS DaysLeft
    FROM BookCopies bc
    INNER JOIN Books b ON bc.BookId = b.BookId
    INNER JOIN CopyStatuses cs ON bc.Status = cs.StatusId
    LEFT JOIN Checkouts c ON bc.CopyId = c.CopyId AND c.ReturnDate IS NULL
    LEFT JOIN AspNetUsers u ON c.UserId = u.Id
    WHERE (@BookId IS NULL OR bc.BookId = @BookId)
    ORDER BY bc.Barcode;
END
GO

-- Get available copies for a book (for checkout selection)
CREATE OR ALTER PROCEDURE PROC_GetAvailableCopies
    @BookId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        bc.CopyId,
        bc.BookId,
        bc.Barcode,
        bc.Condition,
        b.Title
    FROM BookCopies bc
    INNER JOIN Books b ON bc.BookId = b.BookId
    WHERE bc.BookId = @BookId AND bc.Status = 1
    ORDER BY bc.Barcode;
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
        c.CheckoutId,
        c.CopyId,
        bc.BookId,
        b.Title AS BookTitle,
        bc.Barcode,
        c.UserId,
        c.CheckoutDate,
        c.DueDate,
        c.ReturnDate,
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
        c.CheckoutId,
        c.CopyId,
        bc.BookId,
        b.Title AS BookTitle,
        bc.Barcode,
        c.UserId,
        c.CheckoutDate,
        c.DueDate,
        c.ReturnDate,
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
        c.CheckoutId,
        c.CopyId,
        bc.BookId,
        b.Title AS BookTitle,
        bc.Barcode,
        c.UserId,
        u.FullName AS MemberName,
        u.Email AS MemberEmail,
        c.CheckoutDate,
        c.DueDate,
        c.ReturnDate,
        CASE WHEN GETUTCDATE() > c.DueDate THEN 1 ELSE 0 END AS IsOverdue,
        DATEDIFF(DAY, GETUTCDATE(), c.DueDate) AS DaysLeft
    FROM Checkouts c
    INNER JOIN BookCopies bc ON c.CopyId = bc.CopyId
    INNER JOIN Books b ON bc.BookId = b.BookId
    INNER JOIN AspNetUsers u ON c.UserId = u.Id
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
        c.CheckoutId,
        c.CopyId,
        bc.BookId,
        b.Title AS BookTitle,
        bc.Barcode,
        c.UserId,
        u.FullName AS MemberName,
        u.Email AS MemberEmail,
        c.CheckoutDate,
        c.DueDate,
        c.ReturnDate,
        DATEDIFF(DAY, c.DueDate, GETUTCDATE()) AS DaysOverdue
    FROM Checkouts c
    INNER JOIN BookCopies bc ON c.CopyId = bc.CopyId
    INNER JOIN Books b ON bc.BookId = b.BookId
    INNER JOIN AspNetUsers u ON c.UserId = u.Id
    WHERE c.ReturnDate IS NULL AND GETUTCDATE() > c.DueDate
    ORDER BY c.DueDate;
END
GO

-- Checkout a book copy
CREATE OR ALTER PROCEDURE PROC_CheckoutBook
    @CopyId INT,
    @UserId UNIQUEIDENTIFIER,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if member already has 5 books
    DECLARE @CurrentCount INT;
    SELECT @CurrentCount = COUNT(*) FROM Checkouts WHERE UserId = @UserId AND ReturnDate IS NULL;
    
    IF @CurrentCount >= 5
    BEGIN
        SET @Success = 0;
        SET @Message = 'Member has reached the maximum checkout limit of 5 books.';
        RETURN;
    END
    
    -- Check if copy is available
    DECLARE @CopyStatus INT;
    SELECT @CopyStatus = Status FROM BookCopies WHERE CopyId = @CopyId;
    
    IF @CopyStatus != 1
    BEGIN
        SET @Success = 0;
        SET @Message = 'This book copy is not available for checkout.';
        RETURN;
    END
    
    -- Perform checkout
    BEGIN TRANSACTION;
    
    INSERT INTO Checkouts (CopyId, UserId, CheckoutDate, DueDate)
    VALUES (@CopyId, @UserId, GETUTCDATE(), DATEADD(DAY, 21, GETUTCDATE()));
    
    UPDATE BookCopies SET Status = 0 WHERE CopyId = @CopyId;
    
    COMMIT TRANSACTION;
    
    SET @Success = 1;
    SET @Message = 'Book checked out successfully. Due in 21 days.';
END
GO

-- Return a book
CREATE OR ALTER PROCEDURE PROC_ReturnBook
    @CheckoutId INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get the copy ID
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
        u.Id AS UserId,
        u.UserName,
        u.Email,
        u.FullName,
        (SELECT COUNT(*) FROM Checkouts c WHERE c.UserId = u.Id AND c.ReturnDate IS NULL) AS CurrentCheckouts
    FROM AspNetUsers u
    INNER JOIN AspNetUserRoles ur ON u.Id = ur.UserId
    INNER JOIN AspNetRoles r ON ur.RoleId = r.Id
    WHERE r.NormalizedName = 'MEMBER'
    ORDER BY u.FullName;
END
GO

-- Get all authors
CREATE OR ALTER PROCEDURE PROC_GetAllAuthors
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        AuthorId,
        FirstName,
        LastName,
        Bio
    FROM Authors
    WHERE Active = 1
    ORDER BY LastName, FirstName;
END
GO

-- Get books by author
CREATE OR ALTER PROCEDURE PROC_GetBooksByAuthor
    @AuthorId INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
        (SELECT COUNT(*) FROM BookCopies bc WHERE bc.BookId = b.BookId) AS TotalCopies,
        (SELECT COUNT(*) FROM BookCopies bc WHERE bc.BookId = b.BookId AND bc.Status = 1) AS AvailableCopies
    FROM Books b
    INNER JOIN BookAuthors ba ON b.BookId = ba.BookId
    INNER JOIN Authors a ON ba.AuthorId = a.AuthorId
    WHERE b.Active = 1 AND ba.AuthorId = @AuthorId
    GROUP BY b.BookId, b.Title, b.ISBN, b.Summary, b.PublishedYear, b.TotalPages, b.CreatedAt, b.Active
    ORDER BY b.Title;
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
         FROM AspNetUsers u
         INNER JOIN AspNetUserRoles ur ON u.Id = ur.UserId
         INNER JOIN AspNetRoles r ON ur.RoleId = r.Id
         WHERE r.NormalizedName = 'MEMBER') AS TotalMembers;
END
GO

-- =============================================================================
-- SECTION 3: SAMPLE DATA
-- =============================================================================

-- Insert sample authors
IF NOT EXISTS (SELECT 1 FROM Authors)
BEGIN
    INSERT INTO Authors (FirstName, LastName, Bio) VALUES
        ('George', 'Orwell', 'English novelist and essayist'),
        ('Jane', 'Austen', 'English novelist known for romance novels'),
        ('Mark', 'Twain', 'American writer and humorist'),
        ('Ernest', 'Hemingway', 'American novelist and journalist'),
        ('Agatha', 'Christie', 'English writer known for detective novels'),
        ('Stephen', 'King', 'American author of horror and suspense'),
        ('J.K.', 'Rowling', 'British author of Harry Potter series'),
        ('Dan', 'Brown', 'American author of thriller fiction');
END
GO

-- Insert sample books
IF NOT EXISTS (SELECT 1 FROM Books)
BEGIN
    INSERT INTO Books (Title, ISBN, Summary, PublishedYear, TotalPages) VALUES
        ('1984', '978-0451524935', 'A dystopian social science fiction novel', 1949, 328),
        ('Animal Farm', '978-0451526342', 'A satirical allegorical novella', 1945, 112),
        ('Pride and Prejudice', '978-0141439518', 'A romantic novel of manners', 1813, 432),
        ('Adventures of Huckleberry Finn', '978-0486280615', 'A novel about a young boy and a runaway slave', 1884, 366),
        ('The Old Man and the Sea', '978-0684801223', 'A short novel about an aging fisherman', 1952, 127),
        ('Murder on the Orient Express', '978-0062693662', 'A detective novel featuring Hercule Poirot', 1934, 256),
        ('The Shining', '978-0307743657', 'A horror novel set in an isolated hotel', 1977, 447),
        ('Harry Potter and the Sorcerers Stone', '978-0590353427', 'The first book in the Harry Potter series', 1997, 309),
        ('The Da Vinci Code', '978-0307474278', 'A mystery thriller novel', 2003, 489),
        ('Emma', '978-0141439587', 'A comic novel about youthful hubris', 1815, 474);
END
GO

-- Link books to authors
IF NOT EXISTS (SELECT 1 FROM BookAuthors)
BEGIN
    INSERT INTO BookAuthors (BookId, AuthorId) VALUES
        (1, 1), -- 1984 - Orwell
        (2, 1), -- Animal Farm - Orwell
        (3, 2), -- Pride and Prejudice - Austen
        (4, 3), -- Huckleberry Finn - Twain
        (5, 4), -- Old Man and the Sea - Hemingway
        (6, 5), -- Murder on Orient Express - Christie
        (7, 6), -- The Shining - King
        (8, 7), -- Harry Potter - Rowling
        (9, 8), -- Da Vinci Code - Brown
        (10, 2); -- Emma - Austen
END
GO

-- Insert sample book copies
IF NOT EXISTS (SELECT 1 FROM BookCopies)
BEGIN
    INSERT INTO BookCopies (BookId, Barcode, Condition, Status) VALUES
        -- 1984 copies
        (1, 'BC-1984-001', 'Good', 1),
        (1, 'BC-1984-002', 'Fair', 1),
        (1, 'BC-1984-003', 'New', 1),
        -- Animal Farm copies
        (2, 'BC-ANFM-001', 'Good', 1),
        (2, 'BC-ANFM-002', 'Good', 1),
        -- Pride and Prejudice copies
        (3, 'BC-PRDP-001', 'Excellent', 1),
        (3, 'BC-PRDP-002', 'Good', 1),
        (3, 'BC-PRDP-003', 'Fair', 1),
        -- Adventures of Huckleberry Finn
        (4, 'BC-HCKF-001', 'Good', 1),
        (4, 'BC-HCKF-002', 'Good', 1),
        -- The Old Man and the Sea
        (5, 'BC-OMTS-001', 'New', 1),
        -- Murder on the Orient Express
        (6, 'BC-MOEX-001', 'Good', 1),
        (6, 'BC-MOEX-002', 'Excellent', 1),
        -- The Shining
        (7, 'BC-SHIN-001', 'Good', 1),
        (7, 'BC-SHIN-002', 'Fair', 1),
        -- Harry Potter
        (8, 'BC-HPSS-001', 'Excellent', 1),
        (8, 'BC-HPSS-002', 'Good', 1),
        (8, 'BC-HPSS-003', 'Good', 1),
        (8, 'BC-HPSS-004', 'New', 1),
        -- Da Vinci Code
        (9, 'BC-DVNC-001', 'Good', 1),
        (9, 'BC-DVNC-002', 'Good', 1),
        -- Emma
        (10, 'BC-EMMA-001', 'Excellent', 1);
END
GO

PRINT 'Database setup completed successfully!';
GO
