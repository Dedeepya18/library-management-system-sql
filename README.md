# Library Management System (SQL-based)

A relational-database application for managing a library's catalog,
members, and circulation (checkouts, returns, overdue tracking, and
reservations), with a Python CLI on top so it's a working application.

## Structure

```
library-management/
├── schema.sql        # Table definitions, constraints, indexes
├── sample_data.sql   # Realistic sample data (7 books, 5 members, loan history)
├── queries.sql       # 10 ready-to-use reporting queries
├── app.py            # Python CLI application (uses SQLite)
└── README.md
```

## Data model

- **authors** — book authors
- **categories** — genres/subjects
- **books** — catalog entries (one row per title), tracking
  `total_copies` vs `available_copies`
- **members** — library members with a status (active/suspended/expired)
- **loans** — checkout/return records with loan date, due date, and
  return date
- **reservations** — hold requests for books that are currently
  unavailable

Foreign keys and CHECK constraints enforce integrity — e.g.
`available_copies` can never exceed `total_copies`, and loan/reservation
statuses are restricted to a fixed set of values.

## Running it

Requires Python 3 (uses the built-in `sqlite3` module — no extra installs).

```bash
# Build the database and load sample data
python app.py init

# Launch the interactive menu
python app.py
```

Menu options let you: browse the catalog, add a book, add a member,
check out a book (with a 14-day loan period), return a book, and view
overdue/category/most-borrowed reports. Checking out and returning
automatically update `available_copies`.

## Using the raw SQL

`queries.sql` has 10 queries you can run directly against `library.db`
with any SQLite client (or adapt for Postgres/MySQL) — currently checked
out books, overdue books with days-overdue, most borrowed titles, books
per category, member borrowing history, most active borrowers, and
average loan duration.

```bash
sqlite3 library.db < queries.sql
```

## Porting to Postgres/MySQL

The schema is close to standard SQL. To port:
- Replace `INTEGER PRIMARY KEY AUTOINCREMENT` with `SERIAL PRIMARY KEY` (Postgres)
  or `INT AUTO_INCREMENT PRIMARY KEY` (MySQL)
- Replace `TEXT` date columns with `DATE` types
- `app.py`'s `get_connection()` is the only place that would need a
  different driver (e.g. `psycopg2` or `mysql-connector-python`)

## Possible extensions

- Automatic reservation fulfillment when a reserved book is returned
- Overdue fine calculation
- Email/SMS due-date reminders
- A small Flask/FastAPI layer to turn this into a web app
