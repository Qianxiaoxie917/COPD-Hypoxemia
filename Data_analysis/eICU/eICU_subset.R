library(dplyr)
library(mgcv)
library(bigrquery)


project_id <- "oxgenator"  # Google Cloud project ID

# Wrapper for running BigQuery queries.
run_query <- function(query) return(bigrquery::bq_table_download(
  bigrquery::bq_project_query(x = project_id, query=query)))

#Download data from google cloud
pat_eICU2 <- run_query('
SELECT * FROM eICU_derived.eicu_patient_results')

pat_eICU2$eth <- pat_eICU2$ethnicity
pat_eICU2$eth[pat_eICU2$eth == ""] <- "Other/Unknown"
pat_eICU2$eth <- as.factor(pat_eICU2$eth)
print(table(pat_eICU2$eth))


#Remove heights below 50cm and above 300cm
pat_eICU2$height[pat_eICU2$height > 300 | pat_eICU2$height < 50] <- NA

# Remove weights below 20kg and above 600kg
pat_eICU2$weight[pat_eICU2$weight < 20 | pat_eICU2$weight > 600] <- NA

# Compute the body mass index
pat_eICU2$bmi <- pat_eICU2$weight / (pat_eICU2$height/100)^2

# Remove BMIs below 15 or above 100
pat_eICU2$bmi[pat_eICU2$bmi < 15 | pat_eICU2$bmi > 100] <- NA


if(is.character(pat_eICU2$gender)) pat_eICU2$gender_string <- pat_eICU2$gender
summary(as.factor(pat_eICU2$gender_string))

pat_eICU2$gender <- NA
pat_eICU2$gender[pat_eICU2$gender_string == "Female"] = "F"
pat_eICU2$gender[pat_eICU2$gender_string == "Male"] = "M"

pat_eICU2$gender <- as.factor(pat_eICU2$gender)

pat_eICU2$unit_type = as.factor(pat_eICU2$unittype)

levels(pat_eICU2$unit_type)[levels(pat_eICU2$unit_type) %in% c("Med-Surg ICU", "MICU", "SICU")] = "General ICU"
levels(pat_eICU2$unit_type)[levels(pat_eICU2$unit_type) %in% c("CCU-CTICU", "CSICU", "CTICU")] = "Cardiac ICU"


pat_eICU2$mortality_in_ICU <- NA
pat_eICU2$mortality_in_ICU[pat_eICU2$discharge_status_ICU == "Alive"] <- FALSE
pat_eICU2$mortality_in_ICU[pat_eICU2$discharge_status_ICU == "Expired"] <- TRUE
summary(pat_eICU2$mortality_in_ICU)

pat_eICU2$mortality_in_Hospt <- NA
pat_eICU2$mortality_in_Hospt[pat_eICU2$discharge_status_Hospt == "Alive"] <- FALSE
pat_eICU2$mortality_in_Hospt[pat_eICU2$discharge_status_Hospt == "Expired"] <- TRUE
# If someone expires in the ICU, then they expire in the hospital.
pat_eICU2$mortality_in_Hospt[which(pat_eICU2$mortality_in_ICU)] <- TRUE


# ICU stays that do not have any measurements are currently NA and should be 0.
pat_eICU2$nOxy[which(is.na(pat_eICU2$nOxy))] <- 0


##select subset for patients with enough information
pat_eICU2_subset <- pat_eICU2

cat("Total number of ICU stays:", nrow(pat_eICU2_subset))


pat_eICU2_subset <- pat_eICU2_subset[!(is.na(pat_eICU2_subset$age) | pat_eICU2_subset$age < 16), ]

pat_eICU2_subset <- pat_eICU2_subset[!(is.na(pat_eICU2_subset$gender)), ]

cat("\nPatients selected so far:", nrow(pat_eICU2_subset))

#pat_eICU2_subset <- pat_eICU2_subset[!(is.na(pat_eICU2_subset$bmi)), ]

#cat("\nPatients selected so far:", nrow(pat_eICU2_subset))


pat_eICU2_subset <- pat_eICU2_subset[!(is.na(pat_eICU2_subset$sofatotal)), ]


pat_eICU2_subset <- pat_eICU2_subset[!(is.na(pat_eICU2_subset$mortality_in_Hospt)), ]

cat("\nPatients selected so far:", nrow(pat_eICU2_subset))


pat_eICU2_subset <- pat_eICU2_subset[!is.na(pat_eICU2_subset$paco2) & pat_eICU2_subset$paco2 != -1, ]

cat("\nPatients selected so far:", nrow(pat_eICU2_subset))


pat_eICU2_subset <- pat_eICU2_subset[pat_eICU2_subset$warning == 0, ]

cat("\nPatients selected so far:", nrow(pat_eICU2_subset))


##Create a column for Hypercapina
pat_eICU2_subset$Hypercapnia <- ifelse(pat_eICU2_subset$paco2 > 45, "Hypercapnia", "Non-Hypercapnia")



##Select the subset for COPD patients
eICU_COPD_subset <- pat_eICU2_subset[!is.na(pat_eICU2_subset$has_copd_disease) & pat_eICU2_subset$has_copd_disease == TRUE, ]


##Remove patients do not have any measurements
eICU_COPD_subset  <- eICU_subset[eICU_subset$nOxy != 0, ]


save(eICU_COPD_subset, file = "eICU_COPD_subset.RData")














