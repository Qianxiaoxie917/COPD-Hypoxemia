----select copd patients from icd codes (9 and 10)
WITH icd_presence AS (
SELECT
icd.hadm_id, icd.icd_code,
CASE WHEN icd.icd_version = 9
THEN SAFE_CAST(SUBSTR(icd.icd_code, 0, 3) as INT64) 
END AS icd_num,
FROM `oxgenator.mimiciv_hosp.diagnoses_icd` AS icd)

SELECT
icd_presence.hadm_id AS hadm_id,

COUNT(CASE WHEN icd_presence.icd_code  LIKE 'J4%' or icd_presence.icd_num BETWEEN 490 AND 496  THEN 1 END) > 0 AS has_copd_disease,
FROM icd_presence
GROUP BY icd_presence.hadm_id


