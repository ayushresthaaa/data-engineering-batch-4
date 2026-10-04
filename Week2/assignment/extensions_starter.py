"""
extensions.py
─────────────
P1: parameterized query function
P2: generic table printer (cursor.description)
P3: handle a bad insert gracefully (FK violation + rollback)
"""

import os

import psycopg2
from dotenv import load_dotenv


def get_connection():
    load_dotenv()
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )


# ── P1: parameterized query function ──────────────────────────────────────
def get_rides_for_driver(cur, driver_name):
    """Return every trip for the given driver name (case-insensitive)."""
    query = """
        SELECT 
            t.trip_id,
            d.name AS driver_name,
            p.name AS passenger_name,
            t.fare_amount,
            t.status,
            t.requested_at
        FROM trips t
        JOIN drivers d ON t.driver_id = d.driver_id
        JOIN passengers p ON t.passenger_id = p.passenger_id
        WHERE LOWER(d.name) = LOWER(%s);
    """ #the %s is a placeholder for the parameterized query 
    cur.execute(query, (driver_name,))
    return cur.fetchall() #fetchall() returns all the rows from the executed query as a list of tuples 


# ── P2: generic table printer ─────────────────────────────────────────────
def run_and_print(cur, sql):
    cur.execute(sql) 
    rows = cur.fetchall() 

    headers = [desc[0] for desc in cur.description] #cur.description returns a list of tuples containing metadata about the columns in the result set. Each tuple contains information about a column, and the first element (index 0) is the column name.

    print("\n" + " | ".join(f"{h:<20}" for h in headers))
    print("-" * (23 * len(headers)))

    for row in rows:
        print(" | ".join(f"{str(val):<20}" for val in row))
    print()


# ── P3: handle a bad insert gracefully ────────────────────────────────────
def insert_trip_with_bad_driver(conn):
    """Attempt an INSERT with a driver_id that doesn't exist; recover cleanly."""
    bad_sql = "INSERT INTO trips (driver_id, fare_amount, status) VALUES (999999, 500, 'completed');"

    with conn.cursor() as cur: 
        try: 
            cur.execute(bad_sql) 
            conn.commit()
        except psycopg2.Error as e:
            print(f"\n[P3 Error Caught]: {e.pgerror.strip()}")
            print("Rolling back transaction...")
            conn.rollback()

        cur.execute("SELECT COUNT(*) FROM trips;")
        print(f"Connection recovered cleanly! Driver count: {cur.fetchone()[0]}\n")

def main():
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            # Test P1
            print("\n-- P1: Driver Search --")
            rides = get_rides_for_driver(cur, "Aarav Sharma")
            print(f"Retrieved {len(rides)} rides for Aarav Sharma")

            # Test P2 (3 queries)
            print("\n-- P2 Query 1: Cities --")
            run_and_print(cur, "SELECT location_id, city_name FROM locations LIMIT 5;")

            print("-- P2 Query 2: Drivers --")
            run_and_print(cur, "SELECT driver_id, name FROM drivers LIMIT 5;")

            print("-- P2 Query 3: Status Summary --")
            run_and_print(cur, "SELECT status, COUNT(*) AS count FROM trips GROUP BY status;")

        # Test P3
        insert_trip_with_bad_driver(conn)

    finally:
        conn.close()

if __name__ == "__main__":
    main()
