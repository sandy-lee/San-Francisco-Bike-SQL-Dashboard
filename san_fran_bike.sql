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
--use for the dashboard. Views are more secure, easier to maintain and  moreperformant for this type 
--of work.

--report view query

SELECT 
    bike_trips.*, 
    start_station_info.region_id AS start_region, 
    start_station_info.rental_methods AS start_station_rental_methods, 
    start_station_info.capacity AS start_station_capacity, 
    start_station_info.has_kiosk AS start_station_has_kiosk,
    end_station_info.region_id AS end_region, 
    end_station_info.rental_methods AS end_station_rental_methods, 
    end_station_info.capacity AS end_station_capacity, 
    end_station_info.has_kiosk AS end_station_has_kiosk,
    start_region.name AS start_region_name,
    end_region.name AS end_region_name
FROM 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS bike_trips
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS start_station_info
ON 
    bike_trips.start_station_id = cast(start_station_info.station_id AS INT)
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS end_station_info
ON 
    bike_trips.end_station_id = cast(end_station_info.station_id AS INT)
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS start_region
ON 
    start_station_info.region_id = start_region.region_id
JOIN 
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS end_region
ON 
    end_station_info.region_id = end_region.region_id;







