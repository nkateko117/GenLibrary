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

INSERT INTO Authors (FirstName, LastName, Bio, CreatedAt, Active)
VALUES 
('George', 'Orwell', 'Bio', GETDATE(), 1),
('Jane', 'Austen', 'Bio', GETDATE(), 1),
('J.K.', 'Rowling', 'Bio', GETDATE(), 1),
('Stephen', 'King', 'Bio', GETDATE(), 1),
('Chinua', 'Achebe', 'Bio', GETDATE(), 1),
('Mark', 'Twain', 'Bio', GETDATE(), 1);

----------------------------------------------------------
INSERT INTO Books (Title, ISBN, PublishedYear, Summary, TotalPages, CreatedAt, Active)
VALUES
('1984', '9780451524935', 1949, 'Book Summary', 142, GETDATE(), 1),
('Pride and Prejudice', '9780141439518', 1813, 'Book Summary', 425, GETDATE(), 1),
('Harry Potter and the Philosopher''s Stone', '9780747532699', 1997, 'Book Summary', 235, GETDATE(), 1),
('The Shining', '9780385121675', 1977, 'Book Summary', 652, GETDATE(), 1),
('Things Fall Apart', '9780385474542', 1958, 'Book Summary', 234, GETDATE(), 1),
('Adventures of Huckleberry Finn', '9780486280615', 1884, 'Book Summary', 192, GETDATE(), 1);

INSERT INTO BookAuthors(BookId, AuthorId)
VALUES
(1, 1),
(1, 3),
(2, 2),
(3, 3),
(4, 4),
(4, 2),
(5,5),
(6, 6);

INSERT INTO BookCopies (BookId, Barcode, AcquisitionDate, Condition, [Status])
VALUES
-- 1984 (3 copies)
(1, '35ds34tf2r23r','2021-11-01', 'New', 1),
(1, '4t3y3r2e2r23r','2021-11-01', 'New', 1),
(1, '35dsf3245r23r','2021-11-01', 'New', 1),

-- Pride and Prejudice (2 copies)
(2, 'tfh3452433423','2021-11-01', 'New', 1),
(2, '34trfdh5344g4','2021-11-01', 'New', 1),

-- Harry Potter (4 copies)
(3, '43tfgr5345466r','2021-11-01', 'New', 1),
(3, 'rt4t33y434trr3','2021-11-01', 'New', 1),
(3, '4r3tftert4543r','2021-11-01', 'New', 1),
(3, '435ewtrt433422','2021-11-01', 'New', 1),

-- The Shining (2 copies)
(4, '5444t34gfhr34','2021-11-01', 'New', 1),
(4, '434353rtrtret','2021-11-01', 'New', 1),

-- Things Fall Apart (3 copies)
(5, 'mddsftt435y53','2021-11-01', 'New', 1),
(5, 'dfhfdh3452435','2021-11-01', 'New', 1),
(5, 'ewr434523hhjf','2021-11-01', 'New', 1),

-- Huck Finn (2 copies)
(6, '43t34thfdrret','2021-11-01', 'New', 1),
(6, 'fdh4t443t3tdf','2021-11-01', 'New', 1);
