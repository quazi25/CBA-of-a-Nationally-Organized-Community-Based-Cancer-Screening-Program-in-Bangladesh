



****************************** PART A: DATA CLEANING AND PROCESSING ***************
/* Clear previous history */
clear
/* set directory */
cd "C:\Users\HP\Desktop\2025\6. June\1. CBA Study\Final Documents\Dataset, Do File and Questionnaire"
/* import survey dataset */
import excel "C:\Users\HP\Desktop\2025\6. June\1. CBA Study\Final Documents\Dataset, Do File and Questionnaire\Facility-based Patient Survey Dataset.xlsx", sheet("Main Data") firstrow

/* Cleaning Process */
/* rename selected variables for better understanding */
rename	 Ownershipofhospital 	ownership_hos
rename	 monthfirstdiagnosisofcan 	months_from_diag
rename	 Hospitalofdetection 	diag_hos
rename	 Cancerstagewhiledetection 	stage
rename	  currentstageofcancer 	current_stage
rename Numberofdaysspentwost months_without_work
rename Patientsavgmonthlyincome patient_prev_income
rename patients1stattdsavginc att_1_avg_income
rename stattdsmissingworkdays att1_days_missed_work
rename patients2ndattdsavginc att_2_avg_income
rename ndattdsmissingworkdays att2_days_missed_work
rename patients3rdattdsavginc att_3_avg_income
rename rdattdsmissingworkdays att3_days_missed_work
rename Iftheresanywaytogetr intangible_cost
rename Ageofpatient Age
rename Totalexpendituretillthis medical_cost
rename Totallogisticexpendituret accomo_food
rename Totaltransportcosttillth transport
rename Noofhospitalvisitedbefor prev_facilities

/* destring categorical variables */
destring Age, replace
destring months_without_work, replace
destring att_2_avg_income, replace 
destring att2_days_missed_work, replace
destring months_from_diag, replace

/* Replace for cleaning purpose starts */
**Replace Ahsania mission and Bangladesh Cancer Society Hospital as private hospital**
replace ownership_ho = "Private Hospital" if Hospitalname== "AMCH"
replace ownership_ho = "Private Hospital" if Hospitalname== "BCSH"
tab ownership_ho

/* Repalace for correcting errors */
*replace extra 4th stage
replace stage = "04.4th" if stage == "04.4th "
*replace outlier
replace accomo_food = 70000 if stage == "01.1st" & accomo_food == 700000
* replace type of treatment
replace Presenttypeoftreatment = "04.Medicine" if Presenttypeoftreatment == "04.Medicine "

// replace missing value - Replace  "99" with "."
replace att2_days_missed_work = . if att2_days_missed_work == 99
replace att_3_avg_income= . if att_3_avg_income== 99
replace att3_days_missed_work= . if att3_days_missed_work== 99

/* Outlier - average income 300,000 is not an outlier */
tab att_3_avg_income

/* Generating yearly indirect costs variables */
// Rationale: For patients and attendants who reported zero income, assigning a value of zero would likely underestimate the true economic burden. This is particularly relevant for groups such as housewives and students, whose contributions—despite not being monetarily compensated—result in real productivity losses when interrupted. For individuals in other professions reporting zero income, there is also the possibility of intentional underreporting. Therefore, in all such cases, we replaced the zero income values with the national per capita income, which serves as a proxy for the economic value of lost time or productivity. However, for elderly and unemployed individuals, these assumptions do not apply, as their time may not represent productive or hidden economic contributions. In such cases, income was retained as zero. Overall, we assume that per capita income provides a reasonable approximation of lost economic value and thus used it to impute missing wage data where appropriate. //
/* STEP 1: previous/current monthly income missing wages replaced by per capita income. */

* PATIENT
ta Professionofpatient
generate monthly_per_capita_inc = 24515
di monthly_per_capita_inc
sum patient_prev_income if patient_prev_income == 0 & (Professionofpatient != "08.Unemployed" & Professionofpatient != "20.Elderly")
replace patient_prev_income = monthly_per_capita_inc if patient_prev_income == 0 & (Professionofpatient != "08.Unemployed" & Professionofpatient != "20.Elderly")
* This should make 238 real changes

* ATTENDANT 1
ta patients1stattdsmainpr
sum att_1_avg_income if att_1_avg_income == 0 & (patients1stattdsmainpr != "08.Unemployed" & patients1stattdsmainpr != "20.Elderly")
replace att_1_avg_income = monthly_per_capita_inc if att_1_avg_income == 0 & (patients1stattdsmainpr != "08.Unemployed" & patients1stattdsmainpr != "20.Elderly")
* This should make 169 real changes

* ATTENDANT 2
ta patients2ndattdsmainpr
sum att_2_avg_income if att_2_avg_income == 0 & (patients2ndattdsmainpr != "08.Unemployed" & patients2ndattdsmainpr != "20.Elderly" & patients2ndattdsmainpr != "19.Child")
replace att_2_avg_income = monthly_per_capita_inc if att_2_avg_income == 0 & (patients2ndattdsmainpr != "08.Unemployed" & patients2ndattdsmainpr != "20.Elderly" & patients2ndattdsmainpr != "19.Child")
* This should make 57 real changes

* ATTENDANT 3
ta patients3rdattdsmainpr
sum att_3_avg_income if att_3_avg_income == 0
replace att_3_avg_income = monthly_per_capita_inc if att_3_avg_income == 0
* This should make 1 real changes

/* STEP 2: For calculating annual indriect cost - we need annual work month lost. We need annual workmonth lost for patient and annual workdays lost for attendants.
How - To estimate annual work-month loss, we used available data on both the duration from diagnosis to the time of interview (months_from_diag) and the total reported period without work (months_without_work). In several cases, months_without_work exceeded months_from_diag, which reflects the possibility that patients were unable to work due to symptoms even before receiving a formal cancer diagnosis. To address this, we used the unitary method to calculate annualized work-month losses. In instances where months_without_work was greater than months_from_diag, we replaced the lower value with months_without_work to capture the full duration of productivity loss attributable to illness, regardless of the formal detection date. This adjustment accounts for the pre-diagnosis impact of cancer-related symptoms on patients’ ability to work. */
egen new_months_from_diag = rowmax(months_from_diag months_without_work)
gen annual_workmonth_lost_patient = (months_without_work * 12) / new_months_from_diag

* Convert months from diagnosis into days and years for convenience - 30.4375 days in a month on average
gen days_from_diag = months_from_diag * 30.4375
gen years_from_diag = months_from_diag / 12
gen age_when_diagnosed = Age - years_from_diag

* Attendant 1 - calculate workdays missed in a year - 365.25 days in a year on average, adjusted for leap years
gen annual_workdays_lost_att1 = (att1_days_missed_work / days_from_diag) * 365.25

* Attendant 2 - calculate workdays missed in a year - 365.25 days in a year on average, adjusted for leap years
gen annual_workdays_lost_att2 = (att2_days_missed_work / days_from_diag) * 365.25

* Attendant 3 - calculate workdays missed in a year - 365.25 days in a year on average, adjusted for leap years
gen annual_workdays_lost_att3 = (att3_days_missed_work / days_from_diag) * 365.25

/* Generate weights */
** ATTENDANT EARNING LOSS

** Generate per day income for the attendants **
gen income_per_day_att1 = att_1_avg_income/30.4375
gen income_per_day_att2 = att_2_avg_income/30.4375
gen income_per_day_att3 = att_3_avg_income/30.4375
** Per day income and days missed work

** Calculate income loss for each attendant
gen annual_income_loss_att1 = income_per_day_att1 * annual_workdays_lost_att1
gen annual_income_loss_att2 = income_per_day_att2 * annual_workdays_lost_att2
gen annual_income_loss_att3 = income_per_day_att3 * annual_workdays_lost_att3

** Calculate total annual income loss per patient
egen total_annual_att_earning_loss = rowtotal(annual_income_loss_att1 annual_income_loss_att2 annual_income_loss_att3)

** Calculate average annual income loss for attendants
sum total_annual_att_earning_loss

** PATIENT EARNING LOSS
* Calculate Total Annual Earning Loss Patient
gen annual_earning_loss_patient = patient_prev_income * annual_workmonth_lost_patient

* Calculate Average Annual Earning Loss
sum annual_earning_loss_patient

/* Creating simplified versions of some variables */

** simplified age varaible with 3 categories
generate age_simple=1 if Age >= 20 & Age <=30
replace age_simple=2 if Age >= 31 & Age <=40
replace age_simple=3 if Age >= 41 & Age <=50
replace age_simple=4 if Age >=51 & Age <=60
replace age_simple=5 if Age >= 61 & Age <=70
replace age_simple=6 if Age >= 71 & Age <=80
replace age_simple=7 if Age >= 81 & Age <=85
*label
label define age_labels 1 "20 - 30 years" 2 "31 - 40 years" 3 " 41 - 50 years" 4 "51 - 60 years" 5 "61 - 70 years" 6 " 71 - 80 years" 7 "81 - 85 years", replace
label values age_simple age_labels
tab age_simple

** simplified edu varaible with 5 categories
generate edu_simple=1 if Patientseduqual == "00. No edu" | Patientseduqual == "02.Class 2" | Patientseduqual == "03.Class 3" | Patientseduqual== "04.Class 4" | Patientseduqual=="05.Class 5"
replace edu_simple=2 if Patientseduqual == "06.Class 6" | Patientseduqual == "07.Class 7" | Patientseduqual == "08.Class 8"
replace edu_simple=3 if Patientseduqual == "09.Class 9" | Patientseduqual == "10.SSC equiv" 
replace edu_simple=4 if Patientseduqual == "11.11th/equiv" | Patientseduqual == "12. 12th/HSC equiv"
replace edu_simple=5 if Patientseduqual == "13.Hons/equiv(running)" | Patientseduqual == "14.Hons/equiv(passed)" | Patientseduqual == "15.Post grad/equiv"
*label
label define edu_labels 1 "No or elementary" 2 "Middle school" 3 "High School" 4 "College" 5 "University", replace
label values edu_simple edu_labels
tab edu_simple

/* simplified stage varaible with 3 categories - QUESTION 4 - How to convert stage 1 
and 2 to the advanced stages? Answer: No need to convert. Keep it as you have done it*/
generate stage_simple=1 if stage == "01.1st" | stage == "02. 2nd"
replace stage_simple=2 if stage == "03.3rd" | stage == "04.4th"
replace stage_simple=3 if stage == "05.Dont know"
*label
label define stage_labels 1 "Early Stage" 2 "Advanced" 3 "Don't Know", replace
label values stage_simple stage_labels
tab stage_simple

// simplified previous facilities visited
generate prev_facilities_simple=1 if prev_facilities == 1
replace prev_facilities_simple=2 if prev_facilities == 2
replace prev_facilities_simple=3 if prev_facilities == 3
replace prev_facilities_simple=4 if prev_facilities == 4
replace prev_facilities_simple=5 if prev_facilities >= 5
*label
label define prev_facilities_simple_labels 1 "One" 2 "Two" 3 "Three" 4 "Four" 5 "More Than or Equal to Five", replace
label values prev_facilities_simple prev_facilities_simple_labels
tab prev_facilities_simple

// simplified family  income
generate income_simple=1 if patientsavgfamilyincome < 15000
replace income_simple=2 if patientsavgfamilyincome >= 15000 & patientsavgfamilyincome <=30000
replace income_simple=3 if patientsavgfamilyincome > 30000
*label
label define income_simple_labels 1 "<15000" 2 "15,000 – 30,000" 3 "> 30,000", replace
label values income_simple income_simple_labels
tab income_simple

/* Generating yearly direct costs variables */

* medical
ta months_from_diag if months_from_diag < 1
drop if months_from_diag < 1 & months_from_diag > 0
generate monthly_medical_cost = medical_cost / months_from_diag
generate yearly_medical_cost = monthly_medical_cost * 12

* food and acc
generate monthly_food_acc_cost = accomo_food / months_from_diag
generate yearly_food_acc_cost = monthly_food_acc_cost * 12

* transport
generate monthly_transport_cost = transport / months_from_diag
generate yearly_transport_cost = monthly_transport_cost * 12

* other
generate monthly_other_cost = Otherexpnensesrelatedtoc / months_from_diag
generate yearly_other_cost = monthly_other_cost * 12

* intangible cost - convert months from diagnosis into year for convenience - then calculate yearly intangible cost
gen intangible_cost_yearly = intangible_cost / years_from_diag

* Genrate advanced_stage_while_detected variable */
gen Advanced_stage_while_detected = 1 if stage == "03.3rd"
replace Advanced_stage_while_detected = 2 if stage == "04.4th"
* label
label define Advanced_stage_labels 1 "3rd stage" 2 "4th stage", replace
label values Advanced_stage_while_detected Advanced_stage_labels
tab Advanced_stage_while_detected






****************************** PART B: DATA ANALYSIS

/* ----------------------- Yearly Direct Cost Calculations ------------------------- */

// --------------------- BY OWNERSHIP -------------------------- //

// Direct Cost calculations - yearly data
* Yearly medical cost
sum yearly_medical_cost
sum yearly_medical_cost if ownership_ho == "Private Hospital"
sum yearly_medical_cost if ownership_ho == "Government Hospital"
// Yearly accomodation and food (inc attendant)
sum yearly_food_acc_cost
sum yearly_food_acc_cost if ownership_ho == "Private Hospital"
sum yearly_food_acc_cost if ownership_ho == "Government Hospital"
// yearly transportation cost (inc. attendant)
sum yearly_transport_cost
sum yearly_transport_cost if ownership_ho == "Private Hospital"
sum yearly_transport_cost if ownership_ho == "Government Hospital"
// Yearly other cost
sum yearly_other_cost
sum yearly_other_cost if ownership_ho == "Private Hospital"
sum yearly_other_cost if ownership_ho == "Government Hospital"

// --------------------- BY CANCER TYPE -------------------------- //
// Direct Cost calculations - yearly
* Medical cost
sum yearly_medical_cost if Typeofcancer == "01. Cervical Cancer"
sum yearly_medical_cost if Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if Typeofcancer == "03. Breast Cancer"
// Accomodation and food (inc attendant)
sum yearly_food_acc_cost if Typeofcancer == "01. Cervical Cancer"
sum yearly_food_acc_cost if Typeofcancer == "02. Oral Cancer"
sum yearly_food_acc_cost if Typeofcancer == "03. Breast Cancer"
// transportation cost (inc. attendant)
sum yearly_transport_cost if Typeofcancer == "01. Cervical Cancer"
sum yearly_transport_cost if Typeofcancer == "02. Oral Cancer"
sum yearly_transport_cost if Typeofcancer == "03. Breast Cancer"
// other cost
sum yearly_other_cost if Typeofcancer == "01. Cervical Cancer"
sum yearly_other_cost if Typeofcancer == "02. Oral Cancer"
sum yearly_other_cost if Typeofcancer == "03. Breast Cancer"

/* ----------------------- Yearly Indirect Cost Calculations ------------------------- */

// ------------------------- Health Loss ------------------------------------- //

// Average Age when detected - advanced
ta stage_simple
sum	Age
* avg. age if cervical - 47.05 years
sum	age_when_diagnosed if Typeofcancer== "01. Cervical Cancer" & stage_simple == 2
* avg. age if oral - 53.36 years
sum	age_when_diagnosed if Typeofcancer== "02. Oral Cancer" & stage_simple == 2
* avg. age if breast - 43.90 years
sum	age_when_diagnosed if Typeofcancer== "03. Breast Cancer" & stage_simple == 2
 
// Average Age when detected - early
ta stage_simple
* avg. age if cervical - 44.65 years
sum	age_when_diagnosed if Typeofcancer== "01. Cervical Cancer" & stage_simple == 1
* avg. age if oral - 49.59 years
sum	age_when_diagnosed if Typeofcancer== "02. Oral Cancer" & stage_simple == 1
* avg. age if breast - 43.44 years
sum	age_when_diagnosed if Typeofcancer== "03. Breast Cancer" & stage_simple == 1
 
// ------------------------- Earning Loss ------------------------------------- //
// indirect cost - current earning loss
* patient
sum annual_earning_loss_patient
* attendant 
sum total_annual_att_earning_loss

// ------------------------- Weights ------------------------------------- //
* Weights
tab Typeofcancer
gen total_samples = 343
gen weight_cervical = 112 / total_samples
gen weight_oral = 64 / total_samples
gen weight_breast = 167 / total_samples
* display
di weight_cervical
di weight_breast
di weight_oral

// ------------------------- Earning loss by cancer type ------------------------------------- //
// Current earning loss - Diease Wise
* patient
sum annual_earning_loss_patient if Typeofcancer == "02. Oral Cancer"
sum annual_earning_loss_patient if Typeofcancer == "03. Breast Cancer"
sum annual_earning_loss_patient if Typeofcancer == "01. Cervical Cancer"
* attendant 1
sum total_annual_att_earning_loss if Typeofcancer == "02. Oral Cancer"
sum total_annual_att_earning_loss if Typeofcancer == "03. Breast Cancer"
sum total_annual_att_earning_loss if Typeofcancer == "01. Cervical Cancer"

// ------------------------- Earning loss by cancer stage ------------------------------------- //

// Current earning loss - Stage wise
* patient
sum annual_earning_loss_patient if stage == "03.3rd"
sum annual_earning_loss_patient if stage == "04.4th"
* attendant
sum total_annual_att_earning_loss if stage == "03.3rd"
sum total_annual_att_earning_loss if stage == "04.4th"

// ------------------------- Earning loss by cancer stage and type ------------------------------------- //
// Stage 3
* patient
sum annual_earning_loss_patient if stage == "03.3rd" & Typeofcancer == "02. Oral Cancer"
sum annual_earning_loss_patient if stage == "03.3rd" & Typeofcancer == "03. Breast Cancer"
sum annual_earning_loss_patient if stage == "03.3rd" & Typeofcancer == "01. Cervical Cancer"
* attendant
sum total_annual_att_earning_loss if stage == "03.3rd" & Typeofcancer == "02. Oral Cancer"
sum total_annual_att_earning_loss if stage == "03.3rd" & Typeofcancer == "03. Breast Cancer"
sum total_annual_att_earning_loss if stage == "03.3rd" & Typeofcancer == "01. Cervical Cancer"

// Stage 4
* patient
sum annual_earning_loss_patient if stage == "04.4th" & Typeofcancer == "02. Oral Cancer"
sum annual_earning_loss_patient if stage == "04.4th" & Typeofcancer == "03. Breast Cancer"
sum annual_earning_loss_patient if stage == "04.4th" & Typeofcancer == "01. Cervical Cancer"
* attendant 1
sum total_annual_att_earning_loss if stage == "04.4th" & Typeofcancer == "02. Oral Cancer"
sum total_annual_att_earning_loss if stage == "04.4th" & Typeofcancer == "03. Breast Cancer"
sum total_annual_att_earning_loss if stage == "04.4th" & Typeofcancer == "01. Cervical Cancer"


/* ----------------------- Yearly Intangible Cost Calculations ------------------------- */

// Overall
sum intangible_cost_yearly

* By Cancer Type
sum intangible_cost_yearly if Typeofcancer == "02. Oral Cancer"
sum intangible_cost_yearly if Typeofcancer == "03. Breast Cancer"
sum intangible_cost_yearly if Typeofcancer == "01. Cervical Cancer"

* By Cancer Stage
sum intangible_cost_yearly if stage == "03.3rd"
sum intangible_cost_yearly if stage == "04.4th"

* Stage 3
sum intangible_cost_yearly if stage == "03.3rd" & Typeofcancer == "02. Oral Cancer"
sum intangible_cost_yearly if stage == "03.3rd" & Typeofcancer == "03. Breast Cancer"
sum intangible_cost_yearly if stage == "03.3rd" & Typeofcancer == "01. Cervical Cancer"
* Stage 4
sum intangible_cost_yearly if stage == "04.4th" & Typeofcancer == "02. Oral Cancer"
sum intangible_cost_yearly if stage == "04.4th" & Typeofcancer == "03. Breast Cancer"
sum intangible_cost_yearly if stage == "04.4th" & Typeofcancer == "01. Cervical Cancer"


/* ----------------------- Yearly Provider's Cost Calculations ------------------------- */

// Overall
sum yearly_medical_cost if ownership_ho == "Private Hospital"
sum yearly_medical_cost if ownership_ho == "Government Hospital"

// By Cancer Type
sum yearly_medical_cost if ownership_ho == "Private Hospital" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & Typeofcancer == "01. Cervical Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & Typeofcancer == "01. Cervical Cancer"

// By Cancer Stage
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "03.3rd"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "03.3rd"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "04.4th"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "04.4th"

// By Cancer Stage and Type
** Public
* Stage 3
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "03.3rd" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "03.3rd" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "03.3rd" & Typeofcancer == "01. Cervical Cancer"
* Stage 4
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "04.4th" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "04.4th" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "04.4th" & Typeofcancer == "01. Cervical Cancer"

** Private
* Stage 3
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "03.3rd" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "03.3rd" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "03.3rd" & Typeofcancer == "01. Cervical Cancer"
* Stage 4
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "04.4th" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "04.4th" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "04.4th" & Typeofcancer == "01. Cervical Cancer"
