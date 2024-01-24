--q1

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


--q2 

SELECT * from `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`

where end_station_id = 527;

--there are no trips to or from this station (by name of ID), there is no station ID joining on the info or status table, tried to infer by looking at capacity of stands and it doesn't work. Also looked at hash functions and it didn't work. The station has no billing method so does it even exist? Hard to say what to do here, can't find a more detailed data dictionary.


--q3

with trip as (SELECT * FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` 

where trip_id='201710241152031294'),

trip_start_station as (select * from trip

inner join `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` as station_info

on trip.start_station_id = cast(station_info.station_id as int))

select region.name as start_region from trip_start_station

inner join `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` as region

on trip_start_station.region_id = region.region_id;

-- start_region = "Oakland"


--q4

select distinct(c_subscription_type) AS subsciption_type, round(avg(duration_sec/60) over(PARTITION BY c_subscription_type), 2) AS average_journey_time_mins

FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`

where c_subscription_type is not null;



--report view query

SELECT bike_trips.*, 
       start_station_info.region_id as start_region, 
       start_station_info.rental_methods as start_station_rental_methods, 
       start_station_info.capacity as start_station_capacity, 
       start_station_info.has_kiosk as start_station_has_kiosk,
       end_station_info.region_id as end_region, 
       end_station_info.rental_methods as end_station_rental_methods, 
       end_station_info.capacity as end_station_capacity, 
       end_station_info.has_kiosk as end_station_has_kiosk,
       start_region.name as start_region_name,
       end_region.name as end_region_name

FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS bike_trips

JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS start_station_info

ON bike_trips.start_station_id = cast(start_station_info.station_id as int)

JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS end_station_info

ON bike_trips.end_station_id = cast(end_station_info.station_id as int)

JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS start_region

ON start_station_info.region_id = start_region.region_id

JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS end_region

ON end_station_info.region_id = end_region.region_id;







