-- =========================================================
-- Sample data for the Library Management System
-- =========================================================

INSERT INTO authors (first_name, last_name, nationality) VALUES
('George', 'Orwell', 'British'),
('Jane', 'Austen', 'British'),
('Chinua', 'Achebe', 'Nigerian'),
('Haruki', 'Murakami', 'Japanese'),
('R.K.', 'Narayan', 'Indian');

INSERT INTO categories (name) VALUES
('Fiction'),
('Classic Literature'),
('Science Fiction'),
('Non-Fiction'),
('Biography');

INSERT INTO books (title, author_id, category_id, isbn, published_year, total_copies, available_copies) VALUES
('1984', 1, 3, '9780451524935', 1949, 4, 2),
('Animal Farm', 1, 1, '9780451526342', 1945, 3, 3),
('Pride and Prejudice', 2, 2, '9780141439518', 1813, 2, 1),
('Things Fall Apart', 3, 1, '9780385474542', 1958, 3, 3),
('Norwegian Wood', 4, 1, '9780375704024', 1987, 2, 1),
('Kafka on the Shore', 4, 3, '9781400079278', 2002, 2, 2),
('Malgudi Days', 5, 1, '9780143039655', 1943, 3, 2);

INSERT INTO members (first_name, last_name, email, phone, join_date, status) VALUES
('Meera', 'Pillai', 'meera.pillai@mail.com', '9811100001', '2024-01-15', 'active'),
('Aditya', 'Kapoor', 'aditya.kapoor@mail.com', '9811100002', '2024-03-22', 'active'),
('Fatima', 'Sheikh', 'fatima.sheikh@mail.com', '9811100003', '2023-11-05', 'active'),
('Rohan', 'Das', 'rohan.das@mail.com', '9811100004', '2025-02-10', 'suspended'),
('Lakshmi', 'Nair', 'lakshmi.nair@mail.com', '9811100005', '2022-07-19', 'active');

-- Loans: some returned, some still checked out, one overdue
INSERT INTO loans (book_id, member_id, loan_date, due_date, return_date, status) VALUES
(1, 1, '2026-07-01', '2026-07-15', NULL, 'checked_out'),
(1, 2, '2026-06-10', '2026-06-24', '2026-06-22', 'returned'),
(3, 3, '2026-06-28', '2026-07-12', NULL, 'checked_out'),
(5, 1, '2026-06-01', '2026-06-15', NULL, 'overdue'),
(7, 5, '2026-07-05', '2026-07-19', NULL, 'checked_out'),
(2, 4, '2026-05-01', '2026-05-15', '2026-05-14', 'returned'),
(6, 2, '2026-06-20', '2026-07-04', '2026-07-03', 'returned');

INSERT INTO reservations (book_id, member_id, reservation_date, status) VALUES
(3, 5, '2026-07-10', 'pending'),
(5, 3, '2026-07-12', 'pending'),
(1, 3, '2026-06-05', 'fulfilled');
