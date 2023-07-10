WITH Od0 AS (
SELECT *, MIN(charttime) OVER (PARTITION BY icustay_id ORDER BY charttime) AS initial_time,
charttime - MIN(charttime) OVER (PARTITION BY icustay_id ORDER BY charttime) AS time_diff,
CASE WHEN oxygen_therapy_type IN (-1, 1, 0) THEN 0
ELSE 1 END AS ventilation
FROM oxgenator.eicu.oxygen_therapy

),

--Select the subset with all oxygen therapy type as 0, -1
Oxygen_dat0 AS (

SELECT *
FROM (
  SELECT *
  FROM Od0
  WHERE icustay_id NOT IN (
    SELECT icustay_id
    FROM Od0
    WHERE oxygen_therapy_type NOT IN (0, -1)
    GROUP BY icustay_id
  )
) temp
WHERE RN = 1

),

--Select the subset initiating with oxygen therapy type as 1, 2, 3, 4
Oxygen_dat1 AS (

SELECT *
FROM Od0
WHERE RN = 1 AND oxygen_therapy_type IN (1, 2, 3, 4)

),

--Classify unknown oxygen therapy type as -1, 0
--Select the subset initiating with oxygen therapy type as -1, 0 but not all 
Oxygen_tmp AS (

SELECT *
FROM Od0
WHERE RN = 1 AND oxygen_therapy_type IN (-1, 0) 
      AND icustay_id NOT IN (SELECT icustay_id FROM Oxygen_dat0)

),


--Select the records within 24 hours from the subset Oxygen_dat2
Od1 AS (

SELECT *
FROM Od0
WHERE icustay_id IN (SELECT icustay_id FROM Oxygen_tmp) 


),

--Select from the above records with the first oxygen therapy type > 0 
--While the charttime remain the initial one 
Oxygen_dat2 AS (

SELECT * 
FROM (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY icustay_id ORDER BY charttime) as O_RN
  FROM Od1 
  WHERE oxygen_therapy_type > 0 AND time_diff <= 24*60
) temp
WHERE O_RN = 1


),


--Select the rest with oxygen therapy type remainng as -1, 0 
Oxygen_dat3 AS (

SELECT * 

FROM Od1

WHERE RN =1 AND icustay_id NOT IN (SELECT icustay_id FROM  Oxygen_dat2)

),


---Combining all together
Oxygen_dat AS (

SELECT * FROM Oxygen_dat0
UNION ALL 
SELECT * FROM Oxygen_dat1
UNION ALL 
SELECT * EXCEPT(O_RN)
FROM Oxygen_dat2
UNION ALL 
SELECT * FROM Oxygen_dat3

),


--Create a column that indicate the change of ventilation type (ventilated or non-ventilated)
Ov0 AS (

SELECT *, CASE WHEN  ventilation != LAG(ventilation) OVER (PARTITION BY icustay_id ORDER BY charttime) 
THEN 1 ELSE 0 END as flagchange
FROM Od0


),

--Create a column that aggregate the flag change 
Ov1 AS (

SELECT *, SUM(CASE WHEN flagchange = 1 THEN 1 ELSE 0 END) 
       OVER(PARTITION BY icustay_id ORDER BY charttime) as flaggroup, 
FROM Ov0


),


--Create the column for vent duration with value of the end time of the first session 
EndTimes AS (
  SELECT icustay_id, MAX(charttime) as EndTime, MAX(time_diff) as duration
  FROM Ov1
  WHERE flaggroup = 0
  GROUP BY icustay_id
)



--Add columns for vent duration and the end time of ventilation
SELECT Od.*,  Et.EndTime  AS end_time, Et.duration AS vent_duration

FROM Oxygen_dat AS Od
LEFT JOIN EndTimes AS Et
on Od.icustay_id = Et.icustay_id




















