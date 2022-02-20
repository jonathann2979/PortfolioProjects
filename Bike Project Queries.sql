-- Combine all datasets into a Yearly Data Set
CREATE VIEW yearlyData AS
SELECT * FROM dbo.january2021
UNION
SELECT * FROM dbo.february2021
UNION
SELECT * FROM dbo.march2021
UNION
SELECT * FROM dbo.april2021
UNION
SELECT * FROM dbo.may2021
UNION
SELECT * FROM dbo.june2021
UNION
SELECT * FROM dbo.july2021
UNION
SELECT * FROM dbo.august2021
UNION
SELECT * FROM dbo.september2021
UNION
SELECT * FROM dbo.october2021
UNION
SELECT * FROM dbo.november2021
UNION
SELECT * FROM dbo.december2021

--Alter column table data types based off 'dbo.january2021'
ALTER TABLE dbo.february2021
ALTER COLUMN end_station_name nvarchar(255)

--Remove null values based on the columns
CREATE VIEW removedNull AS  
SELECT *
FROM yearlyData
WHERE start_station_name IS NOT NULL
	AND start_station_id IS NOT NULL
		AND end_station_name IS NOT NULL
			AND end_station_id IS NOT NULL
				AND start_station_name NOT LIKE '351';

--Create an aggregated table with values needed
CREATE VIEW aggregatedData AS
SELECT *, DATEDIFF(minute,started_at,ended_at) AS LengthMinutes, 
	CASE
		WHEN day_of_week = 1 THEN 'Monday'
		WHEN day_of_week = 2 THEN 'Tuesday'
		WHEN day_of_week = 3 THEN 'Wednesday'
		WHEN day_of_week = 4 THEN 'Thursday'
		WHEN day_of_week = 5 THEN 'Friday'
		WHEN day_of_week = 6 THEN 'Saturday'
	ELSE
		'Sunday'
	END AS DayOfWeek
FROM removedNull

--Fix the ride_id length and drop values with less than 1 minute
CREATE VIEW cleanedRideID AS
SELECT *
FROM aggregatedData
WHERE LEN(ride_id) = 16 AND LengthMinutes >= 1;

--Create clean station names column
CREATE VIEW clean_start_station_name AS
SELECT ride_id, TRIM(REPLACE (REPLACE (start_station_name, '*', ''), '(TEMP)', '')) AS start_station_name_clean
FROM cleanedRideID

CREATE VIEW clean_end_station_name AS
SELECT ride_id, TRIM(REPLACE (REPLACE (end_station_name, '*', ''), '(TEMP)', '')) AS end_station_name_clean
FROM cleanedRideID

CREATE VIEW clean_station_names AS
SELECT s.ride_id, s.start_station_name_clean,e.end_station_name_clean
FROM clean_start_station_name s
JOIN clean_end_station_name e
	ON s.ride_id = e.ride_id;

--Create one large aggregated table with columns needed for analysis
CREATE VIEW FinalTable AS
SELECT A.ride_id, A.rideable_type, A.member_casual, A.DayOfWeek, CAST(A.started_at AS Date) AS DateOfYear, A.ended_at, A.LengthMinutes, C.start_station_name_clean, C.end_station_name_clean, A.start_lat, A.start_lng, A.end_lat, A.end_lng
FROM aggregatedData AS A
JOIN clean_station_names AS C
	ON A.ride_id = C.ride_id;

--Get the number of casual/members at initial starting stations
CREATE VIEW casual_Department AS
SELECT TOP 5 start_station_name_clean, COUNT(member_casual) AS Casual
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY start_station_name_clean

CREATE VIEW member_Department AS
SELECT start_station_name_clean, COUNT(member_casual) AS Member
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY start_station_name_clean

--Get the number of casual/members at final ending locations
CREATE VIEW Casual_End_Station_Count AS
SELECT end_station_name_clean, COUNT(member_casual) AS CasualEnd
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY end_station_name_clean

CREATE VIEW Member_End_Station_Count AS
SELECT end_station_name_clean, COUNT(member_casual) AS MemberEnd
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY end_station_name_clean

--Get the exact coordinate of the Stations
CREATE VIEW Casual_InitialLocation AS
SELECT DISTINCT start_station_name_clean, ROUND(AVG(start_lat),4) AS initial_lat, ROUND(AVG(start_lng),4) AS initial_lng
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY start_station_name_clean

CREATE VIEW Member_InitialLocation AS
SELECT DISTINCT start_station_name_clean, ROUND(AVG(start_lat),4) AS start_lat, ROUND(AVG(start_lng),4) AS start_lng
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY start_station_name_clean

CREATE VIEW Casual_EndingLocation AS
SELECT DISTINCT end_station_name_clean, ROUND(AVG(end_lat),4) AS end_lat, ROUND(AVG(end_lng),4) AS end_lng
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY end_station_name_clean

CREATE VIEW Member_EndingLocation AS
SELECT DISTINCT end_station_name_clean, ROUND(AVG(end_lat),4) AS end_lat, ROUND(AVG(end_lng),4) AS end_lng
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY end_station_name_clean

-- Generate a list of the top 5 initial/final locations for both casual and members
CREATE VIEW Casual_InitialTop5 AS
SELECT TOP 5 start_station_name_clean, COUNT(start_station_name_clean) AS Top_5_Start_Stations
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY start_station_name_clean 
ORDER BY Top_5_Start_stations DESC

CREATE VIEW Member_InitialTop5 AS
SELECT TOP 5 start_station_name_clean, COUNT(start_station_name_clean) AS Top_5_Start_Stations
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY start_station_name_clean
ORDER BY  Top_5_Start_Stations DESC

CREATE VIEW Casual_FinalTop5 AS
SELECT TOP 5 end_station_name_clean, COUNT(end_station_name_clean) AS Top_5_End_Stations
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY end_station_name_clean 
ORDER BY Top_5_End_stations DESC

CREATE VIEW Member_FinalTop5 AS
SELECT TOP 5 end_station_name_clean, COUNT(end_station_name_clean) AS Top_5_End_Stations
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY end_station_name_clean 
ORDER BY Top_5_End_stations DESC

--Get the count of total casual/member riders for each individual date and compare the entire year

CREATE VIEW Year_Casual AS
SELECT DateOfYear, COUNT(member_casual) AS Casual_Count
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY DateOfYear

CREATE VIEW Year_Member AS
SELECT DateOfYear, COUNT(member_casual) AS Member_Count
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY DateOfYear

--Get the count of casual/member riders per day

CREATE VIEW Casual_Week_Count AS
SELECT DayOfWeek, COUNT(member_casual) AS Casual_Count_Week
FROM FinalTable
WHERE member_casual = 'casual'
GROUP BY DayOfWeek

CREATE VIEW Member_Week_Count AS
SELECT DayOfWeek, COUNT(member_casual) AS Member_Count_Week
FROM FinalTable
WHERE member_casual = 'member'
GROUP BY DayOfWeek

--Organize how much time each member rides

CREATE VIEW AverageRideTime AS
SELECT member_casual, AVG(LengthMinutes) AS Casual_minutes
FROM FinalTable
GROUP BY member_casual

--Get the ratio of casual riders to member riders
CREATE VIEW RiderRatio AS
SELECT member_casual, COUNT(member_casual) AS Rider_Ratio
FROM FinalTable
GROUP BY member_casual;
