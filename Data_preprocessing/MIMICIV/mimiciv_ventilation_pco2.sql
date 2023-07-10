---- Extract all the pCO2 measurements 
WITH pc0 AS (

SELECT subject_id,  charttime, 
ROW_NUMBER() OVER (partition by subject_id 
ORDER BY CASE WHEN valuenum IS NULL THEN 1 ELSE 0 END,
charttime) AS RN,
valuenum AS pCO2, valueuom
FROM oxgenator.mimiciv_hosp.labevents AS lab
WHERE itemid = 50818

),

-----Select the first measurement 
pc AS (

SELECT DISTINCT subject_id, charttime, pCO2, RN, valueuom

FROM pc0

WHERE RN = 1


),

icu AS (

SELECT *
FROM   `oxgenator.mimiciv_icu.icustays`
        
        ),
 
----merge subject id to ventialtion table
vd0 AS (

SELECT icu.subject_id AS subject_id, vd.* 
FROM oxgenator.mimiciv_derived.mimiciv_ventilation AS vd
LEFT JOIN icu 
ON vd.stay_id  = icu.stay_id

)

----Match the pco2 measurement with the ventilation status
SELECT vd0.*, pc.*EXCEPT(subject_id), 

---- indicate if there is pco2 charrtime after ventilation start time 
CASE WHEN charttime > vd0.initial_time THEN 1 ELSE 0 END AS warning,

sv.change_ventilation, sv.ventilation_type, sv.after_time

FROM vd0

LEFT JOIN pc

ON vd0.subject_id = pc.subject_id

LEFT JOIN oxgenator.mimiciv_derived.mimiciv_subsequent_ventilation AS sv

ON vd0.stay_id = sv.stay_id




















