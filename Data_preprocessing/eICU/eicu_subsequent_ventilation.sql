WITH Od0 AS (
SELECT *, MIN(charttime) OVER (PARTITION BY icustay_id ORDER BY charttime) AS initial_time,
charttime - MIN(charttime) OVER (PARTITION BY icustay_id ORDER BY charttime) AS time_diff,
CASE WHEN oxygen_therapy_type IN (-1, 1, 0) THEN 0
ELSE 1 END AS ventilation
FROM oxgenator.eicu.oxygen_therapy

),


Sd0 AS (


SELECT * 
FROM Od0
WHERE icustay_id IN (SELECT DISTINCT icustay_id
FROM oxgenator.eICU_derived.eicu_ventilation 
WHERE oxygen_therapy_type IN (-1, 0, 1))


),


--Set all the unknown oxygen therapy type as non-ventilated  
Sv AS (

SELECT *, CASE 
        WHEN oxygen_therapy_type IN (-1, 0, 1) THEN 1
        ELSE oxygen_therapy_type
    END as vent_type
FROM Sd0


),

---Select distinct rows by id and ventilation type (1, 2, 3, 4)
Sv0 AS (

SELECT *, ROW_NUMBER() OVER (
            PARTITION BY icustay_id, vent_type
            ORDER BY charttime
        ) AS V_RN
        
FROM Sv


),


Sv1 AS (

SELECT *

FROM Sv0
WHERE V_RN = 1



),

--- Count how many the types of ventilation
Sv2 AS (
    
    SELECT *, COUNT(*) OVER (PARTITION BY icustay_id)  AS num_type

FROM Sv1
),

--Create a column that indicate if there is subsequent ventilation or not 
--with the type of ventilation equals to 1
Sv3 AS (
SELECT *, CASE WHEN num_type = 1 THEN 0 ELSE 1 END AS change_ventilation, ROW_NUMBER() OVER (
            PARTITION BY icustay_id
            ORDER BY charttime, num_type
        ) AS Sv_RN
FROM Sv2

),

--Select the first type of ventilation
CT1 AS (

SELECT icustay_id, charttime 

FROM Sv3

WHERE Sv_RN = 1

),

--Select the second type of ventilation
CT2 AS (

SELECT icustay_id, charttime 

FROM Sv3

WHERE Sv_RN = 2



),


--Select the subset with no change of ventialtion type

Sv_dat0 AS (

SELECT * FROM Sv3
WHERE num_type = 1 AND Sv_RN = 1


),

--Select two types of ventilation during the whole process
Sv_d10 AS (

SELECT * FROM Sv3
WHERE num_type = 2 


),

--Create a column that contains the ventialtion type after the change
Sv_d11 AS (
SELECT 
    *, 
    CASE 
        WHEN vent_type = 2 THEN 'Inv/Noninv'
        WHEN vent_type = 3 THEN 'Noninv'
        WHEN vent_type = 4 THEN 'Inv'
    END as ventilation_type
    
FROM Sv_d10
),


--Create a column that contains the gap time between change

Sv_dat1 AS (

SELECT Sv_d11.*, CT2.charttime - CT1.charttime AS after_time 
FROM Sv_d11 
LEFT JOIN CT1
on Sv_d11.icustay_id = CT1.icustay_id
LEFT JOIN CT2
on Sv_d11.icustay_id = CT2.icustay_id
WHERE Sv_RN = 2



),

--Select the subset that has ventilation types that larger than 2
Sv_d20 AS (

SELECT * 

FROM Sv3

WHERE num_type > 2


),

--Select the second type of ventilation 
CV20 AS (

SELECT icustay_id, vent_type

FROM Sv3

WHERE Sv_RN = 2 AND icustay_id IN (SELECT DISTINCT icustay_id FROM Sv_d20)


),

--Select the second type of ventilation 
CV30 AS (

SELECT icustay_id, vent_type

FROM Sv3

WHERE Sv_RN = 3 AND icustay_id IN (SELECT DISTINCT icustay_id FROM Sv_d20)


),


--Select the known ventialtion type (if unkown as 2 then search the next)
Sv_d21 AS (

SELECT 
    Sv_d20.*, 
    CASE 
        WHEN CV20.vent_type != 2 THEN CASE WHEN CV20.vent_type = 3 THEN 'Noninv' ELSE 'Inv' END 
        ELSE CASE WHEN  CV30.vent_type = 3 THEN 'Noninv' ELSE 'Inv' END 
    END as ventilation_type
FROM Sv_d20
LEFT JOIN CV20
on Sv_d20.icustay_id = CV20.icustay_id
LEFT JOIN CV30
on Sv_d20.icustay_id = CV30.icustay_id
WHERE Sv_RN = 1



), 

Sv_dat2 AS (

SELECT Sv_d21.*, CT2.charttime - CT1.charttime AS after_time 
FROM Sv_d21
LEFT JOIN CT1
on Sv_d21.icustay_id = CT1.icustay_id
LEFT JOIN CT2
on Sv_d21.icustay_id = CT2.icustay_id


)



---Combining all together

SELECT *, NULL AS ventilation_type, NULL AS after_time FROM Sv_dat0
UNION ALL 
SELECT * FROM Sv_dat1
UNION ALL 
SELECT * FROM Sv_dat2







