
*** Note
* "w9_ISCED.xlsx" does not exist, so use "w8_ISCED.xlsx" to replace it

clear all

*** Define path
local path "F:\Hiwi\Data\Data Porcessing\Variables Preparation\ISCED Recoding"
local nums "1 2 4 5 6 7 8 9"



*** Step 1: check missing country codes & missing/non-numeric isced97 codes for columns C & H/I
** check missing country codes
foreach num of local nums {
    
	* save the sheet names of each excel file
    quietly import excel using "`path'\data\w`num'_ISCED.xlsx", describe
	local n_sheets `r(N_worksheet)'
	
	* convert excel format to dta format
	forvalues i = 1/`n_sheets' {
	    
		* open each sheet of each excel file
		local sheet`i' `r(worksheet_`i')'
		quietly import excel using "`path'\data\w`num'_ISCED.xlsx", sheet(`sheet`i'') clear
		
		if missing(A[1]) {
			display "missing country code: File: wave`num', Sheet: `sheet`i''"
		}
	}
}


** check missing isced97 codes for columns C & H/I
foreach num of local nums {
    
	* save the sheet names of each excel file
    quietly import excel using "`path'\data\w`num'_ISCED.xlsx", describe
	local n_sheets `r(N_worksheet)'
	
	* convert excel format to dta format
	forvalues i = 1/`n_sheets' {
	    
		* open each sheet of each excel file
		local sheet`i' `r(worksheet_`i')'
		quietly import excel using "`path'\data\w`num'_ISCED.xlsx", sheet(`sheet`i'') cellrange(A4) clear
		* save as dta format
		tempfile w`num'_`i'
		quietly save `w`num'_`i'', replace
	}

	* generate id_isced_left for each sheet
	local allcodes_`num' = ""
	local rightcodes_`num' = ""
	forvalues i = 1/`n_sheets' {
		
		* left table
		use `w`num'_`i'', clear
		gen left = (A >= 1 & A <= 90 & missing(C))
		quietly count if left == 1
		if r(N) > 0 {
			display "missing isced code: File: wave`num', Sheet: `sheet`i'', Table: left"
		}
		drop left
		
		* right table
		local ori = cond(`num' == 1 | `num' == 2 | `num' == 4, "F", "G")
		local new = cond(`num' == 1 | `num' == 2 | `num' == 4, "H", "I")
		gen right = (`ori' >= 1 & `ori' <= 90 & missing(`new'))
		quietly count if right == 1
		if r(N) > 0 {
			display "missing isced code: File: wave`num', Sheet: `sheet`i'', Table: right"
		}
		drop right
	}
}


** check non-numeric codes for columns C & H/I
foreach num of local nums {
    
	* save the sheet names of each excel file
    quietly import excel using "`path'\data\w`num'_ISCED.xlsx", describe
	local n_sheets `r(N_worksheet)'
	
	forvalues i = 1/`n_sheets' {
		
		* open each sheet of each excel file
		local sheet`i' `r(worksheet_`i')'
		quietly import excel using "`path'\data\w`num'_ISCED.xlsx", sheet(`sheet`i'') cellrange(A4) clear

        ** display the file-sheet name if columns C or H/I contains string values
		* check if wave is 1/2/4; if it is, consider column H; otherwise, I
		local suffix = cond(`num' == 1 | `num' == 2 | `num' == 4, "H", "I")
		
		foreach var of varlist C `suffix' {
		    
			* check if the variable is a string variable
			local varType: type `var'
			if strpos("`varType'", "str") > 0 {
			    
				* display if there are at least one string value
				gen flag = regexm(C, "[a-zA-Z]")
				quietly count if flag == 1
				if r(N) > 0 {
					display "non-numeric isced code: File: wave`num', Sheet: `sheet`i''"
				}
				drop flag
			}
        }	
    }
}



*** Step 2: append all sheets of all excel files
** create the variable id_isced for merging with the original dataset
foreach num of local nums {
    
	* save the sheet names of each excel file
    quietly import excel using "`path'\data\w`num'_ISCED.xlsx", describe
	local n_sheets `r(N_worksheet)'
	
	* convert excel format to dta format
	forvalues i = 1/`n_sheets' {
	    
		* open each sheet of each excel file
		local sheet`i' `r(worksheet_`i')'
		quietly import excel using "`path'\data\w`num'_ISCED.xlsx", sheet(`sheet`i'') clear
		* save as dta format
		tempfile w`num'_`i'
		quietly save `w`num'_`i'', replace
	}

	* generate id_isced_left for each sheet
	local allcodes_`num' = ""
	local rightcodes_`num' = ""
	forvalues i = 1/`n_sheets' {
		use `w`num'_`i'', clear
		
		* save the countrycode for each sheet
		/*
		if real(A[1]) == 24 {
            quietly replace A = "23" in 1
        }
		
        if real(A[1]) == 39 {
            quietly replace A = "15" in 1
        }
		*/
		local countrycode = A[1]
		
		* display `countrycode'
		local allcodes_`num' `allcodes_`num'' `countrycode'
		* display "`allcodes_`num''"
		
		* delete the first two rows
		quietly drop if strpos(B, "country code") > 0
		quietly drop if C == "ISCED_1997"

		
		** left
		preserve
		
		* generate id_isced_left
		quietly gen num_A = real(A)
		quietly keep if inrange(num_A, 1, 100)
		generate id_isced_left = "`num'" + "_" + "`countrycode'" + "_" + A
		
		* delete num_A and num_F 
		keep id_isced_left A C
		order id_isced_left A C
		
		* save the left table of each sheet
		tempfile `num'_`countrycode'_left
		quietly save ``num'_`countrycode'_left', replace
		
		
		** right
		restore
		
		* keep useful columns
		if inlist(`num', 1, 2, 4) {
			keep F H
		}
		else if inlist(`num', 5, 6, 7, 8, 9) {
			keep G I
			rename (G I) (F H)
		}

		* generate id_isced_right
		quietly gen num_F = real(F)
		quietly keep if inrange(num_F, 1, 100)
		drop num_F
		quietly destring F, replace
		
		* reshape the data format
		quietly summarize F, detail
		if r(N) > 0 {
			
			local rightcodes_`num' `rightcodes_`num'' `countrycode'
			* display "`rightcodes_`num''"
			
			sort F
			generate id_isced_right = "`num'" + "_" + "`countrycode'"
			quietly reshape wide H, i(id_isced_right) j(F)
			
			* save the right  table of each sheet
			tempfile `num'_`countrycode'_right
			quietly save ``num'_`countrycode'_right', replace
		}
	}
	
	** keep unique numbers of allcodes
	*display "w`num'_all: " "`allcodes_`num''"
	*display "w`num'_right:" "`rightcodes_`num''"
	local uniquecodes_`num'
	local uniqueright_`num'

	foreach code of local allcodes_`num' {
		if strpos(" `uniquecodes_`num'' ", " `code' ") == 0 {
			local uniquecodes_`num' "`uniquecodes_`num'' `code'"
		}
	}
	foreach code of local rightcodes_`num' {
		if strpos(" `uniqueright_`num'' ", " `code' ") == 0 {
			local uniqueright_`num' "`uniqueright_`num'' `code'"
		}
	}
	display "w`num'_unique: " "`uniquecodes_`num''"
	*display "w`num'_uniright: " "`uniqueright_`num''"
	
	** append all left tables of one excel file
	local first 0
	foreach code of local uniquecodes_`num' {
		if `first' == 0 {
			use ``num'_`code'_left', clear
			local first 1
		}
		else {
			quietly append using ``num'_`code'_left'
		}	
	}
	tempfile `num'_left
	quietly save ``num'_left', replace
	
	* append all right tables of one excel file
	local first 0
	foreach code of local uniqueright_`num' {
		if `first' == 0 {
			use ``num'_`code'_right', clear
			local first 1
		}
		else {
			quietly append using ``num'_`code'_right'
		}	
	}
	tempfile `num'_right
	quietly save ``num'_right', replace
	
}


** append all tables of all excel files 
* left tables
local first 0
foreach num of local nums {
	if `first' == 0 {
		use ``num'_left', clear
		local first 1
	}
	else {
		append using ``num'_left'
	}
}	
sort id_isced
egen count_id = count(id_isced_left), by(id_isced_left)
keep if count_id == 1
drop count_id
save "`path'\file\isced_left.dta", replace	

* right tables
local first 0
foreach num of local nums {
	if `first' == 0 {
		use ``num'_right', clear
		local first 1
	}
	else {
		append using ``num'_right'
	}
}	
sort id_isced
order id_isced_right H1 H2 H3 H4 H5 H6 H7 H8 H9 H10 H11 H12 H13 H14 H15 H16 H17 H18 H19 H20 H95 H96 H97
egen count_id = count(id_isced_right), by(id_isced_right)
keep if count_id == 1
drop count_id
save "`path'\file\isced_right.dta", replace



*** Step 3: generate the variable isced97
** merge the isced coderule datasets with the original dataset
* create id_isced for the original file
use "`path'\file\isced_original.dta", clear
generate dn010_num = dn010_
generate country_num = country
generate id_isced_left = string(wave) + "_" + string(country_num) + "_" + string(dn010_num)
generate id_isced_right = string(wave) + "_" + string(country_num)
drop country_num dn010_num
order mergeid id_isced_left id_isced_right

* merge the left dataset
merge n:1 id_isced_left using "`path'\file\isced_left.dta"
drop if _merge == 2
drop _merge 

* merge the right dataset
merge n:1 id_isced_right using "`path'\file\isced_right.dta"
drop if _merge == 2
drop _merge 
sort mergeid id_isced_left id_isced_right
save "`path'\isced_recode.dta", replace


** generate the variable isced97
use "`path'\isced_recode.dta", clear
gen isced97 = .
quietly destring A C H1-H20 H95-H97, replace force
		
* generate isced97 based on the left table
replace isced97 = C if !missing(A) & !missing(C)
replace isced97 = A if !missing(A) & missing(C) & !missing(id_isced_left)
* Note: !missing(C) contains !missing(id_isced_left): dn010_ == A & country == A1 & wave == filename number
	
* replace isced97 based on the right table	
forvalues i = 1/20 {
	replace isced97 = H`i' if dn012d`i' == 1 & !missing(H`i') & (H`i' > isced97 | isced97 == 97 | isced97 == .)
}
replace isced97 = 95 if missing(isced97) & dn012d95 == 1 & !missing(id_isced_right)
replace isced97 = 97 if (isced97 == . | isced97 == 0) & dn012dot == 1 & !missing(id_isced_right)
* Note: !missing(H`i') contains !missing(id_isced_right): country == A1 & wave == filename number

			
** Special case according to Step 1
* Germany - Wave 5
* left table
replace isced97 = 3 if country == 12 & wave == 5 & (dn010_ == 6 | dn010_ == 7) & (dn012d1 == 1 | dn012d95 == 1)
replace isced97 = 4 if country == 12 & wave == 5 & (dn010_ == 6 | dn010_ == 7) & (dn012d2 == 1 | dn012d3 == 1 | dn012d4 == 1 | dn012d5 == 1 | dn012d6 == 1 | dn012d7 == 1 | dn012d8 == 1 | dn012d9 == 1 | dn012d10 == 1 | dn012d11 == 1 | dn012d12 == 1 | dn012d13 == 1 | dn012d14 == 1 | dn012d15 == 1 | dn012d16 == 1 | dn012d17 == 1 | dn012d18 == 1 | dn012d19 == 1 | dn012dot == 1)
egen miss012 = rowmiss(dn012d*)
replace isced97 = 3 if country == 12 & wave == 5 & (dn010_ == 6 | dn010_ == 7) & miss012 == 23
drop miss012

* right table
replace isced97 = 2 if country == 12 & wave == 5 & (dn010_ >= 1 & dn010_ < 6) & dn012d2 == 1 
replace isced97 = 3 if country == 12 & wave == 5 & (dn010_ >= 1 & dn010_ < 6) & (dn012d3 == 1 | dn012d4 == 1 | dn012d5 == 1 | dn012d6 == 1 | dn012d7 == 1 | dn012d8 == 1)
replace isced97 = 2 if country == 12 & wave == 5 & isced97 == 97 & dn012d2 == 1 
replace isced97 = 3 if country == 12 & wave == 5 & isced97 == 97 & (dn012d3 == 1 | dn012d4 == 1 | dn012d5 == 1 | dn012d6 == 1 | dn012d7 == 1 | dn012d8 == 1)
replace isced97 = 5 if country == 12 & wave == 5 & (dn012d9 == 1 | dn012d10 == 1 | dn012d11 == 1 | dn012d12 == 1 | dn012d13 == 1 | dn012d14 == 1 | dn012d15 == 1 | dn012d16 == 1 | dn012d17 == 1 | dn012d18 == 1)
replace isced97 = 6 if country == 12 & wave == 5 & dn012d19 == 1
replace isced97 = 97 if country == 12 & wave == 5 & (isced97 == . | isced97 == 0) & dn012dot == 1
* Note: isced97 = 4 (see the code for the left table)

* save
keep mergeid wave country isced97 dn*
order mergeid wave country isced97 dn*
save "`path'\isced_recode.dta", replace



*** Step 4: compare with the original isced variable
merge 1:1 mergeid using "`path'\file\isced1997.dta"
order mergeid wave country isced97 isced1997
drop if isced97 == isced1997 | (isced97 == . & isced1997 == -1)




