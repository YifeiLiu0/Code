
*** define paths
local path "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Preparation\Label Variables"
local path_data "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Preparation\Label Variables\Task"



*** main code
** convert the label variable into labels
import excel "`path_data'\variable_descriptions_final.xlsx", sheet("Sheet1") firstrow clear

forvalues i = 1 / `=_N' {
    local current_varname = variablename[`i']
    local current_label = label[`i']
	
    gen `current_varname' = .
    label variable `current_varname' "`current_label'"
}

drop variablename label
drop if missing(mergeid)

ds *BLM
foreach var of varlist `r(varlist)' {
    local basename = substr("`var'", 1, strlen("`var'") - 3)
    rename `var' `basename'blm
}
rename X_merge x_merge

foreach var of varlist x_merge vdori2 vdvis2 vdvis1z vdmde3 vdmde4z vdexf2z vdasp1z vdasp2z vdasp5z exf_eap exf_mean exf_median mergeid vdlfl4 vdmre2z vdasp4_newz normsample normsample_d  exf_meanblm exflogitblm {
    tostring `var', replace
}
save "`path'\variable_labels.dta", replace


** save the variables labels for the dataset
import delimited "`path_data'\blomtransformed_factorscores_29.01.24.csv", clear
foreach var of varlist _all {
    label variable `var' ""
}
save "`path'\blomtransformed_factorscores_29.01.24.dta", replace

use "`path'\variable_labels.dta", clear
append using "`path'\blomtransformed_factorscores_29.01.24.dta"
save "`path'\blomtransformed_factorscores_29.01.24.dta", replace









