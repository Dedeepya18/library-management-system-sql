-- =========================================================
-- Library Management System — Database Schema
-- Works with SQLite (used by app.py); close to standard SQL
-- so it ports easily to PostgreSQL/MySQL with minor changes.
-- =========================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS authors;

-- Authors
CREATE TABLE authors (
    author_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    nationality     TEXT
);

-- Categories / genres
CREATE TABLE categories (
    category_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL UNIQUE
);

-- Books (catalog entries — each row is a title, with a copy count)
CREATE TABLE books (
    book_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    title               TEXT NOT NULL,
    author_id           INTEGER NOT NULL,
    category_id         INTEGER NOT NULL,
    isbn                TEXT UNIQUE,
    published_year      INTEGER,
    total_copies        INTEGER NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies    INTEGER NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    FOREIGN KEY (author_id) REFERENCES authors(author_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CHECK (available_copies <= total_copies)
);

-- Members
CREATE TABLE members (
    member_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    phone           TEXT,
    join_date       TEXT NOT NULL,          -- YYYY-MM-DD
    status          TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','suspended','expired'))
);

-- Loans (borrow/return records)
CREATE TABLE loans (
    loan_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id         INTEGER NOT NULL,
    member_id       INTEGER NOT NULL,
    loan_date       TEXT NOT NULL,
    due_date        TEXT NOT NULL,
    return_date     TEXT,                   -- NULL while still checked out
    status          TEXT NOT NULL DEFAULT 'checked_out'
                        CHECK (status IN ('checked_out','returned','overdue')),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- Reservations (hold requests for books currently unavailable)
CREATE TABLE reservations (
    reservation_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id             INTEGER NOT NULL,
    member_id           INTEGER NOT NULL,
    reservation_date    TEXT NOT NULL,
    status              TEXT NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending','fulfilled','cancelled')),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- Helpful indexes
CREATE INDEX idx_books_author ON books(author_id);
CREATE INDEX idx_books_category ON books(category_id);
CREATE INDEX idx_loans_member ON loans(member_id);
CREATE INDEX idx_loans_book ON loans(book_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_reservations_book ON reservations(book_id);
