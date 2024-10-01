
*** define paths
local path "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Statistics\Mean Score by Age"
local path_photo "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Statistics\Mean Score by Age\photo"



*** functions
** function: generate graphs of mean score per age group with 95% CI
capture program drop mean_agegroup
program mean_agegroup, rclass
    args meanvar path path_photo
	
	* Generate the average score by age
	egen `meanvar'_agegroup = mean(`meanvar'), by(age_group)

	* Generate the upper and low bound of the 95% CI variable
	gen high = .
	gen low = .

	* Loop commmand
	forvalues i = 1/5 {
		ci mean `meanvar' if age_group == `i'
		replace high = r(ub) if age_group == `i'
		replace low = r(lb) if age_group == `i'
	}

	* Sort by age and generate the two-way line plot
	sort age_group
	graph twoway (rcap low high age_group) (connected `meanvar'_agegroup age_group, color(navy) msize(small)), title("Mean Score (`meanvar') per Age with 95% CI") ytitle("Mean Score (`meanvar')") xtitle("Age Group") xlab(1 "65-69" 2 "70-74" 3 "75-79" 4 "80-84" 5 "85+", labsize(vsmall)) ylab(, labsize(vsmall) nogrid) graphregion(color(white)) bgcolor(white)
	
	graph export "`path_photo'\\`meanvar'_group.png", replace
	
	drop high low
	
end


** function: generate graphs of mean score per age with 95% CI
capture program drop mean_age
program mean_age, rclass
    args meanvar path path_photo
	
	* Generate the average score by age
	egen `meanvar'_age = mean(`meanvar'), by(age2022)

	* Generate the upper and low bound of the 95% CI variable
	gen high = .
	gen low = .

	* Loop commmand
	quietly levelsof age2022, local(ages)
	foreach age of local ages {
		ci mean `meanvar' if age2022 == `age'
		replace high = r(ub) if age2022 == `age'
		replace low = r(lb) if age2022 == `age'
	}

	* Sort by age and generate the two-way line plot
	sort age2022
	graph twoway (rcap low high age2022) (connected `meanvar'_age age2022, color(navy) msize(small)), title("Mean Score (`meanvar') per Age with 95% CI") ytitle("Mean Score (`meanvar')") xtitle("Age Group") xlab(65(5)105, labsize(vsmall)) ylab(, labsize(vsmall) nogrid) graphregion(color(white)) bgcolor(white)
	
	graph export "`path_photo'\\`meanvar'.png", replace
	
	drop high low
	
end



*** main code
use "`path'\normsample_fscores_v2_12022024", clear
codebook age_group

** call the first function
mean_agegroup ori_mean "`path'" "`path_photo'"
mean_agegroup exf_mean "`path'" "`path_photo'"
mean_agegroup mem_mean "`path'" "`path_photo'"
mean_agegroup vis_mean "`path'" "`path_photo'"

** call the second function
mean_age ori_mean "`path'" "`path_photo'"
mean_age exf_mean "`path'" "`path_photo'"
mean_age mem_mean "`path'" "`path_photo'"
mean_age vis_mean "`path'" "`path_photo'"










