
*******************************************
*******************************************

clear
/*
global C=6
colorpalette viridis, n($C)
return list
forvalue i=1/$C {
	global c`i'=r(p`i')
}
*/
set seed 6557

global WORK F:\Hiwi\Data\Data Porcessing\Replicates\Willis (2024)\SHARE_results

global matchyrs = 4
global cogvars word_immediate word_delay word_total series7 cognition25 memory_bad
global matchvars gender education agebin cogbin 

*******************************************
*******************************************

use "$WORK\database_SHARE.dta", replace

*******************************************
* exact matching
* one to one

* matching variables
egen agebin = cut(age2011), at(50(1)75)
*tabstat age98, by(agebin) s(min max n) mis
* average cog27 for first $matchyrs years
local ymin = 2011
local ymax = 2015
forvalue y = `ymin'(2)`ymax' {
	gen temp = cognition25 if wave_year ==`y'
	bysort mergeid: egen cognition`y' = mean(temp)
	cap drop temp*
}
egen temp = rowmean(cognition20*)
egen cogbin = cut(temp), at(7(1)25)
*tabstat cog27, by(cogbin) s(min max n) mis

* drop if any of match variables missing
foreach x of varlist $matchvars {
	drop if `x'==.
}

* create string form matchvars
foreach x of varlist $matchvars {
	tostring `x', gen(string_`x')
}
gen str10 string_matchvars = string_gender + string_education +string_agebin + string_cogbin
*compress
*tab strmatchvars,mis

preserve
	keep if wave_year == 2011
	gen matched_t=0 if demented_ever == 1
	* matched_treatment = 1, means have one matched observation
	gen matched_c=0 if demented_ever == 0
	gen demented_year_c=.
	* dementia_onset_year_control
	gen rand=runiform()
	gsort $matchvars -demented_ever rand
	save "$WORK\temp0",replace
	
	* 1st neighbor is match
	use "$WORK\temp0",replace
	local i=1
	replace matched_t=1 if matched_t==0 & demented_ever==1 & demented_ever[_n+`i']==0 & string_matchvars==string_matchvars[_n+`i']
	replace matched_c=1 if matched_c==0 & demented_ever==0 & demented_ever[_n-`i']==1 & string_matchvars==string_matchvars[_n-`i']
	replace demented_year_c = demented_year[_n-`i'] if matched_c==1 
	keep if matched_t==1 | matched_c==1
	save "$WORK\temp1",replace
	
	* 2nd neighbor is match
	use "$WORK\temp0",replace
	merge 1:1 mergeid using "$WORK\temp1", nogen keep(1)
	* drop if IDs are same as both datasets: drop the matched observations, and then match the left observations
	gsort $matchvars -demented_ever rand
	local i=1
	replace matched_t=1 if matched_t==0 & demented_ever==1 & demented_ever[_n+`i']==0 & string_matchvars==string_matchvars[_n+`i']
	replace matched_c=1 if matched_c==0 & demented_ever==0 & demented_ever[_n-`i']==1 & string_matchvars==string_matchvars[_n-`i']
	replace demented_year_c = demented_year[_n-`i'] if matched_c==1 
	keep if matched_t==1 | matched_c==1
	save "$WORK\temp2",replace
	
	* 3rd neighbor is match
	use "$WORK\temp0",replace
	merge 1:1 mergeid using "$WORK\temp1", nogen keep(1)
	merge 1:1 mergeid using "$WORK\temp2", nogen keep(1)
	gsort $matchvars -demented_ever rand
	local i=1
	replace matched_t=1 if matched_t==0 & demented_ever==1 & demented_ever[_n+`i']==0 & string_matchvars==string_matchvars[_n+`i']
	replace matched_c=1 if matched_c==0 & demented_ever==0 & demented_ever[_n-`i']==1 & string_matchvars==string_matchvars[_n-`i']
	replace demented_year_c = demented_year[_n-`i'] if matched_c==1 
	keep if matched_t==1 | matched_c==1
	save "$WORK\temp3",replace
	
	* 4th neighbor is match
	use "$WORK\temp0",replace
	merge 1:1 mergeid using "$WORK\temp1", nogen keep(1)
	merge 1:1 mergeid using "$WORK\temp2", nogen keep(1)
	merge 1:1 mergeid using "$WORK\temp3", nogen keep(1)
	gsort $matchvars -demented_ever rand
	local i=1
	replace matched_t=1 if matched_t==0 & demented_ever==1 & demented_ever[_n+`i']==0 & string_matchvars==string_matchvars[_n+`i']
	replace matched_c=1 if matched_c==0 & demented_ever==0 & demented_ever[_n-`i']==1 & string_matchvars==string_matchvars[_n-`i']
	replace demented_year_c = demented_year[_n-`i'] if matched_c==1 
	keep if matched_t==1 | matched_c==1
	save "$WORK\temp4",replace
	
	* 5th neighbor is match
	use "$WORK\temp0",replace
	merge 1:1 mergeid using "$WORK\temp1", nogen keep(1)
	merge 1:1 mergeid using "$WORK\temp2", nogen keep(1)
	merge 1:1 mergeid using "$WORK\temp3", nogen keep(1)
	merge 1:1 mergeid using "$WORK\temp4", nogen keep(1)
	gsort $matchvars -demented_ever rand
	local i=1
	replace matched_t=1 if matched_t==0 & demented_ever==1 & demented_ever[_n+`i']==0 & string_matchvars==string_matchvars[_n+`i']
	replace matched_c=1 if matched_c==0 & demented_ever==0 & demented_ever[_n-`i']==1 & string_matchvars==string_matchvars[_n-`i']
	replace demented_year_c = demented_year[_n-`i'] if matched_c==1 
	keep if matched_t==1 | matched_c==1
	save "$WORK\temp5",replace

	use "$WORK\temp1"
	append using "$WORK\temp2"
	append using "$WORK\temp3"
	append using "$WORK\temp4"
	append using "$WORK\temp5"
	keep mergeid rand matched* demented_year_c
	save "$WORK\matched",replace
	sort mergeid
	drop if mergeid==mergeid[_n-1]
	save "$WORK\matched",replace
restore

merge m:1 mergeid using "$WORK\matched", nogen
tab matched_t matched_c, mis
tab matched_t matched_c if wave_year == 2011, mis

/*
preserve
	keep if wavey==1998
	gsort $matchvars -demever rand
	lis hhidpn demever matched* strmatchvars demonsety* if _n<300 & demever==1 | demever[_n-1]==1 | demever[_n-2]==1 | demever[_n-3]==1 | demever[_n-4]==1
restore
*/

* GROUPS
gen group=0
 replace group=1 if matched_c==1
 replace group=2 if matched_t==1
 replace group=3 if demented_ever==1 & matched_t!=1
 lab def group 0 "unmatched non-dementia" 1 "matched control" 2 "matched dementia" 3 "unmatched dementia"
 lab val group group
tab wave_year group,mis


* EVENT TIME
*  years before dementia onset for ever demented 
*   or pseudo-intervention for non-treated
*   set pseudo-intervention to 2016 for unmatched never demented
gen t = wave_year - demented_year if demented_ever==1
 replace t = wave_year - demented_year_c if matched_c==1
*replace t = wave_year-201 if demented_ever==0 & matched_c!=1 /* unmatched get 2016 as the pseuto-intervention year */
 drop if t>0 & t<. 
 /* drop observations after pseudo intervention for matched controls */
tab t group,mis

save "$WORK\workfile",replace

******************************************
******************************************

* DESCRIBE DATA
use "$WORK\workfile", replace
gen baseline = wave_year == 2011

tabstat gender education age if baseline, s(min max mean sd n) c(s)
tab demented_ever if baseline
tab group if baseline

tabstat gender education age2011 cogbin, by(group) s(mean) 

******************************************
******************************************

* GRAPHS BY GROUP

foreach y in $cogvars {
	use "$WORK\workfile", replace
	collapse (mean) `y' (sd) sd`y'=`y' (count) n=`y', by(group t)
	* statistics
	gen `y'lo = `y' - 2*sd`y'/sqrt(n)
	gen `y'hi = `y' + 2*sd`y'/sqrt(n)
	* lower and upperbounds of the 95% confidence interval for the mean of y
	keep `y' `y'lo `y'hi t group
	reshape wide `y' `y'lo `y'hi, i(t) j(group) 
	twoway rarea `y'lo0 `y'hi0 t, lc(white) fc("$c1") fintens(30)  ///
	|| rarea `y'lo1 `y'hi1 t, lc(white) fc("$c3") fintens(30) 	///
	|| rarea `y'lo2 `y'hi2 t, lc(white) fc("$c6") fintens(30) 	///
	|| line `y'0 `y'1 `y'2 t, lw(thick thick thick) lc("$c1" "$c3" "$c6") ///
	 yla(, grid) ytitle("`y'") ///
	 xla(-12(2)0, grid) xtitle("Years before dementia onset") ///
	 legend(order(4 5 6) label(4 "Unmatched non-dementia group") ///
	  label(5 "Matched non-dementia group") label(6 "Dementia group") ///
	 ring(0) position(7) col(1) region(lstyle(none)))
	 graph export "$WORK/3groups-`y'-.png", replace
	more
}

/*
foreach y in selfmembad {
	use "$WORK\workfile", replace
	collapse (mean) `y' (sd) sd`y'=`y' (count) n=`y', by(group t)
	gen `y'lo = `y' - 2*sd`y'/sqrt(n)
	gen `y'hi = `y' + 2*sd`y'/sqrt(n)
	keep `y' `y'lo `y'hi t group
	reshape wide `y' `y'lo `y'hi, i(t) j(group) 
	twoway rarea `y'lo0 `y'hi0 t, lc(white) fc("$c1") fintens(30)  ///
	|| rarea `y'lo1 `y'hi1 t, lc(white) fc("$c3") fintens(30) 	///
	|| rarea `y'lo2 `y'hi2 t, lc(white) fc("$c6") fintens(30) 	///
	|| line `y'0 `y'1 `y'2 t, lw(thick thick thick) lc("$c1" "$c3" "$c6") ///
	 yla(0(0.2)0.6, grid) ytitle("`y'") ///
	 xla(-20(2)0, grid) xtitle("Years before dementia onset") ///
	 legend(order(6 5 4) label(4 "Unmatched non-dementia group") ///
	  label(5 "Matched non-dementia group") label(6 "Dementia group") ///
	 ring(0) position(7) col(1) region(lstyle(none)))
	 * graph export "$WORK/3groups-`y'-.png", replace
	more
}
*/

******************************************

* GRAPHS BY EDUCATION

foreach y in $cogvars {
	use "$WORK\workfile", replace
	keep if group==1 | group==2
	collapse (mean) `y' (sd) sd`y'=`y' (count) n=`y', by(group education t)
	gen `y'lo = `y' - 2*sd`y'/sqrt(n)
	gen `y'hi = `y' + 2*sd`y'/sqrt(n)
	keep `y' `y'lo `y'hi t group education
	reshape wide `y' `y'lo `y'hi, i(education t) j(group) 
	reshape wide `y'1 `y'lo1 `y'hi1 `y'2 `y'lo2 `y'hi2, i(t) j(education)
	twoway rarea `y'lo22 `y'hi22 t, lc(white) fc("$c5") fintens(40) ///
	|| rarea `y'lo12 `y'hi12 t, lc(white) fc("$c5") fintens(40) ///
	|| rarea `y'lo21 `y'hi21 t, lc(white) fc("$c3") fintens(30) ///
	|| rarea `y'lo11 `y'hi11 t, lc(white) fc("$c3") fintens(30) ///
	|| rarea `y'lo20 `y'hi20 t, lc(white) fc("$c1") fintens(20) ///
	|| rarea `y'lo10 `y'hi10 t, lc(white) fc("$c1") fintens(20) ///
	|| line `y'22 `y'12 `y'21 `y'11 `y'20 `y'10 t, lw(thick thick thick thick thick thick) lc("$c5" "$c5" "$c3" "$c3" "$c1" "$c1") ///
	lp(solid dash solid dash solid dash) ///
	yla(, grid) ytitle("`y'") ///
	xla(-12(2)0, grid) xtitle("Years before dementia onset") ///
	legend(order(3 4 5 6 7 8) ///
	label(3 "High educated, dementia") label(4 "High educated, matched control") ///
	label(5 "Medium educated, dementia") label(6 "Medium educated, matched control") ///
	label(7 "Low educated, dementia") label(8 "Low educated, matched control") ///
	ring(0) position(7) col(1) region(lstyle(none)))
	graph export "$WORK/ed-`y'-.png", replace
	more
}

/*
foreach y in selfmembad {
	use "$WORK\workfile", replace
	keep if group==1 | group==2
	collapse (mean) `y' (sd) sd`y'=`y' (count) n=`y', by(group highed t)
	gen `y'lo = `y' - 2*sd`y'/sqrt(n)
	gen `y'hi = `y' + 2*sd`y'/sqrt(n)
	keep `y' `y'lo `y'hi t group highed
	qui reshape wide `y' `y'lo `y'hi, i(highed t) j(group) 
	qui reshape wide `y'1 `y'lo1 `y'hi1 `y'2 `y'lo2 `y'hi2, i(t) j(highed) 
	twoway rarea `y'lo21 `y'hi21 t, lc(white) fc("$c5") fintens(30) ///
	|| rarea `y'lo11 `y'hi11 t, lc(white) fc("$c5") fintens(30) ///
	|| rarea `y'lo20 `y'hi20 t, lc(white) fc("$c2") fintens(20) ///
	|| rarea `y'lo10 `y'hi10 t, lc(white) fc("$c2") fintens(20) ///
	|| line `y'21 `y'11 `y'20 `y'10 t, lw(thick thick thick thick) lc("$c5" "$c5" "$c2" "$c2") ///
	 lp(solid dash solid dash) ///
	 yla(0(0.2)0.6, grid) ytitle("`y'") ///
	 xla(-20(2)0, grid) xtitle("Years before dementia onset") ///
	 legend(order(7 8 5 6) ///
	  label(5 "High educated, dementia") label(6 "High educated, matched control") ///
	  label(7 "Low educated, dementia") label(8 "Low educated, matched control") ///
	 ring(0) position(5) col(1) region(lstyle(none)))
	 * graph export "$WORK/ed-`y'-.png",replace
	more
}
*/