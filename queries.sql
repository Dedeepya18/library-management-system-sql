-- =========================================================
-- Common Library reporting queries
-- =========================================================

-- 1. All books currently checked out, with borrower and due date
SELECT b.title, m.first_name || ' ' || m.last_name AS borrower, l.due_date
FROM loans l
JOIN books b ON b.book_id = l.book_id
JOIN members m ON m.member_id = l.member_id
WHERE l.status IN ('checked_out', 'overdue')
ORDER BY l.due_date;

-- 2. Overdue books (past due date and not yet returned)
SELECT b.title, m.first_name || ' ' || m.last_name AS borrower,
       l.due_date, julianday('now') - julianday(l.due_date) AS days_overdue
FROM loans l
JOIN books b ON b.book_id = l.book_id
JOIN members m ON m.member_id = l.member_id
WHERE l.return_date IS NULL AND l.due_date < date('now')
ORDER BY days_overdue DESC;

-- 3. Most borrowed books (all-time)
SELECT b.title, COUNT(l.loan_id) AS times_borrowed
FROM loans l
JOIN books b ON b.book_id = l.book_id
GROUP BY b.title
ORDER BY times_borrowed DESC;

-- 4. Book availability by title
SELECT title, available_copies, total_copies
FROM books
ORDER BY available_copies ASC;

-- 5. Books per category
SELECT c.name AS category, COUNT(b.book_id) AS book_count
FROM categories c
LEFT JOIN books b ON b.category_id = c.category_id
GROUP BY c.name
ORDER BY book_count DESC;

-- 6. Member borrowing history
SELECT m.first_name || ' ' || m.last_name AS member,
       b.title, l.loan_date, l.return_date, l.status
FROM loans l
JOIN members m ON m.member_id = l.member_id
JOIN books b ON b.book_id = l.book_id
ORDER BY member, l.loan_date DESC;

-- 7. Most active borrowers
SELECT m.first_name || ' ' || m.last_name AS member, COUNT(l.loan_id) AS total_loans
FROM loans l
JOIN members m ON m.member_id = l.member_id
GROUP BY member
ORDER BY total_loans DESC;

-- 8. Books by a specific author (Murakami example)
SELECT b.title, b.published_year
FROM books b
JOIN authors a ON a.author_id = b.author_id
WHERE a.first_name = 'Haruki' AND a.last_name = 'Murakami';

-- 9. Pending reservations, oldest first
SELECT b.title, m.first_name || ' ' || m.last_name AS member, r.reservation_date
FROM reservations r
JOIN books b ON b.book_id = r.book_id
JOIN members m ON m.member_id = r.member_id
WHERE r.status = 'pending'
ORDER BY r.reservation_date;

-- 10. Average loan duration (returned books only, in days)
SELECT ROUND(AVG(julianday(return_date) - julianday(loan_date)), 1) AS avg_days
FROM loans
WHERE return_date IS NOT NULL;
