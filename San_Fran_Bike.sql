--#Section 1 (SQL Questions)

--Q1 How many trips, longer than 5 minutes, started at the station “Berry St at 4th St” in January 2018?

SELECT
    COUNT(trip_id) AS total_trips
FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE
    duration_sec > 300
AND 
    start_station_name = 'Berry St at 4th St'
AND 
    DATE(start_date) BETWEEN DATE(2018,1,1) AND DATE(2018,1,31)

--total trips = 1922

--------------------------------------------------------------------------------------------------------
--Q2 How many bikes are available at the station “Tehama St at 1st St”?

--It isn't possible to tell this from the data and additional context/domain knowledge from the product
--owner would be required.

--the logical way of doing this would be to do a join on the the station_id across the station_info 
--table and the station_status table thusly:

SELECT 
    * 
FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS station_info
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_status` AS station_status
ON 
    station_info.station_id = station_status.station_id;

--no data

--no data is returned because no constraint exists and these keys are different (I tried hashes of 
--various column names and couldn't get a match). In addition, the status table seems to serve a 
--different purpose to the other tables as it is used to keep track of live stations in the back end.

--Looking for evidence of activity at this station in the trips table thusly:

SELECT 
    * 
FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE 
    start_station_name = "Tehama St at 1st St" 
OR 
    end_station_name = "Tehama St at 1st St";

--no data

--it seems that there is no activity for this station in the whole data set, and the same is true when 
--looking for the station_id. 

--when looking at the station record in the info table we see:

SELECT 
    * 
FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
WHERE 
    name = "Tehama St at 1st St";

--there is a lot data about the station, but it is not clear if it is live or not. For example, there 
--are 39 spaces for bikes, it has a kiosk, but there are no rental methods listed. As noted above
--more domain knowledge/context from the product owner would be needed to explain what this means.

--Possible causes could be the station is new, its name has changed or there is an issues in the data
--that needs further investigation.
--------------------------------------------------------------------------------------------------------
--Q3 Which region did the trip ID “201710241152031294” start in?

WITH trip AS 
    (SELECT 
        * 
    FROM 
        `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` 
    WHERE trip_id='201710241152031294'),

    trip_start_station AS 
    (SELECT 
        * 
    FROM 
        trip
    JOIN 
        `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS station_info
    ON 
        trip.start_station_id = cast(station_info.station_id AS INT))

SELECT 
    region.name AS start_region 
FROM
    trip_start_station
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS region
ON 
    trip_start_station.region_id = region.region_id;

-- start_region = "Oakland"
--------------------------------------------------------------------------------------------------------
--Q4 Do people with a subscription type = ‘Subscriber’ (c_subscription_type = ‘Subscriber’) travel for 
--longer, or shorter, than those with a subscription type = ‘Customer’?

SELECT
    DISTINCT(c_subscription_type) AS subsciption_type, round(avg(duration_sec/60) 
OVER
    (PARTITION BY c_subscription_type), 2) AS average_journey_time_mins
FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE
    c_subscription_type is not null;

--subsciption_type    average_journey_time_mins
--Subscriber          9.71
--Customer            61.98

--People with the subscription type 'Subscriber' on average travel nearly 50 minutes less than a person
--who is a 'Customer'.
--------------------------------------------------------------------------------------------------------
--#Section 2 (Insights & Visualisation)

--The following query is used to build a view with all of the information in it that Power BI needs to 
--use for the dashboard. Views are more secure, easier to maintain and  more performant for this type 
--of work.

--There are a lot of ways to slice this data, and I chose to look at space and time to of journey starts
--as that is likely to show some interest insights. It would have also been possible to look at journey
--completions or routes or to study user behaviour (cohort analysis etc) - there are a lot of ways this
--could be done and I wanted to narrow it down. One issue with the latitudes and longitudes is that about
--45% of the data has longitude and latitude missing. I wrote a script in Python to get the missing data
--from Google Maps and imputed into the view so this will give a more accurate picture. We can discuss 
--the rationale behind my other design choices during the interview.

--report view query

WITH days AS
(SELECT
    trip_id, 
    CASE WHEN EXTRACT(DAYOFWEEK from start_date) = 1 THEN 'Sunday'
         WHEN EXTRACT(DAYOFWEEK from start_date) = 2 THEN 'Monday'
         WHEN EXTRACT(DAYOFWEEK from start_date) = 3 THEN 'Tuesday'
         WHEN EXTRACT(DAYOFWEEK from start_date) = 4 THEN 'Wednesday'
         WHEN EXTRACT(DAYOFWEEK from start_date) = 5 THEN 'Thursday'
         WHEN EXTRACT(DAYOFWEEK from start_date) = 6 THEN 'Friday'
         WHEN EXTRACT(DAYOFWEEK from start_date) = 7 THEN 'Saturday' END AS day_of_week
FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`),

months AS 
(SELECT
    trip_id,
    CASE WHEN EXTRACT(MONTH from start_date) = 1 THEN 'January'
         WHEN EXTRACT(MONTH from start_date) = 2 THEN 'February'
         WHEN EXTRACT(MONTH from start_date) = 3 THEN 'March'
         WHEN EXTRACT(MONTH from start_date) = 4 THEN 'April'
         WHEN EXTRACT(MONTH from start_date) = 5 THEN 'May'
         WHEN EXTRACT(MONTH from start_date) = 6 THEN 'June'
         WHEN EXTRACT(MONTH from start_date) = 7 THEN 'July'
         WHEN EXTRACT(MONTH from start_date) = 8 THEN 'August' 
         WHEN EXTRACT(MONTH from start_date) = 9 THEN 'September'
         WHEN EXTRACT(MONTH from start_date) = 10 THEN 'October'
         WHEN EXTRACT(MONTH from start_date) = 11 THEN 'November'
         WHEN EXTRACT(MONTH from start_date) = 12 THEN 'December' END AS month_of_year
FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`),

hours AS 
(SELECT
    trip_id,
    CASE WHEN EXTRACT(HOUR FROM start_date) = 1 THEN '1am'
         WHEN EXTRACT(HOUR FROM start_date) = 2 THEN '2am'
         WHEN EXTRACT(HOUR FROM start_date) = 3 THEN '3am'
         WHEN EXTRACT(HOUR FROM start_date) = 4 THEN '4am'
         WHEN EXTRACT(HOUR FROM start_date) = 5 THEN '5am'
         WHEN EXTRACT(HOUR FROM start_date) = 6 THEN '6am'
         WHEN EXTRACT(HOUR FROM start_date) = 7 THEN '7am'
         WHEN EXTRACT(HOUR FROM start_date) = 8 THEN '8am'
         WHEN EXTRACT(HOUR FROM start_date) = 9 THEN '9am'
         WHEN EXTRACT(HOUR FROM start_date) = 10 THEN '10am'
         WHEN EXTRACT(HOUR FROM start_date) = 11 THEN '11am'
         WHEN EXTRACT(HOUR FROM start_date) = 12 THEN '12pm'
         WHEN EXTRACT(HOUR FROM start_date) = 13 THEN '1pm'
         WHEN EXTRACT(HOUR FROM start_date) = 14 THEN '2pm'
         WHEN EXTRACT(HOUR FROM start_date) = 15 THEN '3pm'
         WHEN EXTRACT(HOUR FROM start_date) = 16 THEN '4pm'
         WHEN EXTRACT(HOUR FROM start_date) = 17 THEN '5pm'
         WHEN EXTRACT(HOUR FROM start_date) = 18 THEN '6pm'
         WHEN EXTRACT(HOUR FROM start_date) = 19 THEN '7pm'
         WHEN EXTRACT(HOUR FROM start_date) = 20 THEN '8pm'
         WHEN EXTRACT(HOUR FROM start_date) = 21 THEN '9pm'
         WHEN EXTRACT(HOUR FROM start_date) = 22 THEN '10pm'
         WHEN EXTRACT(HOUR FROM start_date) = 23 THEN '11pm'
         WHEN EXTRACT(HOUR FROM start_date) = 0 THEN '12am' END as time_of_day
FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`)

SELECT 
    bike_trips.* EXCEPT(end_date, 
                        end_station_name, 
                        end_station_id, 
                        end_station_latitude, 
                        end_station_longitude, 
                        end_station_geom, 
                        zip_code, 
                        subscriber_type, 
                        c_subscription_type, 
                        member_birth_year, 
                        member_gender, 
                        bike_share_for_all_trip,
                        start_station_geom), 
    start_station_info.region_id AS start_region, 
    start_station_info.capacity AS start_station_capacity, 
    start_station_info.has_kiosk AS start_station_has_kiosk,
    start_region.name AS start_region_name,
    round(duration_sec/60, 2) AS duration_min,
    EXTRACT(YEAR from start_date) AS year,
    days.day_of_week,
    months.month_of_year,
    hours.time_of_day,
    ifnull(bike_trips.start_station_latitude, imputation_table.start_station_latitude) AS imputed_start_station_latitude,
    ifnull(bike_trips.start_station_longitude, imputation_table.start_station_longitude) AS imputed_start_station_longitude
FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS bike_trips
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS start_station_info
ON 
    bike_trips.start_station_id = cast(start_station_info.station_id AS INT)
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS start_region
ON 
    start_station_info.region_id = start_region.region_id
JOIN 
    days
ON 
    bike_trips.trip_id = days.trip_id
JOIN 
    months
ON 
    bike_trips.trip_id = months.trip_id
JOIN 
    hours
ON 
    bike_trips.trip_id = hours.trip_id
LEFT JOIN 
    `warm-braid-392619.kingfisher_san_fran_bike.missing_stations_lat_lng` AS imputation_table
ON
    bike_trips.start_station_name = imputation_table.start_station_name
    