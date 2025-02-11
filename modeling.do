
*** Content
* Step 1: Preparation (Line 12)
* Step 2: Build the Database (Line 26)
* Step 3: Build Measures of Cognition Decline (Line 130)
* Step 4: Statistics (Line 249)





*** Step 1: Preparation

** define collections
local datas "dn cf"
local nums "9 8 7 6 5 4"

** define paths
local path "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Replicates\Kézdi & Willis (2014)"
local path_data "F:\SHARE8"





*** Step 2: Build the Database

** Select Var: delete irrelevant variables for each wave (4-9) of dn and cf module
foreach num of local nums {
    
    * define file suffix based on `num`
    local suffix = cond(`num' == 9, "_rel0", "_rel8-0-0")

    * process dn module
    use "`path_data'\w`num'\sharew`num'`suffix'_dn.dta", clear
    keep mergeid dn002_ dn003_
    tempfile w`num'_dn
    save `w`num'_dn', replace

    * process cf module
    use "`path_data'\w`num'\sharew`num'`suffix'_cf.dta", clear
    keep mergeid cf104tot cf105tot cf106tot cf107tot cf108_ cf109_ cf110_ cf111_ cf112_ cf113tot cf114tot cf115tot cf116tot
    tempfile w`num'_cf
    save `w`num'_cf', replace
	
}


** Wave Indicator: add wave indicator variable for each wave (4-9) of dn and cf module
foreach data of local datas {
	foreach num of local nums { 
	    
        * open datasets
		use `w`num'_`data'', clear

        * create indicator variable 
        gen wave = `num'
		label variable wave "Wave indicator"
		
		* save datasets
		tempfile w`num'_`data'_indicator
		save `w`num'_`data'_indicator', replace	
		
	}
}


** Append: append all waves (4-9)  together for dn and cf module, respectively
foreach data of local datas {
    local first 0
	foreach num of local nums {
		if `first' == 0 {
			use `w`num'_`data'_indicator', clear
			local first 1
		}
		else {
			append using `w`num'_`data'_indicator'
		}
	}
		
	tempfile `data'_w4w9
	save ``data'_w4w9', replace
}


** Merge: merge appended cf and dn datasets together
use `dn_w4w9', clear
sort mergeid wave
local master 1
merge 1:1 mergeid wave using `cf_w4w9'
keep if _merge == 3
drop _merge  

* create age variable
recode wave (4 = 2011) (5 = 2013) (6 = 2015) (7 = 2017) (8 = 2019) (9 = 2021), generate(interview_year)
label variable interview_year "Wave interview year" 

gen age = interview_year - dn003_
label variable age "Age at the time of interview"

* create score variables of series 7 tests
gen sub1 = (cf108_ == 93)
gen sub2 = (cf109_ == 86)
gen sub3 = (cf110_ == 79)
gen sub4 = (cf111_ == 72)
gen sub5 = (cf112_ == 65)

gen series7 = sub1 + sub2 + sub3 + sub4 + sub5
label variable series7 "Sum of series 7 tests scores"

* create score sum variables
egen first10 = rowtotal(cf104tot cf105tot cf106tot cf107tot), missing
label variable first10 "Sum of ten words first trail"

egen delay10 = rowtotal(cf113tot cf114tot cf115tot cf116tot), missing
label variable delay10 "Sum of ten words delayed trail"

egen score_sum = rowtotal(series7 first10 delay10), missing
label variable score_sum "Sum of the three tests scores"

* order the variables
order wave mergeid age score_sum series7 first10 delay10 
tempfile cf_merge
save "`path'\database.dta", replace





*** Step 3: Build Measures of Cognition Decline (2 methods) 

** functions

* Method in Agarwal et al. (2009): for one test, calculate the average slope for each age group
* (group1: 50&52; group2: 51&53;...;groupn:119&121)
capture program drop construct_slope
program construct_slope, rclass
    args test
	
	gen slope_construct_`test' = .
	gen ave_slope_cons_`test' = .

	forvalues i = 50/119 {
		local j = `i' + 2
			
		* count occurrences of mergeid for the age pair
		egen id_count = count(mergeid) if (age == `i' | age == `j'), by(mergeid)

		* build the id_list of unique mergeids where id_count = 2
		quietly levelsof mergeid if id_count == 2, local(mergeid_list)

		* calculate the slope for each mergeid where id_count = 2
		foreach mergeid of local mergeid_list {
			
			* calculate individual slope
			quietly sum `test' if mergeid == "`mergeid'" & age == `i'
			local score1 = r(mean)
			quietly sum `test' if mergeid == "`mergeid'" & age == `j'
			local score2 = r(mean)

			* add the value to the dataset
			replace slope_construct_`test' = (`score2' - `score1') / 2 if id_count == 2 & mergeid == "`mergeid'" & age == `i'
			
		}

		* calculate the average slope for the group
		sum slope_construct_`test' if id_count == 2 & age == `i'
		replace ave_slope_cons_`test' = r(mean) if age == `i' & first

		* drop the temporary variables for this iteration
		drop id_count
		
	}
		
end		



* Method in Kézdi & Willis (2014): for each individual, regress their test score on age and get the coefficient slope
capture program drop regression_slope
program regression_slope, rclass
    args test num
	
	gen slope_regress_`test' = .
	
	forvalues i = `num'/6 {
	
		* save unique mergeids
		quietly levelsof mergeid if id_count == `i', local(mergeid_list)
		
		* generate a regression slope for each mergeid
		foreach mergeid of local mergeid_list {
			quietly reg `test' age if mergeid == "`mergeid'" 
			replace slope_regress_`test' = _b[age] if mergeid == "`mergeid'" & first
		}
	
	}
	
end		



** Method 1: constructed slope		
use "`path'\database", clear

* only keep target age group
drop if age < 50 | age > 200
* sum age

* mark when each age first appears
bysort age: gen first = _n == 1
	
* call function
* Note: If you want to add more tests' construct_slope, add them here
construct_slope score_sum

* drop the temporary variables
drop first
save "`path'\construct_slope.dta", replace



** Method 2: regression slope		
use "`path'\database", clear

* only keep target age group
drop if age < 50 | age > 200
keep if !missing(score_sum)

* only keep mergeids with three or more observations
egen id_count = count(mergeid), by(mergeid)
keep if id_count >= 3

* mark when each mergeid first appears
bysort mergeid: gen first = _n == 1

* call function
* Note: If you want to add more tests' regression_slope, add them here
regression_slope score_sum 3

* drop the temporary variables
drop first
save "`path'\regress_slope", replace





*** Step 4: Statistics - Replication for Figures and Graphs

** Merge: merge construct_slope.dta and regress_slope.dta together
use "`path'\construct_slope.dta", clear
sort mergeid wave
merge 1:1 mergeid wave using "`path'\regress_slope.dta"
keep wave mergeid age score_sum slope_construct_score_sum ave_slope_cons_score_sum slope_regress_score_sum
egen id_count = count(mergeid), by(mergeid)
gen slope_regress_score_sum_full = cond(id_count == 6, slope_regress_score_sum, .)
save "`path'\replication.dta", replace
use "`path'\replication.dta", clear


** Replicate Tables: replicate the table - page 322: Table 9.3
quietly sum slope_construct_score_sum
local mean_con = string(r(mean), "%9.2f")

local sd_con = string(r(sd), "%9.2f")
* sum ave_slope_cons_score_sum
quietly sum slope_regress_score_sum
local mean_reg = string(r(mean), "%9.2f")
local sd_reg = string(r(sd), "%9.2f")


** Replicate Graphs: replicate the graph - page 323: Figure 9.5
twoway (histogram slope_construct_score_sum if slope_construct_score_sum >= -6 & slope_construct_score_sum <= 0, frequency width(1) fcolor(white) lcolor(black) lalign(center)) (histogram slope_construct_score_sum if slope_construct_score_sum >= 0 & slope_construct_score_sum <= 6, frequency width(1) color(black)) , ylabel(0(20000)60000, angle(horizontal) format(%9.0f)) xlabel(-5(1)5) plotregion(color(white)) graphregion(color(white)) legend(order(1 "Observations w/ negative change" 2 "Observations w/ positive change") nobox rows(2)) ytitle("Number of observations") xtitle("Wave-to-wave changes in the 4-test cognitive score," "normalized by age change")

twoway (histogram slope_regress_score_sum if slope_regress_score_sum >= -4 & slope_regress_score_sum <= 0, frequency width(1) fcolor(white) lcolor(black) lalign(center)) (histogram slope_regress_score_sum_full if slope_regress_score_sum_full >= -2 & slope_regress_score_sum_full <= 0, frequency width(1) fcolor(gs14) lcolor(black) lalign(center)) (histogram slope_regress_score_sum if slope_regress_score_sum > 0 & slope_regress_score_sum <= 4, frequency width(1) color(black)) (histogram slope_regress_score_sum_full if slope_regress_score_sum_full > 0 & slope_regress_score_sum_full <= 2, frequency width(1) color(gs8)), ylabel(0(5000)35000, angle(horizontal) format(%9.0f)) xlabel(-3(1)3) plotregion(color(white)) graphregion(color(white)) legend(order(1 "All individuals w/ negative slope" 2 "7-obs. individuals w/ negative slope" 3 "All individuals w/ positive change" 4 "7-obs. individuals w/ positive change") nobox rows(4)) ytitle("Number of observations") xtitle("Estimated individual slope of cognitive score by age")


** Output LaTeX: output the table and graph into a latex file
texdoc init "`path'/replication.tex", replace
tex \documentclass{article}
tex \usepackage{stata}
tex \usepackage{multirow}
tex \usepackage{graphicx}
tex \usepackage{subcaption}
tex \usepackage[a4paper, left=2cm, right=2cm, top=2cm, bottom=2cm]{geometry}
tex  
tex \title{Replication of Kézdi \& Willis (2014)}
tex \author{}
tex \date{}
tex
tex \begin{document}
tex \maketitle
tex  

tex \section{Page 322}
tex \begin{table}[ht]
tex \centering
tex \caption{Summary statistics of the age-adjusted first difference in cognitive score and the age-adjusted slope of cognitive score}
tex \begin{tabular}{lcc}
tex \hline
tex & First difference$^{a}$ & Slope measure$^{b}$ \\
tex & (1) & (2) \\
tex \hline
tex Mean & `mean_con' & `mean_reg' \\
tex Standard deviation & `sd_con' & `sd_reg' \\
tex \hline
tex \end{tabular}
tex \end{table}
tex \footnotesize {$^{a}$ Wave-to-wave change in the cognitive score divided by wave-to-wave change in the age of the respondent.} \\
tex \footnotesize {$^{b}$ Estimated individual slopes of the cognitive score from individual-specific regressions on age at the time of the interview.}
tex  

tex \section{Page 323}
tex \begin{figure}[h]
tex \centering
tex \begin{subfigure}{0.47\linewidth}
tex \centering
tex \includegraphics[width=\linewidth]{sum_con.png}
tex \caption{First-differenced measure of cognitive decline}
tex \end{subfigure}%
tex \begin{subfigure}{0.47\linewidth}
tex \centering
tex \includegraphics[width=\linewidth]{sum_reg.png}
tex \caption{Individual slope measure of cognitive decline}
tex \end{subfigure}
tex \caption{Distributions of the individual measures of cognitive decline}
tex \end{figure}
tex  
tex \end{document}









