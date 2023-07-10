With pc0 AS (

SELECT patientunitstayid, chartoffset, paco2, ROW_NUMBER() OVER (partition by patientunitstayid 
ORDER BY CASE WHEN paco2 IS NULL OR paco2 = -1 THEN 1 ELSE 0 END,
chartoffset) AS RN,
FROM `oxgenator.eICU_derived.pivoted_bg` 
ORDER BY patientunitstayid 

),

pc AS (SELECT DISTINCT patientunitstayid, chartoffset, paco2

FROM pc0

WHERE RN = 1)



--Indicate warnings for the pco2 measured after ventilation
--Create columns for the information of subsequent vetilation
SELECT vd.*, pc.*, CASE WHEN pc.paco2 IS NOT NULL AND pc.chartoffset > vd.initial_time THEN 1 ELSE 0 END AS warning, sv.change_ventilation, sv.ventilation_type, sv.after_time 
FROM oxgenator.eICU_derived.eicu_ventilation AS vd
LEFT JOIN pc
ON vd.icustay_id = pc.patientunitstayid
LEFT JOIN 
oxgenator.eICU_derived.eICU_subsequent_ventilation AS sv
ON vd.icustay_id = sv.icustay_id


