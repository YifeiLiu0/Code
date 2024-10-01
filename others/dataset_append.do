
*** define paths & collections

** define paths
local path "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Datasets Merge & Append\W8"
local path_data "F:\SHARE8"
local path_forloop "F:\SHARE8\w'i'"



** define collections
local num7s "8 7 6 5 4 2 1"
local num6s "8 7 6 5 4 2"
local num4s "8 7 6 5"

* Note: If you want to add more variables, add them here and at "main code - save variables".
local abcs "parents_migrant dn004_ dn010_ dn041_ isced2011_r"
local othvars "dn isced1997_r"






*** define functions & create new variables

** function: fill the values of a variable in a dataset using other datasets
capture program drop fill_w8

program fill_w8, rclass

	syntax, type(string) path_forloop(string) nums(string) dat(string) var(string)
	local master 0
	
	* fill values of a variable in a dataset
	foreach num of local nums { 
		
		* define for-loop path
		local path_loop = subinstr("`path_forloop'", "'i'", "`num'", .)
		
		* determine the dataset type
		if "`type'" == "temp" {
			local dataset "`w`num'_`dat''"
	    }
	    else {
			local dataset "`path_loop'\sharew`num'_rel8-0-0_`dat'.dta"
	    }
		
		* set the fisrt dataset as a master dataset 
	    if "`master'" == "0" {	
			use `dataset', clear
			
			keep mergeid `var'
			rename `var' `var'_final
	        sort mergeid
		    local master 1		
        }
		
		* merge other datasets to the master dataset
        else {
            merge 1:1 mergeid using `dataset'
		    drop if _merge == 2
			
			* replace values using other waves
			replace `var'_final = `var' if _merge == 3 & `var'_final == .
		    keep mergeid `var'_final  
        }
		
	}
	
	rename `var'_final  `var'
	tempfile `var'_fill
	save "``var'_fill'", replace
	local `abc'_fill "``var'_fill'"
	
end



** variable: parents' migrant background
foreach num4 of local num4s {
	
	* define for-loop path
	local path_loop = subinstr("`path_forloop'", "'i'", "`num4'", .)
	
	* keep variables needed
    use "`path_loop'\sharew`num4'_rel8-0-0_dn.dta", clear
    keep mergeid country dn504c dn505c

    * convert the variables into string type
    decode country, generate(country_compare)
    decode dn504c, generate(dn504c_compare)
    decode dn505c, generate(dn505c_compare)

    * create variables: migrant background of mother and father (migrant = 1, no migrant = 0, missing = .)
    gen mother = .
	replace mother = 1 if country_compare != dn504c_compare & !missing(dn504c_compare)
	replace mother = 0 if country_compare == dn504c_compare
	
    gen father = .
	replace father = 1 if country_compare != dn505c_compare & !missing(dn505c_compare)
	replace father = 0 if country_compare == dn505c_compare

    * create variable: migrant background of parents (both migrant = 2, one migrant = 1, no migrant = 0, one missing = nonmissing, both missing = .)
	gen parents_migrant = .
	replace parents_migrant = mother + father if !missing(mother) & !missing(father)
	replace parents_migrant = cond(missing(mother), father, mother) if missing(mother) & !missing(father) | !missing(mother) & missing(father)
	
	* add label and note
    label variable parents_migrant "migrant background of parents"
    notes parents_migrant: 0 = no migrant background; 1 = one of parents has migrant background; 2 = both parents have migrant background.

    * keep variables needed
    keep mergeid parents_migrant
	tempfile w`num4'_parents
    save `w`num4'_parents', replace
	
}












*** main code

** save variables
* filled variables: parents_migrant, born_country, education, education years, 2011 education code
fill_w8, type(temp) path_forloop(`path_forloop') nums(`num4s')  dat(parents) var(parents_migrant)
fill_w8, type(local) path_forloop(`path_forloop') nums(`num7s') dat(dn) var(dn004_)
fill_w8, type(local) path_forloop(`path_forloop') nums(`num7s') dat(dn) var(dn010_)
fill_w8, type(local) path_forloop(`path_forloop') nums(`num6s') dat(dn) var(dn041_)
fill_w8, type(local) path_forloop(`path_forloop') nums(`num4s') dat(gv_isced) var(isced2011_r)


* direct variables: country, age, gender, 1997 education code
use "`path_data'\w8\sharew8_rel8-0-0_dn.dta", clear
keep mergeid country dn003_ dn042_
tempfile dn_direct
save `dn_direct', replace

use "`path_data'\w8\sharew8_rel8-0-0_gv_isced.dta", clear
keep mergeid isced1997_r
tempfile isced1997_r_direct
save `isced1997_r_direct', replace



** merge all variables together
local first = 0

* merge direct variables
foreach othvar of local othvars {
	if "`first'" == "0" {
	    use "``othvar'_direct'", clear
	    sort mergeid
		local first 1
    }
    else {
		merge 1:1 mergeid using "``othvar'_direct'"
		drop _merge 
	}
}

* merge filled variables
foreach abc of local abcs {
	merge 1:1 mergeid using "``var'_fill'"
	drop _merge   
}

order mergeid country dn003_ dn042_ dn010_ dn041_ isced1997_r isced2011_r dn004_ parents_migrant
save "`path'\w8_fill.dta", replace







