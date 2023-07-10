With ph0 AS (

SELECT patientunitstayid, chartoffset, ph, ROW_NUMBER() OVER (partition by patientunitstayid 
ORDER BY CASE WHEN ph IS NULL OR ph = -1 THEN 1 ELSE 0 END,
chartoffset) AS RN,
FROM `oxgenator.eICU_derived.pivoted_bg` 
WHERE ph >=0 AND ph <= 14

),

ph AS (SELECT DISTINCT patientunitstayid, chartoffset, ph

FROM ph0

WHERE RN = 1)



--Indicate warnings for the pho2 measured after ventilation
--Create columns for the information of subsequent vetilation
SELECT vd.*, ph.*, CASE WHEN ph.ph IS NOT NULL AND ph.chartoffset > vd.initial_time THEN 1 ELSE 0 END AS warning, sv.change_ventilation, sv.ventilation_type, sv.after_time 
FROM oxgenator.eICU_derived.eicu_ventilation AS vd
LEFT JOIN ph
ON vd.icustay_id = ph.patientunitstayid
LEFT JOIN 
oxgenator.eICU_derived.eICU_subsequent_ventilation AS sv
ON vd.icustay_id = sv.icustay_id


