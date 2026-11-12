"""
Library Management System — CLI Application
Wraps the SQLite database defined in schema.sql with a simple
menu-driven interface for day-to-day library operations.

Usage:
    python app.py init      # (re)build the database from schema.sql + sample_data.sql
    python app.py           # launch the interactive menu
"""

import sqlite3
import sys
from datetime import datetime, timedelta
from pathlib import Path

DB_PATH = Path(__file__).parent / "library.db"
SCHEMA_PATH = Path(__file__).parent / "schema.sql"
SAMPLE_DATA_PATH = Path(__file__).parent / "sample_data.sql"

LOAN_PERIOD_DAYS = 14


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.row_factory = sqlite3.Row
    return conn


def init_db(with_sample_data=True):
    conn = get_connection()
    with open(SCHEMA_PATH) as f:
        conn.executescript(f.read())
    if with_sample_data:
        with open(SAMPLE_DATA_PATH) as f:
            conn.executescript(f.read())
    conn.commit()
    conn.close()
    print(f"Database initialized at {DB_PATH}")


# ---------------------------------------------------------------
# Core operations
# ---------------------------------------------------------------

def list_books(conn):
    print("\n-- Book catalog --")
    rows = conn.execute(
        """SELECT b.book_id, b.title, a.first_name || ' ' || a.last_name AS author,
                  c.name AS category, b.available_copies, b.total_copies
           FROM books b
           JOIN authors a ON a.author_id = b.author_id
           JOIN categories c ON c.category_id = b.category_id
           ORDER BY b.title"""
    ).fetchall()
    for r in rows:
        print(f"  #{r['book_id']:<3} {r['title']:<24} by {r['author']:<18} "
              f"[{r['category']:<12}] {r['available_copies']}/{r['total_copies']} available")


def add_book(conn):
    print("\n-- Add new book --")
    title = input("Title: ").strip()

    print("\nAuthors:")
    for r in conn.execute("SELECT * FROM authors"):
        print(f"  [{r['author_id']}] {r['first_name']} {r['last_name']}")
    author_id = int(input("Author ID: ").strip())

    print("\nCategories:")
    for r in conn.execute("SELECT * FROM categories"):
        print(f"  [{r['category_id']}] {r['name']}")
    category_id = int(input("Category ID: ").strip())

    isbn = input("ISBN (optional): ").strip() or None
    year = input("Published year (optional): ").strip()
    year = int(year) if year else None
    copies = int(input("Number of copies: ").strip() or "1")

    conn.execute(
        """INSERT INTO books (title, author_id, category_id, isbn, published_year,
                               total_copies, available_copies)
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (title, author_id, category_id, isbn, year, copies, copies),
    )
    conn.commit()
    print(f"Added '{title}' with {copies} cop{'y' if copies == 1 else 'ies'}.")


def add_member(conn):
    print("\n-- Add new member --")
    first = input("First name: ").strip()
    last = input("Last name: ").strip()
    email = input("Email: ").strip()
    phone = input("Phone: ").strip()
    join_date = datetime.now().strftime("%Y-%m-%d")
    conn.execute(
        """INSERT INTO members (first_name, last_name, email, phone, join_date)
           VALUES (?, ?, ?, ?, ?)""",
        (first, last, email, phone, join_date),
    )
    conn.commit()
    print(f"Added member: {first} {last}")


def checkout_book(conn):
    print("\n-- Check out a book --")
    book_id = int(input("Book ID: ").strip())
    member_id = int(input("Member ID: ").strip())

    book = conn.execute("SELECT * FROM books WHERE book_id = ?", (book_id,)).fetchone()
    if not book:
        print("No such book.")
        return
    if book["available_copies"] < 1:
        print(f"'{book['title']}' has no available copies right now.")
        return

    member = conn.execute("SELECT * FROM members WHERE member_id = ?", (member_id,)).fetchone()
    if not member or member["status"] != "active":
        print("Member not found or not active.")
        return

    loan_date = datetime.now().strftime("%Y-%m-%d")
    due_date = (datetime.now() + timedelta(days=LOAN_PERIOD_DAYS)).strftime("%Y-%m-%d")

    conn.execute(
        """INSERT INTO loans (book_id, member_id, loan_date, due_date, status)
           VALUES (?, ?, ?, ?, 'checked_out')""",
        (book_id, member_id, loan_date, due_date),
    )
    conn.execute(
        "UPDATE books SET available_copies = available_copies - 1 WHERE book_id = ?",
        (book_id,),
    )
    conn.commit()
    print(f"'{book['title']}' checked out to {member['first_name']} {member['last_name']}. "
          f"Due back {due_date}.")


def return_book(conn):
    print("\n-- Return a book --")
    rows = conn.execute(
        """SELECT l.loan_id, b.title, m.first_name || ' ' || m.last_name AS member, l.due_date
           FROM loans l
           JOIN books b ON b.book_id = l.book_id
           JOIN members m ON m.member_id = l.member_id
           WHERE l.status IN ('checked_out', 'overdue')"""
    ).fetchall()
    if not rows:
        print("No books currently checked out.")
        return
    for r in rows:
        print(f"  [{r['loan_id']}] {r['title']} — {r['member']} (due {r['due_date']})")
    loan_id = int(input("Loan ID to return (0 to cancel): ").strip())
    if loan_id == 0:
        return

    loan = conn.execute("SELECT * FROM loans WHERE loan_id = ?", (loan_id,)).fetchone()
    if not loan:
        print("No such loan.")
        return

    return_date = datetime.now().strftime("%Y-%m-%d")
    conn.execute(
        "UPDATE loans SET return_date = ?, status = 'returned' WHERE loan_id = ?",
        (return_date, loan_id),
    )
    conn.execute(
        "UPDATE books SET available_copies = available_copies + 1 WHERE book_id = ?",
        (loan["book_id"],),
    )
    conn.commit()
    print("Book returned. Thanks!")


def overdue_report(conn):
    print("\n-- Overdue books --")
    rows = conn.execute(
        """SELECT b.title, m.first_name || ' ' || m.last_name AS member, l.due_date
           FROM loans l
           JOIN books b ON b.book_id = l.book_id
           JOIN members m ON m.member_id = l.member_id
           WHERE l.return_date IS NULL AND l.due_date < date('now')
           ORDER BY l.due_date"""
    ).fetchall()
    if not rows:
        print("Nothing overdue right now.")
        return
    for r in rows:
        print(f"  {r['title']:<24} borrowed by {r['member']:<18} was due {r['due_date']}")


def category_report(conn):
    print("\n-- Books per category --")
    rows = conn.execute(
        """SELECT c.name AS category, COUNT(b.book_id) AS book_count
           FROM categories c
           LEFT JOIN books b ON b.category_id = c.category_id
           GROUP BY c.name
           ORDER BY book_count DESC"""
    ).fetchall()
    for r in rows:
        print(f"  {r['category']:<20} {r['book_count']} book(s)")


def most_borrowed_report(conn):
    print("\n-- Most borrowed books --")
    rows = conn.execute(
        """SELECT b.title, COUNT(l.loan_id) AS times_borrowed
           FROM loans l
           JOIN books b ON b.book_id = l.book_id
           GROUP BY b.title
           ORDER BY times_borrowed DESC"""
    ).fetchall()
    for r in rows:
        print(f"  {r['title']:<24} borrowed {r['times_borrowed']} time(s)")


# ---------------------------------------------------------------
# Menu
# ---------------------------------------------------------------

MENU = """
========== Library Management System ==========
1. List book catalog
2. Add book
3. Add member
4. Check out a book
5. Return a book
6. Overdue report
7. Books per category
8. Most borrowed books
0. Exit
=================================================
"""


def main_menu():
    if not DB_PATH.exists():
        print("No database found — initializing with sample data...")
        init_db()

    conn = get_connection()
    while True:
        print(MENU)
        choice = input("Choose an option: ").strip()
        if choice == "1":
            list_books(conn)
        elif choice == "2":
            add_book(conn)
        elif choice == "3":
            add_member(conn)
        elif choice == "4":
            checkout_book(conn)
        elif choice == "5":
            return_book(conn)
        elif choice == "6":
            overdue_report(conn)
        elif choice == "7":
            category_report(conn)
        elif choice == "8":
            most_borrowed_report(conn)
        elif choice == "0":
            print("Goodbye!")
            break
        else:
            print("Invalid option, try again.")
    conn.close()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "init":
        if DB_PATH.exists():
            DB_PATH.unlink()
        init_db()
    else:
        main_menu()
