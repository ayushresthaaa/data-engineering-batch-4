--Q1: Rides per driver 
-- name, total_rides — completed rides only, ordered by total_rides desc

SELECT 
    d.name,
    COUNT(r.ride_id) AS total_rides
FROM drivers d
JOIN rides r ON d.driver_id = r.driver_id
WHERE r.status = 'completed'
GROUP BY d.driver_id, d.name
ORDER BY total_rides DESC;

--Q2 Drivers with zero completed rides (Intermediate · anti-join)
SELECT 
    d.name 
From drivers d 
Left join rides r on d.driver_id = r.driver_id and r.status = 'completed' 
Where r.ride_id is null;    

--Q3 Average fare per pickup city (Intermediate · 3-table JOIN + AVG) 
SELECT 
    c.name AS city_name,
    ROUND(AVG(r.fare_amount), 2) AS avg_fare --round because the question asks for 2 decimals
FROM rides r
JOIN locations l ON r.pickup_location_id = l.location_id
JOIN cities c ON l.city_id = c.city_id
WHERE r.status = 'completed'
GROUP BY c.city_id, c.name
ORDER BY avg_fare DESC;

--Q4 Same-city driver/passenger trips (Basic–Intermediate · schema thinking)
--Partial query + written explanation (as a comment) of what the schema is missing

SELECT 
    r.ride_id,
    d.name AS driver_name, 
    p.name AS passenger_name,
    c.name AS pickup_city
FROM rides r
JOIN drivers d ON r.driver_id = d.driver_id
JOIN passengers p ON r.passenger_id = p.passenger_id
JOIN locations l ON r.pickup_location_id = l.location_id
JOIN cities c ON l.city_id = c.city_id;

--Q5 Re-run Week 1's revenue query (Basic · verification) 
SELECT SUM(fare_amount) AS total_revenue
FROM trips 
WHERE status = 'completed';

--Q6 WHERE and HAVING, together (Intermediate · WHERE + GROUP BY + HAVING)
SELECT
    d.name,
    COUNT(r.ride_id) AS total_completed_rides,
    SUM(r.fare_amount) AS total_revenue
FROM drivers d
JOIN rides r ON d.driver_id = r.driver_id
WHERE r.status = 'completed'
GROUP BY d.driver_id, d.name
HAVING COUNT(r.ride_id) > 280 AND SUM(r.fare_amount) > 140000;

--Q7 Clean the phone numbers (Intermediate · REGEXP_REPLACE)

create temp table temp_rides as select * from rides;

alter table temp_rides add column phone_number varchar(50);  

UPDATE temp_rides 
SET phone_number = CASE 
    WHEN ride_id % 4 = 0 THEN '+977-980-1234567'
    WHEN ride_id % 4 = 1 THEN ' (9841) 234-567 '
    WHEN ride_id % 4 = 2 THEN '9801234568.'
    ELSE '+977 981 999-0000'
END;

SELECT 
    ride_id,
    phone_number AS raw_phone_number,
    REGEXP_REPLACE(
        REGEXP_REPLACE(phone_number, '[^0-9]', '', 'g'), 
        '^977', ''
    ) AS cleaned_phone_number
FROM temp_rides;

--Q8 Prove the city data is clean (Intermediate · STRPOS / ILIKE)
select 
    city_id, 
    name
from cities
where strpos(lower(name), 'kathmandu') > 0 
    or strpos(lower(name), 'pokhara') > 0;

-- the above query means that the city name contains kathmandu or pokhara, regardless of case.

SELECT 
    city_id, 
    name 
FROM cities 
WHERE name ILIKE '%kathmandu%' 
   OR name ILIKE '%pokhara%';

-- Q9 — Self-join: drivers who overlapped (Advanced · self-join + date functions)
-- Pairs of different drivers, same pickup location, same calendar day
-- question means that the pickup location is the same and the pickup date is the same, but the drivers are different.
SELECT DISTINCT
    t1.driver_id AS driver_1_id,
    d1.name AS driver_1_name,
    t2.driver_id AS driver_2_id,
    d2.name AS driver_2_name,
    t1.pickup_location_id,
    DATE(t1.requested_at) AS ride_date
FROM trips t1
JOIN trips t2 
    ON t1.pickup_location_id = t2.pickup_location_id
   AND DATE(t1.requested_at) = DATE(t2.requested_at)
   AND t1.driver_id < t2.driver_id
JOIN drivers d1 ON t1.driver_id = d1.driver_id
JOIN drivers d2 ON t2.driver_id = d2.driver_id
ORDER BY ride_date, t1.pickup_location_id;

--Q10: promo codes 
-- adding columns into the trips table to store promo code information, and then populating it with sample data, causes redundancies and data anomalies causing duplicates 
-- it also violates 2nf and 3nf because the attributes like discount rate depend on the promo code, not on the trip itself.
-- maintaenance is heavy as updating promo code information would require updating multiple rows in the trips table, which is not efficient and can lead to inconsistencies. 

-- approach 
-- CREATE TABLE promo_codes (
--     promo_code_id       SERIAL PRIMARY KEY,
--     code                VARCHAR(50) UNIQUE NOT NULL, 
--     discount_type       VARCHAR(20) NOT NULL,
--     discount_value      NUMERIC(10,2) NOT NULL,      
--     max_discount_amount NUMERIC(10,2),               
--     usage_limit         INTEGER,                     
--     valid_from          TIMESTAMP NOT NULL,
--     valid_until         TIMESTAMP NOT NULL
-- );

-- ALTER TABLE trips 
-- ADD COLUMN promo_code_id INTEGER REFERENCES promo_codes(promo_code_id),
-- ADD COLUMN discount_applied NUMERIC(10,2) DEFAULT 0.00;

--discount applied on trips because locks in historical financial snapshot.