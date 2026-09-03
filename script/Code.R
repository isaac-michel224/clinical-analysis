#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##U.S. News & World Report: R Coding Exercise
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Prepare workspace
rm(list = ls()) # Clear environment
gc()            # Clear unused memory
cat("\f")       # Clear the console


# Question 1: Create descriptive statistics for the above variables, and run any other code you would normally use to evaluate quality of newly imported data. 
# Describe any concerns you may have about the suitability of this dataset for further analysis.

library(dplyr)

data <- read.csv("data/USNtest_R.csv")

summary(data)

# Check for missing values #- there are zero missing values in this dataset
colSums(is.na(data))  

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Thoughts on Summary Statistics:

# The age variable has 1,813 missing values, which constitutes a significant portion of the dataset (approximately 12%). 
# This can impact analyses that rely on age as a predictor or grouping variable. Imputation or exclusion strategies should be considered.
# The maximum age value is 114, which is plausible but should be verified for accuracy. If there are errors, they could impact age-related analyses.
# The age distribution (mean of 68.58, median of 68) appears reasonable for a hospital dataset, but age-specific analyses should consider the potential bias introduced by missing values.
# The systolic variable has a minimum value of -50, which is not medically plausible. Negative or unrealistic values suggest potential data entry errors or sensor malfunctions.
# These outliers need to be identified and addressed through correction, exclusion, or imputation.
# The procedure and diagnosis variables have values ranging from 1000 to 9000, which may indicate categorical codes rather than continuous data. 
# We must ensure that these variables are appropriately treated as factors or categorical variables in the analysis.

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Question 2: Subset the data to include only those patients age 65 or older (>=). 
# Save this new dataset separately, and use it for the rest of the exercise.

# Filter patients aged 65 or older
elderly_patients <- data %>% filter(age >= 65)

# Saving the new dataset
write.csv(elderly_patients, "elderly_patients.csv", row.names = FALSE)


# Question 3: Create a dummy variable indicating whether each admission involves a readmission, 
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

# Question 4: Create a dummy variable indicating whether each admission involved coronary artery bypass graft (CABG) surgery:
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


# Question 5: Using the ICD-9 option and the Elixhauser score option, 
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


# Question 6: Merge the hospital_R.csv file to your data. 
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

# Observations on Bar Graph:

# The bar graph illustrates the average age of patients across different hospital bed counts, segregated by CABG (Coronary Artery Bypass Grafting) status. 
# The average age is consistent across varying bed counts, with no significant differences between CABG and non-CABG patients. 
# This consistency suggests that hospital size, as indicated by bed count, does not markedly influence the average age of patients undergoing CABG or those who do not. 
# The average age appears to be slightly lower for CABG patients compared to non-CABG patients, but the difference is minimal across all bed count categories. 
# This indicates a relatively uniform age distribution in the patient population irrespective of hospital capacity.

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# Question 7: Specify and run a regression model that estimates how likely a patient is to be readmitted among patients undergoing CABG surgery, 
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

# Question 8: Interpret the model output and explain your model choice over the alternatives. 
# Discuss the assumptions that must hold in order to obtain unbiased estimates from your choice of model.

# Discussion: 
# The logistic regression model analyzes the likelihood of patient readmission based on CABG status, systolic blood pressure, and the number of comorbidities. 
# The odds ratio for 'comorbidities_count' is 1.3516, indicating that each additional comorbidity increases the odds of readmission by approximately 35.2%, which is statistically significant (p < 0.001). 
# In contrast, the odds ratios for CABG status and systolic blood pressure are close to 1, with p-values of 0.979 and 0.404, respectively, suggesting no significant association with readmission. 
# The intercept, with an odds ratio of 0.1254, reflects the baseline odds of readmission for non-CABG patients with zero comorbidities and a systolic blood pressure of zero. 
# Overall, the model highlights the significant impact of the number of comorbidities on the likelihood of readmission, while CABG status and systolic blood pressure do not appear to significantly influence this outcome.
# The logistic regression model was chosen due to its suitability for modeling binary outcomes, such as the likelihood of patient readmission. 
# This model effectively handles the binary nature of the response variable and provides interpretable coefficients in terms of odds ratios. 
# These results emphasize the importance of managing comorbidities in predicting and potentially reducing hospital readmissions. 
# For the model to provide unbiased estimates, several assumptions must be met. 
# These include the assumption of a binary dependent variable, independent observations, and a linear relationship between the predictors and the log odds of the outcome. 
# It also assumes no perfect multicollinearity among the predictors, which ensures that each predictor's effect can be uniquely estimated. 
# The model requires that all relevant predictors be included to avoid omitted variable bias and that the sample size is sufficiently large to provide stable estimates. 
  

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Question 9: Interpretation of the graph. 

# Explanation:
# Notably, black patients exhibit a higher mortality risk than white patients in conditions such as heart failure, 
# aortic valve surgery, chronic obstructive pulmonary disease, heart bypass surgery, and lung cancer surgery. 
# Specifically, the difference is most pronounced in heart failure, with a risk difference of approximately 0.04. 
# Conversely, procedures like hip replacement, knee replacement, and abdominal aortic aneurysm repair show minimal racial disparity in mortality risk. 
# This data underscores significant healthcare disparities that vary by treatment type.

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
