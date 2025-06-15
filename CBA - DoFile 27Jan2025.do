clear
cd "C:\Users\HP\Desktop\2025\1. January\1. CBA Paper\CBA - Benefit"
import excel "C:\Users\HP\Desktop\2025\1. January\1. CBA Paper\CBA - Benefit\2. UGC cencer study dataset.xlsx", sheet("Main Data") firstrow

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
/* replace */
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
*br att_3_avg_income patients3rdattdsmainpr Hospitalname

/* Generating yearly indirect costs variables */
/* STEP 1: previous/current monthly income missing wages replaced by per capita income. 

Why: For patients and attendants who have 0 income, if we consider them 0, 
then their income will be underestimated. 
The work loss or study loss of housewives or students people also has a value. For people of
other profession with 0 income, there is a possibility that they hid their income intentionally.
Hence we will also replace their 0 income with per capita income. But for elderly and unemployed people, all
these assumptions (productive time, hid income) are not valid, we keep their income as 0.
We assume that per capita income roughly represetns that lost value and 
hence we replace the missing wages with per capita income. */
* PATIENT
ta Professionofpatient
*br patient_prev_income Professionofpatient if patient_prev_income == 0 & (Professionofpatient != "08.Unemployed" & Professionofpatient != "20.Elderly")
generate monthly_per_capita_inc = 24515
di monthly_per_capita_inc
sum patient_prev_income if patient_prev_income == 0 & (Professionofpatient != "08.Unemployed" & Professionofpatient != "20.Elderly")
replace patient_prev_income = monthly_per_capita_inc if patient_prev_income == 0 & (Professionofpatient != "08.Unemployed" & Professionofpatient != "20.Elderly")
* Should make 238 real changes
*br patient_prev_income Professionofpatient if patient_prev_income == 24515

* ATTENDANT 1
ta patients1stattdsmainpr
*br att_1_avg_income patients1stattdsmainpr if att_1_avg_income == 0 & (patients1stattdsmainpr != "08.Unemployed" & patients1stattdsmainpr != "20.Elderly")
sum att_1_avg_income if att_1_avg_income == 0 & (patients1stattdsmainpr != "08.Unemployed" & patients1stattdsmainpr != "20.Elderly")
replace att_1_avg_income = monthly_per_capita_inc if att_1_avg_income == 0 & (patients1stattdsmainpr != "08.Unemployed" & patients1stattdsmainpr != "20.Elderly")
* should make 169 real changes
*br att_1_avg_income patients1stattdsmainpr if att_1_avg_income == 24515

* ATTENDANT 2 - Child as a profession ache
ta patients2ndattdsmainpr
*br att_2_avg_income patients2ndattdsmainpr if att_2_avg_income == 0 & (patients2ndattdsmainpr != "08.Unemployed" & patients2ndattdsmainpr != "20.Elderly" & patients2ndattdsmainpr != "19.Child")
sum att_2_avg_income if att_2_avg_income == 0 & (patients2ndattdsmainpr != "08.Unemployed" & patients2ndattdsmainpr != "20.Elderly" & patients2ndattdsmainpr != "19.Child")
replace att_2_avg_income = monthly_per_capita_inc if att_2_avg_income == 0 & (patients2ndattdsmainpr != "08.Unemployed" & patients2ndattdsmainpr != "20.Elderly" & patients2ndattdsmainpr != "19.Child")
* should make 57 real changes
*br att_2_avg_income patients2ndattdsmainpr if att_2_avg_income == 24515

* ATTENDANT 3
ta patients3rdattdsmainpr
*br att_3_avg_income patients3rdattdsmainpr if att_3_avg_income == 0
sum att_3_avg_income if att_3_avg_income == 0
replace att_3_avg_income = monthly_per_capita_inc if att_3_avg_income == 0
* should make 1 real changes
*br att_3_avg_income patients3rdattdsmainpr if att_3_avg_income == 24515
/* QUESTION 7: Should I replace 0 income with per capita income for people of 
all professions or students and housewives only? 
Answer: Only keep 0 for elderly, unemployed and child. For other professions, 
people do not want to mention income, so keeping it zero would understate it. 
So replace with per capita income */

/* STEP 2: For calculating annual indriect cost - we need annual work month lost.
We need annual workmonth lost for patient and annual workdays lost for attendants.

How: we have data for ditection duration and total work month lost. 
Sometimes the total work month lost (months_without_work) > detection duration (months_from_diag) 
cause patient couldn't work due to sympotoms of the disease while the disease was not 
detected yet. We used the unitary method to calculate annual workmonth loss 
by generating the following variable */
/* but the problem is when months_without_work > months_from_diag, 
the value is irrational. In those cases we replaced months_from_detection 
by months_without_work (the larger value) considering the fact that though 
cancer was not diagnosed yet, the patient couldn;t work due to the illness. */
*br months_without_work months_from_diag
egen new_months_from_diag = rowmax(months_from_diag months_without_work)
*br months_without_work months_from_diag new_months_from_diag
gen annual_workmonth_lost_patient = (months_without_work * 12) / new_months_from_diag
*br months_without_work months_from_diag new_months_from_diag annual_workmonth_lost_patient
* convert months from diagnosis into days and years for convenience - 30.4375 days in a month on average
gen days_from_diag = months_from_diag * 30.4375
gen years_from_diag = months_from_diag / 12
gen age_when_diagnosed = Age - years_from_diag
* Attendant 1 - calculate workdays missed in a year - 365.25 days in a year on average, adjusted for leap years
gen annual_workdays_lost_att1 = (att1_days_missed_work / days_from_diag) * 365.25
*br att1_days_missed_work days_from_diag annual_workdays_lost_att1
* Attendant 2 - calculate workdays missed in a year - 365.25 days in a year on average, adjusted for leap years
gen annual_workdays_lost_att2 = (att2_days_missed_work / days_from_diag) * 365.25
* Attendant 3 - calculate workdays missed in a year - 365.25 days in a year on average, adjusted for leap years
gen annual_workdays_lost_att3 = (att3_days_missed_work / days_from_diag) * 365.25

/* Generate weights - QUESTION 3 - Should I calculate the weighted average? 
Answer: Calculate per patient total attendant cost*
ATTENDANT EARNING LOSS */

*br Nameofpatient att_1_avg_income att_2_avg_income att_3_avg_income

** Generate per day income for the attendants **
gen income_per_day_att1 = att_1_avg_income/30.4375
gen income_per_day_att2 = att_2_avg_income/30.4375
gen income_per_day_att3 = att_3_avg_income/30.4375
*br Nameofpatient att_1_avg_income income_per_day_att1 att_2_avg_income income_per_day_att2 att_3_avg_income income_per_day_att3
** Per day income and days missed work
*br Nameofpatient income_per_day_att1 att1_days_missed_work annual_workdays_lost_att1
*br Nameofpatient income_per_day_att1 annual_workdays_lost_att1 income_per_day_att2 annual_workdays_lost_att2 income_per_day_att3 annual_workdays_lost_att3
** Calculate income loss for each attendant
gen annual_income_loss_att1 = income_per_day_att1 * annual_workdays_lost_att1
gen annual_income_loss_att2 = income_per_day_att2 * annual_workdays_lost_att2
gen annual_income_loss_att3 = income_per_day_att3 * annual_workdays_lost_att3
* br Nameofpatient income_per_day_att1 annual_workdays_lost_att1 annual_income_loss_att1
* br Nameofpatient income_per_day_att3 annual_workdays_lost_att3 annual_income_loss_att3

** Calculate total annual income loss per patient
egen total_annual_att_earning_loss = rowtotal(annual_income_loss_att1 annual_income_loss_att2 annual_income_loss_att3)
br Nameofpatient annual_income_loss_att1 annual_income_loss_att2 annual_income_loss_att3 total_annual_att_earning_loss 
** Calculate average annual income loss for attendants
sum total_annual_att_earning_loss

** PATIENT EARNING LOSS
* Calculate Total Annual Earning Loss Patient
gen annual_earning_loss_patient = patient_prev_income * annual_workmonth_lost_patient
*br Nameofpatient patient_prev_income annual_workmonth_lost_patient annual_earning_loss_patient
* Calculate Average Annual Earning Loss
sum annual_earning_loss_patient

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
/* medical - QUESTION 5: Should I drop the observation less than 1 or 
should I replace those values with 1? Anwer: Yes */
ta months_from_diag if months_from_diag < 1
drop if months_from_diag < 1 & months_from_diag > 0
generate monthly_medical_cost = medical_cost / months_from_diag
generate yearly_medical_cost = monthly_medical_cost * 12
*br months_from_diag medical_cost monthly_medical_cost yearly_medical_cost Nameofpatient 
* QUESTION 6: Is this a correct way to get yearly medical cost? Answer: Yes

* food and acc
generate monthly_food_acc_cost = accomo_food / months_from_diag
generate yearly_food_acc_cost = monthly_food_acc_cost * 12
*br months_from_diag accomo_food monthly_food_acc_cost yearly_food_acc_cost Nameofpatient 
* transport
generate monthly_transport_cost = transport / months_from_diag
generate yearly_transport_cost = monthly_transport_cost * 12
*br months_from_diag transport monthly_transport_cost yearly_transport_cost Nameofpatient 
* other
generate monthly_other_cost = Otherexpnensesrelatedtoc / months_from_diag
generate yearly_other_cost = monthly_other_cost * 12
*br months_from_diag Otherexpnensesrelatedtoc monthly_other_cost yearly_other_cost Nameofpatient 

* intangible cost - convert months from diagnosis into year for convenience - then calculate yearly intangible cost
gen intangible_cost_yearly = intangible_cost / years_from_diag
*br intangible_cost years_from_diag intangible_cost_yearly

/* For Table 3 - stagewise calculation - current stage for all the patients is advanced stage 
by assumption we consider that since there is no screening program in BD now so most of the 
cancer cases are detected on advanced stage 
(show percentage by "tab stage - table 2 row 2". As most cases are detected advanced, 
now we calculate the cost of per cancer case. We have data from patients who were 
in advanced stage (3/4) while detected. Cconsidering 191 cases for cost calculation
 - generate a new variable - no need to generate actually

* Advanced_stage_while_detected is same as stage variable */
gen Advanced_stage_while_detected = 1 if stage == "03.3rd"
replace Advanced_stage_while_detected = 2 if stage == "04.4th"
label define Advanced_stage_labels 1 "3rd stage" 2 "4th stage", replace
label values Advanced_stage_while_detected Advanced_stage_labels
tab Advanced_stage_while_detected
*------------------------------------------------------------------------------------

/* ----------------------- Yearly Direct Cost Calculations ------------------------- */

// --------------------- Table 1 -------------------------- //

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

// --------------------- Table 2 -------------------------- //
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

// --------------------- Table 3 -------------------------- //
// Direct Cost calculations 
* Medical cost
sum yearly_medical_cost if stage == "01.1st"
sum yearly_medical_cost if stage == "02. 2nd"
sum yearly_medical_cost if stage == "03.3rd"
sum yearly_medical_cost if stage == "04.4th"

// Accomodation and food (inc attendant)
sum yearly_food_acc_cost if stage == "01.1st"
sum yearly_food_acc_cost if stage == "02. 2nd"
sum yearly_food_acc_cost if stage == "03.3rd"
sum yearly_food_acc_cost if stage == "04.4th"

// transportation cost (inc. attendant)
sum yearly_transport_cost if stage == "01.1st"
sum yearly_transport_cost if stage == "02. 2nd"
sum yearly_transport_cost if stage == "03.3rd"
sum yearly_transport_cost if stage == "04.4th"

// other cost
sum yearly_other_cost if stage == "01.1st"
sum yearly_other_cost if stage == "02. 2nd"
sum yearly_other_cost if stage == "03.3rd"
sum yearly_other_cost if stage == "04.4th"

// --------------------- Table 4 -------------------------- //
// Stage 3
* Medical cost
sum yearly_medical_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "01. Cervical Cancer"

// Accomodation and food (inc attendant)
sum yearly_food_acc_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "02. Oral Cancer"
sum yearly_food_acc_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "03. Breast Cancer"
sum yearly_food_acc_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "01. Cervical Cancer"

// transportation cost (inc. attendant)
sum yearly_transport_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "02. Oral Cancer"
sum yearly_transport_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "03. Breast Cancer"
sum yearly_transport_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "01. Cervical Cancer"

// other cost
sum yearly_other_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "02. Oral Cancer"
sum yearly_other_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "03. Breast Cancer"
sum yearly_other_cost if Advanced_stage_while_detected == 1 & Typeofcancer == "01. Cervical Cancer"

// Stage 4
* Medical Cost
sum yearly_medical_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "01. Cervical Cancer"

// Accomodation and food (inc attendant)
sum yearly_food_acc_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "02. Oral Cancer"
sum yearly_food_acc_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "03. Breast Cancer"
sum yearly_food_acc_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "01. Cervical Cancer"

// transportation cost (inc. attendant)
sum yearly_transport_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "02. Oral Cancer"
sum yearly_transport_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "03. Breast Cancer"
sum yearly_transport_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "01. Cervical Cancer"

// other cost
sum yearly_other_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "02. Oral Cancer"
sum yearly_other_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "03. Breast Cancer"
sum yearly_other_cost if Advanced_stage_while_detected == 2 & Typeofcancer == "01. Cervical Cancer"

/* ----------------------- Yearly Indirect Cost Calculations ------------------------- */
// ------------------------- Table 1 ------------------------------------- //
* Life Expectancy 73.70 - World Bank 2022 - Didn't consider male female separate
* It will not overestimate, rather underestimate since women live longer
// ------------------------- Table 2 ------------------------------------- //
// age - advanced
ta stage_simple
sum	Age
* avg. age if cervical - 47.05 years
sum	age_when_diagnosed if Typeofcancer== "01. Cervical Cancer" & stage_simple == 2
* avg. age if oral - 53.36 years
sum	age_when_diagnosed if Typeofcancer== "02. Oral Cancer" & stage_simple == 2
* avg. age if breast - 43.90 years
sum	age_when_diagnosed if Typeofcancer== "03. Breast Cancer" & stage_simple == 2
 
// age - early
ta stage_simple
* avg. age if cervical - 44.65 years
sum	age_when_diagnosed if Typeofcancer== "01. Cervical Cancer" & stage_simple == 1
* avg. age if oral - 49.59 years
sum	age_when_diagnosed if Typeofcancer== "02. Oral Cancer" & stage_simple == 1
* avg. age if breast - 43.44 years
sum	age_when_diagnosed if Typeofcancer== "03. Breast Cancer" & stage_simple == 1
 
// ------------------------- Table 3 ------------------------------------- //
// indirect cost - current earning loss
* patient
sum annual_earning_loss_patient
* attendant 
sum total_annual_att_earning_loss

// ------------------------- Table 4 ------------------------------------- //
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

// ------------------------- Table 6 ------------------------------------- //
// Current earning loss - Diease Wise
* patient
sum annual_earning_loss_patient if Typeofcancer == "02. Oral Cancer"
sum annual_earning_loss_patient if Typeofcancer == "03. Breast Cancer"
sum annual_earning_loss_patient if Typeofcancer == "01. Cervical Cancer"
* attendant 1
sum total_annual_att_earning_loss if Typeofcancer == "02. Oral Cancer"
sum total_annual_att_earning_loss if Typeofcancer == "03. Breast Cancer"
sum total_annual_att_earning_loss if Typeofcancer == "01. Cervical Cancer"

// ------------------------- Table 7 ------------------------------------- //

// Current earning loss - Stage wise
* patient
sum annual_earning_loss_patient if stage == "03.3rd"
sum annual_earning_loss_patient if stage == "04.4th"
* attendant
sum total_annual_att_earning_loss if stage == "03.3rd"
sum total_annual_att_earning_loss if stage == "04.4th"

// ------------------------- Table 7 ------------------------------------- //
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

// Table 1
sum intangible_cost_yearly

* Type
sum intangible_cost_yearly if Typeofcancer == "02. Oral Cancer"
sum intangible_cost_yearly if Typeofcancer == "03. Breast Cancer"
sum intangible_cost_yearly if Typeofcancer == "01. Cervical Cancer"

* Stage
sum intangible_cost_yearly if stage == "03.3rd"
sum intangible_cost_yearly if stage == "04.4th"

// Table 2
* Stage 3
sum intangible_cost_yearly if stage == "03.3rd" & Typeofcancer == "02. Oral Cancer"
sum intangible_cost_yearly if stage == "03.3rd" & Typeofcancer == "03. Breast Cancer"
sum intangible_cost_yearly if stage == "03.3rd" & Typeofcancer == "01. Cervical Cancer"
* Stage 4
sum intangible_cost_yearly if stage == "04.4th" & Typeofcancer == "02. Oral Cancer"
sum intangible_cost_yearly if stage == "04.4th" & Typeofcancer == "03. Breast Cancer"
sum intangible_cost_yearly if stage == "04.4th" & Typeofcancer == "01. Cervical Cancer"


/* ----------------------- Yearly Provider's Cost Calculations ------------------------- */

// Table 1
sum yearly_medical_cost if ownership_ho == "Private Hospital"
sum yearly_medical_cost if ownership_ho == "Government Hospital"

// Table 2
sum yearly_medical_cost if ownership_ho == "Private Hospital" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & Typeofcancer == "02. Oral Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & Typeofcancer == "03. Breast Cancer"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & Typeofcancer == "01. Cervical Cancer"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & Typeofcancer == "01. Cervical Cancer"

// Table 3
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "03.3rd"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "03.3rd"
sum yearly_medical_cost if ownership_ho == "Private Hospital" & stage == "04.4th"
sum yearly_medical_cost if ownership_ho == "Government Hospital" & stage == "04.4th"

// Table 4
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
