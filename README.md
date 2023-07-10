# COPD-Hypoxemia Code Repository 

This repository contains the code used for the paper "Real-world evidence challenges controlled hypoxemia guidelines for critically-ill patients with chronic obstructive pulmonary disease".

## Repository Structure and Description

The repository is organized as follows:

### Data Preprocessing

This section contains SQL scripts for each dataset that are used to preprocess the data. The outputs of the SQL scripts are saved as tables of the same name.

1. [eICU](/Data_preprocessing/eICU): This database covers patients who were admitted to critical care units in 2014 and 2015. The scripts found in this folder are:

    - [`eicu_oxygen_therapy.sql`](/Data_preprocessing/eICU/eicu_oxygen_therapy.sql): Extracts the type of oxygen therapy. 
    - [`eicu_ventilation.sql`](/Data_preprocessing/eICU/eicu_ventilation.sql): Determines the first status of ventilation for patients based on all oxygen therapy types.
    - [`eicu_ventilation_pco2.sql`](/Data_preprocessing/eICU/eicu_ventilation_pco2.sql): Combines the information of the first status of ventilation with pCO2 measurements prior to any ventilation.
    - [`eicu_ventilation_ph.sql`](/Data_preprocessing/eICU/eicu_ventilation_ph.sql): Combines the information of the first status of ventilation with pH measurements prior to any ventilation.
    - [`eicu_subsequent_ventilation.sql`](/Data_preprocessing/eICU/eicu_subsequent_ventilation.sql): Extracts the information of subsequent ventilation when the first status of ventilation is non-ventilated.
    - [`eicu_sofa_results.sql`](/Data_preprocessing/eICU/eicu_sofa_results.sql): Extracts the SOFA score of patients.
    - [`eicu_patient_results.sql`](/Data_preprocessing/eICU/eicu_patient_results.sql): Extracts a final table containing all the above information.

2. [MIMICIV](/Data_preprocessing/MIMICIV): This database contains hospital and critical care data for patients admitted to the ED or ICU between 2008 - 2019. The scripts found in this folder are:

    - [`mimiciv_ventilation.sql`](/Data_preprocessing/MIMICIV/mimiciv_ventilation.sql): Determines the first status of ventilation for patients based on all ventilation statuses.
    - [`mimiciv_ventilation_pco2.sql`](/Data_preprocessing/MIMICIV/mimiciv_ventilation_pco2.sql):   Combines the information of the first status of ventilation with pCO2 measurements prior to any ventilation.
    - [`mimiciv_ventilation_ph.sql`](/Data_preprocessing/MIMICIV/mimiciv_ventilation_ph.sql):   Combines the information of the first status of ventilation with pH measurements prior to any ventilation.
    - [`mimiciv_subsequent_ventilation.sql`](/Data_preprocessing/MIMICIV/mimiciv_subsequent_ventilation.sql): Extracts the information of subsequent ventilation when the first status of ventilation is non-ventilated.
    - [`mimiciv_copd_icd_codes.sql`](/Data_preprocessing/MIMICIV/mimiciv_copd_icd_codes.sql): Extracts the ICD codes of COPD patients.
    - [`mimiciv_patient_results.sql`](/Data_preprocessing/MIMICIV/mimiciv_patient_results.sql): Extracts a final table containing all the above information.


### Data Analysis

This section includes the extraction and analysis of data using R. The analysis code assumes that the data is present in this folder.

1. [eICU](/Data_analysis/eICU): This directory contains the analysis scripts for the eICU-CRD database.

    - [`funs.R`](/Data_analysis/eICU/funs.R): Script to contain the functions that might be used during the analysis.
    - [`eICU_subset.R`](/Data_analysis/eICU/eICU_subset.R): Script to extract a subset of initially non-ventilated COPD patients. It generates "eICU_COPD_subset.RData" file for the analysis.
    - [`Main_eICU_COPD.Rmd`](/Data_analysis/eICU/Main_eICU_COPD.Rmd): R Markdown file to perform data analysis using Generalized Additive Model (GAM) regression.
    - [`Supplement_eICU_COPD_FiO2.Rmd`](/Data_analysis/eICU/Supplement_eICU_COPD_FiO2.Rmd): R Markdown file to perform the sensitivity analysis to adjust for FiO2.
    - [`Supplement_eICU_COPD_Interaction.Rmd`](/Data_analysis/eICU/Supplement_eICU_COPD_Interaction.Rmd): R Markdown file to perform the interaction analysis of pCO2 and SpO2.
    - [`Supplement_eICU_COPD_Respiratory_Acidosis.Rmd`](/Data_analysis/eICU/Supplement_eICU_COPD_Respiratory_Acidosis.Rmd): R Markdown file to perform the subgroup analysis where we subdivided the ICU stays with COPD anf hypercapnia by respiratory acidosis.
       
    
    
2. [MIMICIV](/Data_analysis/MIMICIV): This directory contains the analysis scripts for the MIMIC-IV database.

    - [`funs.R`](/Data_analysis/MIMICIV/funs.R): Script to contain the functions that might be used during the analysis.
    - [`MIMICIV_subset.R`](/Data_analysis/MIMICIV/MIMICIV_subset.R): Script to extract a subset of initially non-ventilated COPD patients. It generates "MIMICIV_COPD_subset.RData" file for the analysis.
    - [`Main_MIMICIV_COPD.Rmd`](/Data_analysis/MIMICIV/Main_MIMICIV_COPD.Rmd): R Markdown file to perform data analysis using Generalized Additive Model (GAM) regression.
    - [`Supplement_MIMICIV_COPD_FiO2.Rmd`](/Data_analysis/MIMICIV/Supplement_MIMICIV_COPD_FiO2.Rmd): R Markdown file to perform the sensitivity analysis to adjust for FiO2.
    - [`Supplement_MIMICIV_COPD_Interaction.Rmd`](/Data_analysis/MIMICIV/Supplement_MIMICIV_COPD_Interaction.Rmd): R Markdown file to perform the interaction analysis of pCO2 and SpO2.
    - [`Supplement_MIMICIV_COPD_Respiratory_Acidosis.Rmd`](/Data_analysis/MIMICIV/Supplement_MIMICIV_COPD_Respiratory_Acidosis.Rmd): R Markdown file to perform the subgroup analysis where we subdivided the ICU stays with COPD anf hypercapnia by respiratory acidosis.
    - [`Supplement_MIMICIV_COPD_Ethnicity.Rmd`](/Data_analysis/MIMICIV/Supplement_MIMICIV_COPD_Ethnicity.Rmd): R Markdown file to perform the subgroup analysis of patients with dark skin.


Please note that specific details of the scripts and their functions can be found within the respective folders. Feel free to contribute or raise an issue if you find anything that could be improved or updated.
