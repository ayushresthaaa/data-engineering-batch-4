--Week 2 Assignment: Answers
-- Step 1: CREATE TABLE statements, in dependency order

DROP TABLE IF EXISTS trips; 
DROP TABLE IF EXISTS payment_methods; 
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS drivers;
DROP TABLE IF EXISTS passengers; 
CREATE TABLE locations (
    location_id   SERIAL        PRIMARY KEY,
    city_name     VARCHAR(100)  NOT NULL UNIQUE
);

CREATE TABLE drivers (
    driver_id     SERIAL        PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL
);

CREATE TABLE passengers (
    passenger_id  SERIAL        PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL
);

CREATE TABLE payment_methods (
    payment_method_id SERIAL       PRIMARY KEY,
    name               VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE trips (
    trip_id              SERIAL        PRIMARY KEY,
    driver_id            INTEGER       NOT NULL REFERENCES drivers(driver_id),
    passenger_id         INTEGER       NOT NULL REFERENCES passengers(passenger_id),
    pickup_location_id   INTEGER       NOT NULL REFERENCES locations(location_id),
    dropoff_location_id  INTEGER       NOT NULL REFERENCES locations(location_id),
    fare_amount          NUMERIC(10,2) NOT NULL CHECK (fare_amount > 0),
    distance_km           NUMERIC(6,2)  NOT NULL,
    status                VARCHAR(50)   NOT NULL CHECK (status IN ('completed','cancelled','no_show')),
    requested_at          TIMESTAMP     NOT NULL,
    completed_at          TIMESTAMP,
    rating                NUMERIC(2,1)  CHECK (rating BETWEEN 1.0 AND 5.0),
    payment_method_id     INTEGER       REFERENCES payment_methods(payment_method_id)
);

--Step 2: Populate drives and passengers (INSERT ... SELECT DISTINCT ... FROM rides, cleaned names)
INSERT INTO drivers (name) 
SELECT DISTINCT INITCAP(TRIM(REGEXP_REPLACE(driver_name, '\s+', ' ', 'g'))) 
FROM rides; 

INSERT INTO passengers (name) 
SELECT DISTINCT INITCAP(TRIM(REGEXP_REPLACE(passenger_name, '\s+', ' ', 'g'))) 
FROM rides;  

--Step 3: Populate locations (UNION of pickup_city and dropoff_city, from rides) 
INSERT INTO locations (city_name) 
SELECT DISTINCT INITCAP(TRIM(REGEXP_REPLACE(pickup_city, '\s+', ' ', 'g')))
UNION 
SELECT DISTINCT INITCAP(TRIM(REGEXP_REPLACE(dropoff_city, '\s+', ' ', 'g'))) 
FROM rides; 

--Step 4: Populate payment_methods (UNION of payment_method, from rides)
INSERT INTO payment_methods (name)
SELECT DISTINCT payment_method
FROM rides
WHERE payment_method IS NOT NULL and payment_method <> '';

--Step 5: Populate trips (INSERT ... SELECT ... FROM rides, using JOINs to get IDs) 
INSERT INTO trips(
    driver_id,
    passenger_id,
    pickup_location_id,
    dropoff_location_id,
    fare_amount,
    distance_km,
    status,
    requested_at,
    completed_at,
    rating,
    payment_method_id
)
SELECT 
(SELECT driver_id FROM drivers WHERE name = INITCAP(TRIM(REGEXP_REPLACE(r.driver_name, '\s+', ' ', 'g') ))) AS driver_id,
(SELECT passenger_id FROM passengers WHERE name = INITCAP(TRIM(REGEXP_REPLACE(r.passenger_name, '\s+', ' ', 'g') ))) AS passenger_id,
(SELECT location_id FROM locations WHERE city_name = INITCAP(TRIM(REGEXP_REPLACE(r.pickup_city, '\s+', ' ', 'g') ))) AS pickup_location_id,
(SELECT location_id FROM locations WHERE city_name = INITCAP(TRIM(REGEXP_REPLACE(r.dropoff_city, '\s+', ' ', 'g') ))) AS dropoff_location_id,
r.fare_amount,
r.distance_km,
r.status,
r.requested_at,
r.completed_at,
r.rating,
(SELECT payment_method_id FROM payment_methods WHERE name = r.payment_method) AS payment_method_id
FROM rides r;

--Step 6: Verification query — COUNT(*) FROM trips should equal COUNT(*) FROM rides
SELECT 
    (SELECT COUNT(*) FROM trips) AS trips_count,
    (SELECT COUNT(*) FROM rides) AS rides_count;

--Step 7: Manually insert one driver with no matching trip (needed for Q2)
INSERT INTO drivers (name) VALUES ('Aayush Shrestha');