## README

## Summary Statistics:

The age variable has 1,813 missing values, which constitutes a significant portion of the dataset (approximately 12%). 
This can impact analyses that rely on age as a predictor or grouping variable. Imputation or exclusion strategies should be considered.
The maximum age value is 114, which is plausible but should be verified for accuracy. If there are errors, they could impact age-related analyses.
The age distribution (mean of 68.58, median of 68) appears reasonable for a hospital dataset, but age-specific analyses should consider the potential bias introduced by missing values.
The systolic variable has a minimum value of -50, which is not medically plausible. Negative or unrealistic values suggest potential data entry errors or sensor malfunctions.
These outliers need to be identified and addressed through correction, exclusion, or imputation.
The procedure and diagnosis variables have values ranging from 1000 to 9000, which may indicate categorical codes rather than continuous data. 
We must ensure that these variables are appropriately treated as factors or categorical variables in the analysis.

## Bar Graph Explanataion:

The bar graph illustrates the average age of patients across different hospital bed counts, segregated by CABG (Coronary Artery Bypass Grafting) status. 
The average age is consistent across varying bed counts, with no significant differences between CABG and non-CABG patients. 
This consistency suggests that hospital size, as indicated by bed count, does not markedly influence the average age of patients undergoing CABG or those who do not. 
The average age appears to be slightly lower for CABG patients compared to non-CABG patients, but the difference is minimal across all bed count categories. 
This indicates a relatively uniform age distribution in the patient population irrespective of hospital capacity.

## Model Discussion: 

The logistic regression model analyzes the likelihood of patient readmission based on CABG status, systolic blood pressure, and the number of comorbidities. 
The odds ratio for 'comorbidities_count' is 1.3516, indicating that each additional comorbidity increases the odds of readmission by approximately 35.2%, which is statistically significant (p < 0.001). 
In contrast, the odds ratios for CABG status and systolic blood pressure are close to 1, with p-values of 0.979 and 0.404, respectively, suggesting no significant association with readmission. 
The intercept, with an odds ratio of 0.1254, reflects the baseline odds of readmission for non-CABG patients with zero comorbidities and a systolic blood pressure of zero. 
Overall, the model highlights the significant impact of the number of comorbidities on the likelihood of readmission, while CABG status and systolic blood pressure do not appear to significantly influence this outcome.
The logistic regression model was chosen due to its suitability for modeling binary outcomes, such as the likelihood of patient readmission. 
This model effectively handles the binary nature of the response variable and provides interpretable coefficients in terms of odds ratios. 
These results emphasize the importance of managing comorbidities in predicting and potentially reducing hospital readmissions. 
For the model to provide unbiased estimates, several assumptions must be met. 
These include the assumption of a binary dependent variable, independent observations, and a linear relationship between the predictors and the log odds of the outcome. 
It also assumes no perfect multicollinearity among the predictors, which ensures that each predictor's effect can be uniquely estimated. 
The model requires that all relevant predictors be included to avoid omitted variable bias and that the sample size is sufficiently large to provide stable estimates. 

## Notes on Graph

Notably, black patients exhibit a higher mortality risk than white patients in conditions such as heart failure, 
aortic valve surgery, chronic obstructive pulmonary disease, heart bypass surgery, and lung cancer surgery. 
Specifically, the difference is most pronounced in heart failure, with a risk difference of approximately 0.04. 
Conversely, procedures like hip replacement, knee replacement, and abdominal aortic aneurysm repair show minimal racial disparity in mortality risk. 
This data underscores significant healthcare disparities that vary by treatment type.