
# Prepare workspace
rm(list = ls()) # Clear environment
gc()            # Clear unused memory
cat("\f")       # Clear the console


# Create descriptive statistics for the above variables, and run any other code you would normally use to evaluate quality of newly imported data. 

library(dplyr)

data <- read.csv("data/USNtest_R.csv")

summary(data)

# Check for missing values #- there are zero missing values in this dataset
colSums(is.na(data))  

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Subset the data to include only those patients age 65 or older (>=). 
# Save this new dataset separately, and use it for the rest of the exercise.

# Filter patients aged 65 or older
elderly_patients <- data %>% filter(age >= 65)

# Saving the new dataset
write.csv(elderly_patients, "elderly_patients.csv", row.names = FALSE)


# Create a dummy variable indicating whether each admission involves a readmission, 
# defined as a subsequent hospitalization for the same patientId within 30 days of the index admission. 
# (i.e., flag the index admission, not the subsequent hospitalization/admission).

# Convert dates to Date class
elderly_patients$admitDate <- as.Date(elderly_patients$admitDate, format = "%d-%b-%y")

# Create a readmission flag
elderly_patients <- elderly_patients %>%
  group_by(patientId) %>%
  arrange(admitDate) %>%
  mutate(readmission = ifelse(lead(admitDate) - admitDate <= 30, 1, 0)) %>%
  ungroup()

# Check for missing values in the dataset
colSums(is.na(elderly_patients))

# Assign a default value of 0 for missing 'readmission' values
elderly_patients$readmission[is.na(elderly_patients$readmission)] <- 0

# Check again for missing values in the dataset
colSums(is.na(elderly_patients))

#Create a dummy variable indicating whether each admission involved coronary artery bypass graft (CABG) surgery:
# 1: Inclusion criteria are any procedure code in the following group: 3610, 3611, 3612, 3613, 3614, 3615, 3616.
# 2: Exclusion criteria are any procedure code where the first three characters are 350 or 351.

# Define CABG procedure codes
CABG_codes <- c(3610, 3611, 3612, 3613, 3614, 3615, 3616)
exclusion_codes <- c("350", "351")

# Create CABG flag = # Exclusion criteria: First three characters are 350 or 351

elderly_patients <- elderly_patients %>%
  rowwise() %>%
  mutate(CABG = any(c_across(starts_with("procedure")) %in% CABG_codes) & 
           !any(substr(c_across(starts_with("procedure")), 1, 3) %in% exclusion_codes)) %>%
                   ungroup()

# Convert CABG to a factor
elderly_patients$CABG <- factor(elderly_patients$CABG, levels = c(FALSE, TRUE), labels = c("Non-CABG", "CABG"))


# Using the ICD-9 option and the Elixhauser score option, 
# creating binary variables to flag each elixhauser comorbidity and a count of comorbidities.

# Load necessary libraries
library(comorbidity)
library(tidyr)

# Reshape the diagnosis data for comorbidity calculation
diagnosis_columns <- c("diagnosis1", "diagnosis2", "diagnosis3", "diagnosis4", "diagnosis5")
elix_long <- elderly_patients %>%
  select(patientId, all_of(diagnosis_columns)) %>%
  pivot_longer(cols = starts_with("diagnosis"), names_to = "code_type", values_to = "code") %>%
  filter(!is.na(code) & code != "")

# Calculate Elixhauser comorbidities using ICD-9
elix_comorbidities <- comorbidity(
  x = elix_long,
  id = "patientId",
  code = "code",
  map = "elixhauser_icd9_quan",
  assign0 = FALSE
)

# Summarize comorbidities
elix_comorbidities <- elix_comorbidities %>%
  rowwise() %>%
  mutate(comorbidities_count = sum(c_across(starts_with("chf"):starts_with("depre")), na.rm = TRUE))

# Merge comorbidity data back with the original dataset
elderly_patients <- left_join(elderly_patients, elix_comorbidities, by = "patientId")

#Checking for missing variables
colSums(is.na(elderly_patients))  


# Merge the hospital_R.csv file to your data. 
# Create a bar graph of average age by bed count for CABG and non-CABG patients and briefly describe your observations in a few sentences.
library(ggplot2)

# Read hospital data
hospital_data <- read.csv("data/hospital_R.csv")

# Merge with the main dataset
merged_data <- left_join(elderly_patients, hospital_data, by = "aha_id")

# Ensure CABG is a factor for plotting purposes
merged_data$CABG <- factor(merged_data$CABG, levels = c("Non-CABG", "CABG"))

write.csv(merged_data, "merged_data.csv", row.names = FALSE)


# Create a bar graph of average age by bed count for CABG and non-CABG patients
ggplot(merged_data, aes(x = factor(bdtot), y = age, fill = CABG)) +
  stat_summary(fun = "mean", geom = "bar", position = "dodge") +
  labs(x = "Bed Count", y = "Average Age", fill = "CABG Status") +
  ggtitle("Average Age by Bed Count and CABG Status") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("bar_graph.png")

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# Specify and run a regression model that estimates how likely a patient is to be readmitted among patients undergoing CABG surgery, 
# controlling for systolic blood pressure and the number of Elixhauser comorbidities in the admission record. 
# Update the dataset with a predicted probability of readmission for each patient undergoing CABG surgery

# Logistic regression model for readmission likelihood
model <- glm(readmission ~ CABG + systolic + comorbidities_count, 
                      data = merged_data, family = binomial)

# Summary of the model
summary(model)

# odds ratios and 95% CI
exp(cbind(OR = coef(model), confint(model)))

# Calculate Predicted Probabilities and Update to Merged_Dataset
# https://stats.oarc.ucla.edu/r/dae/logit-regression/

merged_data$pre_prob <- predict(model, newdata = merged_data, type = "response")

# Saving Final Dataset

final <- merged_data

write.csv(final, "final_data.csv", row.names = FALSE)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
