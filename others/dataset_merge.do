
*** preparation

** define path
local path "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Datasets Merge\CF & PH DN CV"
local path_data "F:\SHARE8"

** define types
local dats "cf ph dn cv_r"
local nums "9 8 7 6 5 4 2 1"
local apps "1 2 4 5 6 7 8 9"

** create temporary filenames
local tempfile w`num'_cf_indicator `data'_w1_w8 cf_merge






*** define functions

** function: add wave indicator
capture program drop wave_indicator

program wave_indicator, rclass

    args dat nums path_data
	local first 1

    foreach num of local nums {    
        * open datasets
		if `num' == 9 {
			use "`path_data'\w`num'\sharew`num'_rel0_`dat'.dta", clear
		}
		else {
        use "`path_data'\w`num'\sharew`num'_rel8-0-0_`dat'.dta", clear
		}

        * create indicator variable
        gen wave = `num'
		order wave, first
		label variable wave "Wave indicator"
        
        * determine if this is the first file
        if `first' == 1 {
			local first 0
        }
        else {
            label drop _all
        }  
		
		drop language hhid`num' mergeidp`num' coupleid`num'
		save w`num'_`dat'_indicator, replace
    }
end



** function: append datasets
capture program drop append_datasets

program append_datasets, rclass

	args dat apps
	local second 1
	
	foreach app of local apps {
	    if `second' == 1 {
	        use "w`app'_`dat'_indicator", clear
	        local second 0
	    }
	    else {
	        append using "w`app'_`dat'_indicator"
	    }
	}
	
	save `dat'_w1_w8, replace
	
end



** function: merge datasets
capture program drop merge_datasets

program merge_datasets, rclass

	args dats
	local master 0
	
	foreach dat of local dats {
	    if "`master'" == "0" {
	        use "`dat'_w1_w8", clear
	        sort mergeid wave
		    local master 1
        }
        else {
            merge 1:1 mergeid wave using "`dat'_w1_w8"
		    keep if _merge == 3
		    drop _merge   
        }
	}
	
	save cf_merge, replace
	
end












*** main code

** append cf, ph, dn, cv, respectively
foreach dat of local dats {
	
	* add wave indicator
	wave_indicator `dat' "`nums'" "`path_data'"
	
	* append w1-w8
	append_datasets `dat' "`apps'"
	
}



** merge cf, ph, dn, cv
merge_datasets "`dats'"



** add frequency of respondent being interviewed
use cf_merge, clear
sort mergeid
egen frequency = count(mergeid), by(mergeid)
label variable frequency "Frequency of respondent being interviewed"


** keep hcap ids
sort mergeid
merge m:1 mergeid using "`path'\hcap_ids.dta"
keep if _merge == 3
drop _merge 
order wave mergeid country frequency
gsort -wave country mergeid
save "`path'\cf merge_w1-w8_hcapids", replace










