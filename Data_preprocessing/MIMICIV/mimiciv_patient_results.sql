WITH

mortality_type AS (
SELECT
  icu.stay_id AS stay_id,
  CASE WHEN admissions.deathtime BETWEEN admissions.admittime and admissions.dischtime
  THEN 1 
  ELSE 0
  END AS mortality_in_Hospt, 
  CASE WHEN admissions.deathtime BETWEEN icu.intime and icu.outtime
  THEN 1
  ELSE 0
  END AS mortality_in_ICU,
  admissions.deathtime as deathtime, 
  icu.intime as ICU_intime,
  admissions.race
FROM `oxgenator.mimiciv_icu.icustays` AS icu
INNER JOIN `oxgenator.mimiciv_hosp.admissions` AS admissions
  ON icu.hadm_id = admissions.hadm_id),

---  table from 'mimiciv_ventilation_pco2.sql'
vd_pco2 AS (

SELECT *
FROM `oxgenator.mimiciv_derived.mimiciv_ventilation_pco2` 

),


---  table from 'mimiciv_ventilation_pco2.sql'
vd_ph AS (

SELECT *
FROM `oxgenator.mimiciv_derived.mimiciv_ventilation_ph` 

),

-- Extract the SpO2 measurements that happen during ventilation
 ce AS (
  SELECT DISTINCT 
    chart.stay_id
    , chart.valuenum as spO2_Value
    , chart.charttime
  FROM `oxgenator.mimiciv_icu.chartevents` AS chart
    INNER JOIN vd_pco2 ON chart.stay_id = vd_pco2.stay_id
      AND vd_pco2.initial_time <= chart.charttime
      AND vd_pco2.end_time >= chart.charttime
  WHERE chart.itemid in (220277, 646) 
    AND chart.valuenum IS NOT NULL
    -- exclude rows marked as warning
    AND (chart.warning <> 1 OR chart.warning IS NULL) --chart.warning IS DISTINCT FROM 1
    -- We remove oxygen measurements that are outside of the range [10, 100]
    AND chart.valuenum >= 10
    AND chart.valuenum <= 100
),


-- Extract the FiO2 measurements that happen during ventilation
 Fe AS (
  SELECT DISTINCT 
    chart.stay_id
    , chart.valuenum as FiO2_Value
    , chart.charttime
  FROM `oxgenator.mimiciv_icu.chartevents` AS chart
    INNER JOIN vd_pco2 ON chart.stay_id = vd_pco2.stay_id
      AND vd_pco2.initial_time <= chart.charttime
      AND vd_pco2.end_time >= chart.charttime
  WHERE chart.itemid = 223835 
    AND chart.valuenum IS NOT NULL
    -- exclude rows marked as warning
    AND (chart.warning <> 1 OR chart.warning IS NULL) --chart.warning IS DISTINCT FROM 1
    -- We remove measurements that are outside of the range [10, 100]
    AND chart.valuenum >= 21
    AND chart.valuenum <= 100
)





-- Computing summaries of the blood oxygen saturation (SpO2)
, SpO2 AS (
  -- Edited from https://github.com/cosgriffc/hyperoxia-sepsis
  SELECT DISTINCT
      ce.stay_id
      -- We currently ignore the time aspect of the measurements.
      -- However, one ideally should take into account that
      -- certain measurements are less spread out than others.
   , COUNT(ce.spO2_Value) OVER(PARTITION BY ce.stay_id) AS nOxy
    , PERCENTILE_CONT(ce.spO2_Value, 0.5) OVER(PARTITION BY ce.stay_id) AS median_SpO2
    , AVG(CAST(ce.spO2_Value >= 96 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop0
    , AVG(CAST(ce.spO2_Value >= 95 AND ce.spO2_Value < 99 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop1
    , AVG(CAST(ce.spO2_Value >= 94 AND ce.spO2_Value < 98 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop2
    , AVG(CAST(ce.spO2_Value >= 93 AND ce.spO2_Value < 97 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop3
    , AVG(CAST(ce.spO2_Value >= 92 AND ce.spO2_Value < 96 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop4
    , AVG(CAST(ce.spO2_Value >= 91 AND ce.spO2_Value < 95 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop5
    , AVG(CAST(ce.spO2_Value >= 90 AND ce.spO2_Value < 94 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop6
    , AVG(CAST(ce.spO2_Value >= 89 AND ce.spO2_Value < 93 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop7
    , AVG(CAST(ce.spO2_Value >= 88 AND ce.spO2_Value < 92 AS INT64)) OVER(PARTITION BY ce.stay_id) AS prop8
    , AVG(CAST(ce.spO2_Value >= 99 AS INT64)) OVER(PARTITION BY ce.icustay_id) AS p100
  FROM ce
), 

FiO2 AS (

SELECT DISTINCT Fe.stay_id 

, COUNT(Fe.FiO2_Value) OVER(PARTITION BY Fe.stay_id) AS nFiO2
    , PERCENTILE_CONT(Fe.FiO2_Value, 0.5) OVER(PARTITION BY Fe.stay_id) AS median_FiO2

FROM Fe

)

,height AS (
SELECT DISTINCT * FROM `oxgenator.mimiciv_derived.first_day_height`
),

weight AS (
SELECT DISTINCT * FROM `oxgenator.mimiciv_derived.first_day_weight`
),


-- `patients` on our Google cloud setup has each ICU stay duplicated 7 times.
-- We get rid of these duplicates.
pat AS (
	SELECT DISTINCT * FROM `oxgenator.mimiciv_hosp.patients`
),

age AS (
	SELECT DISTINCT * FROM `oxgenator.mimiciv_derived.age`
),


icu AS (SELECT *
        FROM   `oxgenator.mimiciv_icu.icustays`),
        

----there are duplicates in the final table, create two more tables to get rid of duplicates
pre_results AS (SELECT DISTINCT
icu.hadm_id AS HADM_id,       
icu.stay_id AS stay_id,       
icu.subject_id AS patient_ID,
pat.gender AS gender,
age.age AS age,
DATETIME_DIFF(icu.outtime, icu.intime, HOUR) / 24 AS icu_length_of_stay,
mortality_type.* EXCEPT(stay_id),
icd.* EXCEPT(hadm_id),
apsiii.apsiii,
sofa.sofa_24hours AS sofatotal,
height.height AS height,
weight.weight as weight,
icu.first_careunit as unittype,
SpO2.* EXCEPT(stay_id), FiO2.* EXCEPT(stay_id), vd_ph.pH, vd_ph.warning AS warning_ph, vd_pco2.* EXCEPT(stay_id)
FROM icu
LEFT JOIN age 
  ON icu.hadm_id = age.hadm_id
LEFT JOIN pat
  ON icu.subject_id = pat.subject_id
LEFT JOIN height
  ON icu.stay_id = height.stay_id
LEFT JOIN weight
  ON icu.stay_id = weight.stay_id
LEFT JOIN mortality_type
  ON icu.stay_id = mortality_type.stay_id
LEFT JOIN `oxgenator.mimiciv_derived.copd` AS icd 
  ON icu.hadm_id = icd.hadm_id
LEFT JOIN `oxgenator.mimiciv_derived.apsiii` AS apsiii
  ON icu.stay_id = apsiii.stay_id
LEFT JOIN `oxgenator.mimiciv_derived.sofa` sofa 
  ON icu.stay_id = SOFA.stay_id
LEFT JOIN vd_pco2
  ON icu.stay_id = vd_pco2.stay_id
LEFT JOIN vd_ph
  ON icu.stay_id = vd_ph.stay_id
LEFT JOIN SpO2
  ON icu.stay_id = SpO2.stay_id
LEFT JOIN FiO2
  ON icu.stay_id = FiO2.stay_id
  ),
  
tmp_results AS (

SELECT *, ROW_NUMBER() OVER (PARTITION BY patient_ID, HADM_id, stay_id ORDER BY patient_ID) AS pat_RN
FROM pre_results

)
  
  
  
SELECT * EXCEPT(pat_RN)

FROM tmp_results

WHERE pat_RN = 1

  
  
  

  
  

  