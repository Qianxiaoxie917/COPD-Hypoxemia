WITH vd0 AS (

SELECT *, 

CASE WHEN ventilation_status = 'SupplementalOxygen' OR ventilation_status = 'HFNC' 
     THEN 'SupplementalOxygen' 
     WHEN ventilation_status = 'Tracheostomy' OR ventilation_status = 'InvasiveVent' 
     THEN 'InvasiveVent' 
     WHEN ventilation_status = 'NonInvasiveVent' THEN  'NonInvasiveVent' 
     END AS vent_type,

CASE WHEN ventilation_status = 'SupplementalOxygen' OR ventilation_status = 'HFNC' THEN 0 ELSE 1 END as vent_status,
DATETIME_DIFF(endtime, starttime, hour) AS vent_d0

FROM oxgenator.mimiciv_derived.ventilation 

WHERE ventilation_status <> 'None' 


),

Sd0 AS(


SELECT *

FROM Vd0

WHERE stay_id IN (

SELECT DISTINCT stay_id
FROM oxgenator.mimiciv_derived.mimiciv_ventilation
WHERE vent_status = 0

) 

),

---Select distinct rows by id and ventilation type 
Sv0 AS (

SELECT *, ROW_NUMBER() OVER (
            PARTITION BY stay_id, vent_type
            ORDER BY starttime
        ) AS V_RN
        
FROM Sd0


),

Sv1 AS (

SELECT *

FROM Sv0
WHERE V_RN = 1


),

--- Count how many the types of ventilation
Sv2 AS (
    
    SELECT *, COUNT(*) OVER (PARTITION BY stay_id)  AS num_type

FROM Sv1
),


--Create a column that indicate if there is subsequent ventilation or not 
--with the type of ventilation equals to 1
Sv3 AS (
SELECT *, CASE WHEN num_type = 1 THEN 0 ELSE 1 END AS change_ventilation, ROW_NUMBER() OVER (
            PARTITION BY stay_id
            ORDER BY starttime, num_type
        ) AS Sv_RN
FROM Sv2

),

--Select the subset with no change of ventialtion type

Sv_dat0 AS (

SELECT * FROM Sv3
WHERE num_type = 1 AND Sv_RN = 1


),

--Select the subset that has ventilation types that larger than 1
Sv_d10 AS (

SELECT * 

FROM Sv3

WHERE num_type >= 2 AND Sv_RN <= 2


),

ENT AS (

SELECT stay_id, endtime

FROM Sv3

WHERE Sv_RN =1


), 

STT AS (

SELECT stay_id, starttime, ventilation_status

FROM Sv3

WHERE Sv_RN = 2


),

--Calculate the gap time among change
Sv_dat1 AS (

SELECT Sv_d10.*, DATETIME_DIFF(STT.starttime, ENT.endtime , hour) AS after_time, 
STT.ventilation_status AS ventilation_type
FROM Sv_d10
LEFT JOIN ENT
on Sv_d10.stay_id = ENT.stay_id
LEFT JOIN STT
on Sv_d10.stay_id = STT.stay_id


)


---Combining all together

SELECT *,  NULL AS after_time, NULL AS ventilation_type FROM Sv_dat0
UNION ALL 
SELECT * FROM Sv_dat1

















