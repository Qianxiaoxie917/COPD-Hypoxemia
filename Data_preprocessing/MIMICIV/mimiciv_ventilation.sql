WITH vd0 AS (

SELECT *, 

CASE WHEN ventilation_status = 'SupplementalOxygen' OR ventilation_status = 'HFNC' THEN 0 ELSE 1 END as vent_status,
DATETIME_DIFF(endtime, starttime, hour) AS vent_d0

FROM oxgenator.mimiciv_derived.ventilation 

WHERE ventilation_status <> 'None' 


),

--Create a column that indicate the change of ventilation type (ventilated or non-ventilated)
vd1 AS (

SELECT *, 
CASE WHEN vent_status != LAG(vent_status) OVER (PARTITION BY stay_id ORDER BY starttime) 
THEN 1 ELSE 0 END as flagchange,

FROM vd0

),

--Create a cloumn that aggregate the flag change 
vd2 AS (

SELECT *, SUM(CASE WHEN flagchange = 1 THEN 1 ELSE 0 END) 
       OVER(PARTITION BY stay_id ORDER BY starttime) as flaggroup
FROM vd1


)

--Create the column for vent duration and related start time and end time
SELECT stay_id, MIN(starttime) AS initial_time, MAX(endtime) AS end_time, SUM(vent_d0)  AS vent_duration, MIN(ventilation_status) AS ventialtion_status, MIN(vent_status) AS vent_status
FROM vd2
WHERE flaggroup = 0
GROUP BY stay_id 







