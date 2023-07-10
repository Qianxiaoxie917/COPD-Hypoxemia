--Mostly based on the code from https://github.com/nus-mornin-lab/oxygenation_kc
--Except for including the information of ventialtion type and pco2 level
WITH 

pat AS (
SELECT * FROM `oxgenator.eicu.patient`),

diag AS (
SELECT * FROM `oxgenator.eicu.diagnosis`),

apsiii_raw AS (
SELECT * FROM `oxgenator.eicu.apachepatientresult`),

intakeoutput AS (
SELECT DISTINCT
patientunitstayid,
intakeoutputoffset,
nettotal
FROM `oxgenator.eicu.intakeoutput`),

sofa_results AS (
SELECT * FROM `oxgenator.eicu.eicu_sofa_results`),


icd_code AS (
SELECT
diag.patientunitstayid,
SAFE_CAST(SUBSTR(diag.icd9code, 0, 3) as INT64) AS icd9code,
icd9code AS icd9code_string
FROM diag),


icd_presence AS (
SELECT
icd_code.patientunitstayid,
COUNT(CASE WHEN icd_code.icd9code BETWEEN 490 AND 496 THEN 1 END) > 0 AS has_copd_disease
FROM icd_code
GROUP BY icd_code.patientunitstayid),


apsiii AS (
SELECT
apsiii_raw.patientunitstayid,
MAX(apsiii_raw.apachescore) as apsiii
FROM apsiii_raw
GROUP BY apsiii_raw.patientunitstayid),


fluid_balance AS (
SELECT
intakeoutput.patientunitstayid,
SUM(intakeoutput.nettotal) as fluid_balance
FROM intakeoutput
GROUP BY intakeoutput.patientunitstayid),



end_of_life AS (
-- Per https://github.com/MIT-LCP/eicu-code/issues/65
SELECT DISTINCT patientunitstayid
FROM `oxgenator.eicu.careplaneol`
WHERE activeupondischarge

UNION DISTINCT

SELECT DISTINCT patientunitstayid
FROM `oxgenator.eicu.careplangeneral`
WHERE cplitemvalue = "No CPR"
OR cplitemvalue = "Do not resuscitate"
OR cplitemvalue = "Comfort measures only"
OR cplitemvalue = "End of life"
)



, vd_pco2 AS (
	SELECT *
	FROM `oxgenator.eICU_derived.eicu_ventilation_pco2`
)

, vd_ph AS (
	SELECT *
	FROM `oxgenator.eICU_derived.eICU_ventilation_ph`
)



-- Extract the SpO2 measurements that happen during oxygen therapy.
, ce AS (
  SELECT DISTINCT 
    chart.patientunitstayid AS icustay_id
    , SAFE_CAST(chart.nursingchartvalue as FLOAT64) as spO2_Value
    , chart.nursingchartoffset AS charttime
  FROM `oxgenator.eicu.nursecharting` AS chart
    INNER JOIN vd_pco2 ON chart.patientunitstayid = vd_pco2.icustay_id
      -- We are only interested in measurements during oxygen therapy sessions.
      AND vd_pco2.initial_time <= chart.nursingchartoffset
      AND vd_pco2.end_time >= chart.nursingchartoffset
  WHERE chart.nursingchartcelltypevalname = "O2 Saturation"
    -- We remove oxygen measurements that are outside of the range [10, 100]
    AND SAFE_CAST(chart.nursingchartvalue as FLOAT64) >= 10
    AND SAFE_CAST(chart.nursingchartvalue as FLOAT64) <= 100
)


-- Extract the FiO2 measurements that happen during ventialtion
, Fe AS (

SELECT DISTINCT 
    bg.patientunitstayid AS icustay_id
    , SAFE_CAST( bg.fio2 as FLOAT64) as FiO2_Value, 
     bg.chartoffset AS charttime
  FROM `oxgenator.eICU_derived.pivoted_bg` AS bg
    INNER JOIN vd_pco2 ON bg.patientunitstayid = vd_pco2.icustay_id
      -- We are only interested in measurements during ventilation sessions.
      AND vd_pco2.initial_time <= bg.chartoffset
      AND vd_pco2.end_time >= bg.chartoffset
    -- We remove measurements that are outside of the range [21, 100]
    AND SAFE_CAST(bg.fio2 as FLOAT64) > 0.20
    AND SAFE_CAST(bg.fio2 as FLOAT64) <= 1.0

),

FiO2 AS (
SELECT DISTINCT

Fe.icustay_id

   , COUNT(Fe.FiO2_Value) OVER(PARTITION BY Fe.icustay_id) AS nFiO2
    , PERCENTILE_CONT(Fe.FiO2_Value, 0.5) OVER(PARTITION BY Fe.icustay_id) AS median_FiO2
  

FROM Fe


)

-- Computing summaries of the blood oxygen saturation (SpO2)
, SpO2 AS(
  SELECT DISTINCT
    ce.icustay_id
    -- We currently ignore the time aspect of the measurements.
    -- However, one ideally should take into account that
    -- certain measurements are less spread out than others.
    , COUNT(ce.spO2_Value) OVER(PARTITION BY ce.icustay_id) AS nOxy
    , PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.icustay_id) AS median_SpO2
    , AVG(CAST(ce.spO2_Value >= 99 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS p100
    , AVG(CAST(ce.spO2_Value >= 96 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop0
    , AVG(CAST(ce.spO2_Value >= 95 AND ce.spO2_Value < 99 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop1
    , AVG(CAST(ce.spO2_Value >= 94 AND ce.spO2_Value < 98 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop2
    , AVG(CAST(ce.spO2_Value >= 93 AND ce.spO2_Value < 97 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop3
    , AVG(CAST(ce.spO2_Value >= 92 AND ce.spO2_Value < 96 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop4
    , AVG(CAST(ce.spO2_Value >= 91 AND ce.spO2_Value < 95 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop5
    , AVG(CAST(ce.spO2_Value >= 90 AND ce.spO2_Value < 94 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop6
    , AVG(CAST(ce.spO2_Value >= 89 AND ce.spO2_Value < 93 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop7
    , AVG(CAST(ce.spO2_Value >= 88 AND ce.spO2_Value < 92 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS prop8
  FROM ce
)



SELECT 
  pat.gender,
  pat.unittype,
  pat.patientHealthSystemStayID as hospital_stay_id,
  pat.unitVisitNumber as unit_stay_number, -- counter for ICU visits on same hospital stay
  pat.hospitalDischargeYear, -- hospitalAdmitYear is missing in patient table
  pat.uniquepid AS patient_ID,
  pat.patientunitstayid AS icustay_id,
  SAFE_CAST(pat.age AS FLOAT64) AS age,
  pat.admissionHeight AS height,
  pat.admissionWeight AS weight,
--  pat.hospitaladmitoffset AS hospitaladmitoffset,
  pat.unitdischargeoffset / (24 * 60) AS icu_length_of_stay,
  pat.hospitalid AS hospital_id,
  pat.unitdischargestatus AS discharge_status_ICU,
  pat.hospitaldischargestatus AS discharge_status_Hospt,
  pat.ethnicity,
  icd_presence.* EXCEPT(patientunitstayid),
  apsiii.* EXCEPT(patientunitstayid),
  fluid_balance.* EXCEPT(patientunitstayid),
  sofa_results.* EXCEPT(patientunitstayid),
  IF(end_of_life.patientunitstayid IS NULL, FALSE, TRUE) as end_of_life
	, vd_pco2.* EXCEPT(icustay_id), vd_ph.ph, vd_ph.warning AS warning_ph
	, SpO2.* EXCEPT(icustay_id), FiO2.* EXCEPT(icustay_id)
FROM pat
LEFT JOIN icd_presence
  ON pat.patientunitstayid = icd_presence.patientunitstayid
LEFT JOIN apsiii
  ON pat.patientunitstayid = apsiii.patientunitstayid
LEFT JOIN fluid_balance
  ON pat.patientunitstayid = fluid_balance.patientunitstayid
LEFT JOIN sofa_results
  ON pat.patientunitstayid = sofa_results.patientunitstayid
LEFT JOIN end_of_life
  ON pat.patientunitstayid = end_of_life.patientunitstayid
LEFT JOIN SpO2
  ON pat.patientunitstayid = SpO2.icustay_id
LEFT JOIN FiO2
  ON pat.patientunitstayid = FiO2.icustay_id
LEFT JOIN  vd_pco2 AS vd_pco2
  ON pat.patientunitstayid = vd_pco2.icustay_id
LEFT JOIN  vd_ph AS vd_ph
  ON pat.patientunitstayid = vd_ph.icustay_id


	