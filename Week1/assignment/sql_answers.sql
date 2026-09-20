-- Week 1 SQL Assignment — Answers
-- Fill in each query below. See sql_assignment.md for the full scenario text.
-- Rename this file to sql_answers.sql before committing.


-- Q1 — Kathmandu to Pokhara (Basic · DQL)
-- Completed rides from Kathmandu to Pokhara: ride_id, driver_name, passenger_name, fare_amount
-- answer: 
select
	ride_id,
	driver_name,
	passenger_name,
	fare_amount
from
	rides
where
	trim(pickup_city) = 'Kathmandu'
	and trim(dropoff_city) = 'Pokhara'
	and ride_status = 'completed'
order by
	ride_id ; 



-- Q2 — Top 5 highest fares (Basic · DQL)
-- driver_name, passenger_name, fare_amount — 5 highest fares, descending
-- asnwer: 
select
	driver_name,
	passenger_name,
	fare_amount
from
	rides
order by
	fare_amount desc
limit 5; 


-- Q3 — The "Shrestha" complaint (Basic · DQL)
-- Every ride where driver_name contains "shrestha", case-insensitive
-- answer:
select
	driver_name,
	passenger_name,
	fare_amount
from
	rides
order by
	fare_amount desc
limit 5; 


-- Q4 — How many rides were never rated? (Basic–Intermediate · NULL)
-- One query returning: total_rides, rated_rides, unrated_rides
-- answer:
select
	count(*) as total_rides,
	count(rating) as rated_rides,
	count(*) - count(rating) as unrated_rides
from
	rides;


-- Q5 — Every ride that wasn't paid in cash (Intermediate · NULL)
-- ride_id, driver_name, payment_method — not cash, including unrecorded payment methods
-- answer:
select
	*
from
	rides
where
	payment_method <> 'cash'
	or payment_method is null; 


-- Q6 — Revenue by pickup city (Intermediate · Aggregation)
-- pickup_city, total_rides, total_revenue, avg_fare (2 decimals) — sorted by total_revenue desc
-- answer: 
select
	pickup_city,
	count(*) as total_rides,
	sum(fare_amount) as total_revenue,
	ROUND(AVG(fare_amount)::numeric, 2) as avg_fare
from
	rides
group by
	pickup_city
order by
	sum(fare_amount) desc; 


-- Q7 — Ride outcomes by status (Intermediate · Aggregation)
-- ride_status, ride_count, avg_distance_km (2 decimals) — sorted by ride_count desc
-- asnwer: 
select
	ride_status,
	count(*) as ride_count,
	round(avg(ride_distance_km)::numeric, 2) as avg_distance_km
from
	rides
group by
	ride_status
order by
	ride_count desc;


-- Q8 — A new driver's first ride (Basic–Intermediate · DML)
-- 8a. INSERT the new ride (ride_id 9001, rating NULL)
--Insertion into new ride 
INSERT INTO rides (
    ride_id, 
    driver_name, 
    passenger_name, 
    pickup_city, 
    dropoff_city, 
    fare_amount, 
    ride_distance_km, 
    ride_status, 
    requested_at, 
    completed_at, 
    rating, 
    payment_method
) 
VALUES (
    9001, 
    'Aarav Sharma', 
    'Sita Gurung', 
    'Kathmandu', 
    'Lalitpur', 
    350.00, 
    6.50, 
    'completed', 
    '2026-09-20 08:30:00', 
    '2026-09-20 09:00:00', 
    NULL, 
    'eSewa'
);


-- 8b. UPDATE the rating to 4.8 for ride_id 9001
-- answer:
update rides 
set rating = 4.8 
where ride_id = 9001; 


-- Q9 — Locking down payment methods (Intermediate · DDL)
-- 9a. ALTER TABLE to restrict payment_method to a fixed set of values
-- answer: 
select distinct(payment_method) from rides;

ALTER TABLE rides DROP CONSTRAINT IF EXISTS payment_method_constraint;

update rides 
set payment_method = null 
where payment_method = '' or trim(payment_method ) = ''; 

UPDATE rides 
SET payment_method = LOWER(TRIM(payment_method)) 
WHERE payment_method IS NOT NULL;

ALTER TABLE rides 
ADD CONSTRAINT payment_method_constraint 
CHECK (payment_method IN ('cash', 'esewa', 'khalti', 'card', 'wallet') OR payment_method IS NULL);



-- 9b. INSERT using an invalid payment method — note the error you'd expect in a comment

INSERT INTO rides (
    ride_id, 
    driver_name, 
    passenger_name, 
    pickup_city, 
    dropoff_city, 
    fare_amount, 
    ride_distance_km, 
    ride_status, 
    requested_at, 
    completed_at, 
    rating, 
    payment_method
) 
VALUES (
    9001, 
    'Aarav Sharma', 
    'Sita Gurung', 
    'Kathmandu', 
    'Lalitpur', 
    350.00, 
    6.50, 
    'completed', 
    '2026-09-20 08:30:00', 
    '2026-09-20 09:00:00', 
    NULL, 
    'fonepay'
);
-- error expected: violation of constraint 
-- gotten error :  
  --SQL Error [23514]: ERROR: new row for relation "rides" violates check constraint "payment_method_constraint"
  -- Detail: Failing row contains (9001, Aarav Sharma, Sita Gurung, Kathmandu, Lalitpur, 350.00, 6.50, completed, 2026-09-20 08:30:00, 2026-09-20 09:00:00, null, fonepay).


-- Q10 — Rides priced above the platform average (Basic · Subquery)
-- ride_id, driver_name, fare_amount — fare_amount above the average of ALL rides (via subquery)


select
	ride_id,
	driver_name,
	fare_amount
from
	rides
where
	fare_amount >(
	select
		avg(fare_amount)
	from
		rides)
order by
	fare_amount; 