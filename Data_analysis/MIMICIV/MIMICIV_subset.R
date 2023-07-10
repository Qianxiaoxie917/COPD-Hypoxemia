library(dplyr)
library(mgcv)
library(bigrquery)


project_id <- "oxgenator"  # Google Cloud project ID

# Wrapper for running BigQuery queries.
run_query <- function(query) return(bigrquery::bq_table_download(
  bigrquery::bq_project_query(x = project_id, query=query)))

#Download data from google cloud
pat_MIMICIV2 <- run_query('
SELECT * FROM MIMICIV_derived.mimiciv_patient_results')

pat_MIMICIV2$eth <- pat_MIMICIV2$ethnicity
pat_MIMICIV2$eth[pat_MIMICIV2$eth == ""] <- "Other/Unknown"
pat_MIMICIV2$eth <- as.factor(pat_MIMICIV2$eth)
print(table(pat_MIMICIV2$eth))


#Remove heights below 50cm and above 300cm
pat_MIMICIV2$height[pat_MIMICIV2$height > 300 | pat_MIMICIV2$height < 50] <- NA

# Remove weights below 20kg and above 600kg
pat_MIMICIV2$weight[pat_MIMICIV2$weight < 20 | pat_MIMICIV2$weight > 600] <- NA

# Compute the body mass index
pat_MIMICIV2$bmi <- pat_MIMICIV2$weight / (pat_MIMICIV2$height/100)^2
# Remove BMIs below 15 or above 100
pat_MIMICIV2$bmi[pat_MIMICIV2$bmi < 15 | pat_MIMICIV2$bmi > 100] <- NA

pat_MIMICIV2$gender <- as.factor(pat_MIMICIV2$gender)

pat_MIMICIV2$unit_type <- as.factor(pat_MIMICIV2$unittype)


pat_MIMICIV2$mortality_in_Hospt[pat_MIMICIV2$mortality_in_ICU == 1] <- TRUE


# ICU stays that do not have any measurements are currently NA and should be 0.
pat_MIMICIV2$nOxy[which(is.na(pat_MIMICIV2$nOxy))] <- 0


##select subset for patients with enough information
pat_MIMICIV2_subset <- pat_MIMICIV2


cat("Total number of ICU stays:", nrow(pat_MIMICIV2_subset))

pat_MIMICIV2_subset <- pat_MIMICIV2_subset[!(is.na(pat_MIMICIV2_subset$age) | pat_MIMICIV2_subset$age < 16), ]

pat_MIMICIV2_subset <- pat_MIMICIV2_subset[!(is.na(pat_MIMICIV2_subset$gender)), ]

cat("\nPatients selected so far:", nrow(pat_MIMICIV2_subset))

#pat_MIMICIV2_subset <- pat_MIMICIV2_subset[!(is.na(pat_MIMICIV2_subset$bmi)), ]


#cat("\nPatients selected so far:", nrow(pat_MIMICIV2_subset))

pat_MIMICIV2_subset <- pat_MIMICIV2_subset[!(is.na(pat_MIMICIV2_subset$sofatotal)), ]


pat_MIMICIV2_subset <- pat_MIMICIV2_subset[!(is.na(pat_MIMICIV2_subset$mortality_in_Hospt)), ]

cat("\nPatients selected so far:", nrow(pat_MIMICIV2_subset))


pat_MIMICIV2_subset <- pat_MIMICIV2_subset[!is.na(pat_MIMICIV2_subset$pCO2), ]


cat("\nPatients selected so far:", nrow(pat_MIMICIV2_subset))


pat_MIMICIV2_subset <- pat_MIMICIV2_subset[pat_MIMICIV2_subset$warning == 0 , ]


cat("\nPatients selected so far:", nrow(pat_MIMICIV2_subset))


##Create a column for Hypercapina
pat_MIMICIV2_subset$Hypercapnia <- ifelse(pat_MIMICIV2_subset$pCO2 > 45, "Hypercapnia", "Non-Hypercapnia")



##Select the subset for COPD patients
MIMICIV_COPD_subset <- pat_MIMICIV2_subset[!is.na(pat_MIMICIV2_subset$has_copd_disease) & pat_MIMICIV2_subset$has_copd_disease == TRUE, ]


##Remove patients do not have any measurements
MIMICIV_COPD_subset  <- MIMICIV_subset[MIMICIV_subset$nOxy != 0, ]

save(MIMICIV_COPD_subset, file = "MIMICIV_COPD_subset.RData")















