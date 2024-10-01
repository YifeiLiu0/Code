

** define paths
local path "C:\\Users\\一飞\\Desktop\\Yifei\\Data\\Data Porcessing\\Variables Preparation\\Parents Migrant Background"
local datasets "w5_dn w6_dn w7_dn w8_dn"
local waves "w5_dn w6_dn w7_dn"
local initial_dataset "w8_dn_miss"



** create temporary filenames
tempfile `d'_non w8_dn_miss `wave'_nonmiss `wave'_miss



** w5-w8 (dn): keep nonmissing data for each
foreach d in `datasets' {

    * open datasets
    use "`path'\\`d'.dta", clear

    * keep variables needed
    keep mergeid country dn004_ dn504c dn505c

    * convert the variables into string type
    decode country, generate(country_compare)
    decode dn504c, generate(dn504c_compare)
    decode dn505c, generate(dn505c_compare)

    * create new variables: migrant background of mother and father (migrant = 1, no migrant = 0, missing = .)
    gen mother = .
	replace mother = 1 if country_compare != dn504c_compare
	replace mother = 0 if country_compare == dn504c_compare
	
    gen father = .
	replace father = 1 if country_compare != dn505c_compare
	replace father = 0 if country_compare == dn505c_compare

    * create a new variable: migrant background of parents (both migrant = 2, one migrant = 1, no migrant = 0, one missing = 0, both missing = .)
	gen parents_migrant = .
	replace parents_migrant = mother + father if !missing(mother) & !missing(father)
	replace parents_migrant = cond(missing(mother), father, mother) if missing(mother) | missing(father)

    label variable parents_migrant "migrant background of parents"
    notes parents_migrant: 0 = no migrant background; 1 = one of parents has migrant background; 2 = both parents have migrant background.

    * delete other variables
    keep mergeid parents_migrant

    * save the new dataset
    save `d'_parents, replace
	
}
	


** w8 (dn): keep missing data
* open datasets
use "`path'\\w8_dn.dta", clear

* keep observations with missing data
keep if missing(dn504c) & missing(dn505c) 

* delete other variables
keep mergeid

* save the new dataset
save w8_dn_miss, replace



** keep nonmissing data (from other waves) of obeservations in w8 
foreach wave of local waves {
    
    * keep non-missing values for each wave
    use "`initial_dataset'", clear
    sort mergeid
    merge 1:1 mergeid using "`wave'_non"
    keep if _merge == 3
    drop _merge
    save `wave'_nonmiss, replace

    * keep the left missing values
    use "`initial_dataset'", clear
    sort mergeid
    merge 1:1 mergeid using "`wave'_non"
    keep if _merge == 1
    keep mergeid
    save `wave'_miss, replace

    * update initial dataset for the next iteration
    local initial_dataset = "`wave'_miss"
	
}


** appending the datasets together to get full w8_dn (parents migrant background)
use "w7_dn_miss", clear

foreach wave of local waves {
    append using `wave'_nonmiss
}

append using "w8_dn_non"
save "`path'\\w8_parent migrant.dta", replace

