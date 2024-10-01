
*** Note
** 1. How to run the do file? 
* Run this line in the Command panel:
* texdoc do "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Statistics\HCAP Variables Descriptive Summary\Data_24Feb\descriptive_summary.do"

** 2. How to run tex file? 
* Open it in Overleaf, click button "Toggle Search", replace all "_" with "\_"



*** define paths
local path "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Statistics\HCAP Variables Descriptive Summary\Data_24Feb"
local path_photo "C:\Users\一飞\Desktop\Yifei\Data\Data Porcessing\Variables Statistics\HCAP Variables Descriptive Summary\Data_24Feb\photo"



*** functions
cap program drop corrange
program define corrange , rclass
	preserve
	
	qui pwcorr head-tail
	mat R=r(C)
	drop _all
	matsave R ,  replace
	
	use R , clear
	keep `1' _rowname
	drop if missing(`1')
	drop if _rowname=="`1'"
	drop if substr(_rowname, length(_rowname), 1) == "o"
	
	gsort -`1'
	local maxis : di %3.2gc `1'
	local maxisname = _rowname
	local maxisname = trim(itrim("`maxisname'"))
	gsort `1'
	local minis : di %3.2gc `1'
	local minisname = _rowname
	local minisname = trim(itrim("`minisname'"))
	
	qui su `1' , detail
	local medis : di %3.2gc `r(p50)'
	local lqis : di %3.2gc	`r(p25)'
	local uqis : di %3.2gc	`r(p75)'
   
	return local maxis "`maxis'"
	return local maxisname "`maxisname'"
	return local minis "`minis'"
	return local minisname "`minisname'"
	return local medis "`medis'"
	return local lqis "`lqis'"
	return local uqis "`uqis'"
	
	restore
end


cap program drop rangeis
program define rangeis
   qui su `1' , detail
	local foo  : di %8.2f `r(mean)'
	local goo  : di %8.2f `r(sd)'
	local hoo  : di %8.2f `r(min)'
	local ioo  : di %8.2f `r(max)'
	local joo  : di %8.2f `r(skewness)'
	local koo  : di %8.2f `r(kurtosis)'
	tex Mean (SD) & `foo' (`goo') & Range & [`hoo' - `ioo'] \\
	tex \hline
	tex skewness & `joo' & kurtosis & `koo' \\
end


cap program drop qmissing
program define qmissing , rclass
   qui distinct `1'
	local nmiss = `c(N)'-`r(N)'
	local pmiss  : di %2.0f 100*(`nmiss'/`c(N)')
	return local nmiss "`nmiss'"
	return local pmiss "`pmiss'"
end


cap program drop atmax
program define atmax , rclass
   qui su `1'
	local valid=`r(N)'
	qui su `1' if `1'==`r(max)'
	local nmax = `r(N)'
	local pmax  : di %2.0f 100*(`nmax'/`valid')
	return local nmax "`nmax'"
	return local pmax "`pmax'"
end
  
  
cap program drop atmin
program define atmin , rclass
   qui su `1'
	local valid=`r(N)'
	qui su `1' if `1'==`r(min)'
	local nmin = `r(N)'
	local pmin  : di %2.0f 100*(`nmin'/`valid')
	return local nmin "`nmin'"
	return local pmin "`pmin'"
end


cap program drop cormm
program define cormm , rclass
   qui corr MMSE_score `1'
	return local cormm  : di %3.2gc `r(rho)'
end



*** main code
use "`path'\w206_july_new", clear
keep MMSE_score head vdori1 vdori2 vdmie1 vdmie2 vdmie2o vdmie3 vdmie4 vdmde1 vdmde2 vdmde3 vdmde4 vdmde5 vdmre1 vdmre2 vdvis1 vdvis2 vdexf1 vdexf2 vdexf3 vdexf4 vdexf5 vdexf7 vdasp1 vdasp2 vdasp3_S7 vdasp3_world vdasp3_S7_WORLD vdasp4 vdasp5 vdlfl1 vdlfl2 vdlfl2o vdlfl3 vdlfl3o vdlfl4 vdlfl5 vdlfl6 vdlfl6o vdlfl7 vdlfl8 vdlfl8o tail
order MMSE_score head vdori1 vdori2 vdmie1 vdmie2 vdmie2o vdmie3 vdmie4 vdmde1 vdmde2 vdmde3 vdmde4 vdmde5 vdmre1 vdmre2 vdvis1 vdvis2 vdexf1 vdexf2 vdexf3 vdexf4 vdexf5 vdexf7 vdasp1 vdasp2 vdasp3_S7 vdasp3_world vdasp3_S7_WORLD vdasp4 vdasp5 vdlfl1 vdlfl2 vdlfl2o vdlfl3 vdlfl3o vdlfl4 vdlfl5 vdlfl6 vdlfl6o vdlfl7 vdlfl8 vdlfl8o tail


** label the vairables
* vdori1
local var "vdori1"
local `var'_lab "MMSE 10 items (number of correct, 0-10)"
local `var'_domain "Orientation"
la var `var' "``var'_lab'"

* vdori2
local var "vdori2"
local `var'_lab "TICS name president correct (0,1)"
local `var'_domain "Orientation"
la var `var' "``var'_lab'"

* vdmie1
local var "vdmie1" 
local `var'_lab "CERAD word list immediate sum of 3 trials (0-30)"
local `var'_domain "Memory, immediate episodic"
la var `var' "``var'_lab'"

* vdmie2 
local var "vdmie2" 
local `var'_lab "MMSE 3 word recognition (0-3)"
local `var'_domain "Memory, immediate episodic"
la var `var' "``var'_lab'"

* vdmie3
local var "vdmie3" 
local `var'_lab "Logical memory immediate (0-25)"
local `var'_domain "Memory, immediate episodic"
la var `var' "``var'_lab'"

* vdmie4
local var "vdmie4"
local `var'_lab "Brave man immediate (0-12)"
local `var'_domain "Memory, immediate episodic"
la var `var' "``var'_lab'"

* vdmde1
local var "vdmde1" 
local `var'_lab "CERAD word list delayed (0-10)"
local `var'_domain "Memory, delayed episodic"
la var `var' "``var'_lab'"

* vdmde2
local var "vdmde2" 
local `var'_lab "Logical memory delayed (0-25)"
local `var'_domain "Memory, delayed episodic"
la var `var' "``var'_lab'"

* vdmde3
local var "vdmde3" 
local `var'_lab "MMSE 3 word delayed recall (0-3)"
local `var'_domain "Memory, delayed episodic"
la var `var' "``var'_lab'"

* vdmde4
local var "vdmde4" 
local `var'_lab "CERAD constructional praxis delayed (0-11)"
local `var'_domain "Memory, delayed episodic"
la var `var' "``var'_lab'"

* vdmde5
local var "vdmde5"
local `var'_lab "Brave man delayed score (0-12)"
local `var'_domain "Memory, delayed episodic"
la var `var' "``var'_lab'"

* vdmre1
local var "vdmre1" 
local `var'_lab "CERAD word list recognition task (0-20)"
local `var'_domain "Memory, recognition"
la var `var' "``var'_lab'"

* vdmre2
local var "vdmre2" 
local `var'_lab "Logical memory recognition (0-15)"
local `var'_domain "Memory, recognition"
la var `var' "``var'_lab'"

* vdvis1
local var "vdvis1"
local `var'_lab "CERAD Constructional praxis"
local `var'_domain "Visuospatial"
la var `var' "``var'_lab'"

* vdvis2
local var "vdvis2"
local `var'_lab "MMSE copy polygons"
local `var'_domain "Visuospatial"
la var `var' "``var'_lab'"

* vdexf1
local var "vdexf1"
local `var'_lab "Raven's progressive matrices"
local `var'_domain "Executive function"
la var `var' "``var'_lab'"

* vdexf2
local var "vdexf2"
local `var'_lab "Trails B time (observed 32-300 seconds)"
local `var'_domain "Executive function"
la var `var' "``var'_lab'"

* vdexf3 
local var "vdexf3"
local `var'_lab "Symbol cancellation test, omission errors"
local `var'_domain "Executive function"
la var `var' "``var'_lab'"

* vdexf4 
local var "vdexf4"
local `var'_lab "Symbol cancellation test, commission errors"
local `var'_domain "Executive function"
la var `var' "``var'_lab'"

* vdexf5 
local var "vdexf5"
local `var'_lab "Errors, Symbol Digit Modalities Test"
local `var'_domain "Executive function"
la var `var' "``var'_lab'"

*vdexf7 
local var "vdexf7"
local `var'_lab "HRS Number Series"
local `var'_domain "Executive function"
la var `var' "``var'_lab'"

* vdasp1
local var "vdasp1"
local `var'_lab "Symbol Digit Modalities Test score"
local `var'_domain "Attention, speed"
la var `var' "``var'_lab'"

* vdasp2
local var "vdasp2"
local `var'_lab "Trails A"
local `var'_domain "Attention, speed"
la var `var' "``var'_lab'"

* vdasp3_S7
local var "vdasp3_S7"
local `var'_lab "MMSE serial 7"
local `var'_domain "Attention, speed"
la var `var' "``var'_lab'"

* vdasp3_world
local var "vdasp3_world"
local `var'_lab "MMSE spell world backwards"
local `var'_domain "Attention, speed"
la var `var' "``var'_lab'"

* vdasp3_S7_WORLD
local var "vdasp3_S7_WORLD"
local `var'_lab "MMSE serial 7 and backward spelling combined"
local `var'_domain "Attention, speed"
label variable `var' "``var'_lab'"

* vdasp4
local var "vdasp4"
local `var'_lab "Backwards counting"
local `var'_domain "Attention, speed"
la var `var' "``var'_lab'"

* vdasp5
local var "vdasp5"
local `var'_lab "Symbol cancellation test, mean score"
local `var'_domain "Attention, speed"
la var `var' "``var'_lab'"

* vdlfl1
local var "vdlfl1"
local `var'_lab "Category fluency (animals)"
local `var'_domain "Language, fluency"
la var `var' "``var'_lab'"

* vdlfl2
local var "vdlfl2"
local `var'_lab "Naming 2 items HRS TICS scissors and bridge"
local `var'_domain "Language, fluency"
la var `var' "``var'_lab'"

* vdlfl3
local var "vdlfl3"
local `var'_lab "Naming 2 items MMSE"
local `var'_domain "Language, fluency"
la var `var' "``var'_lab'"

* vdlfl4
local var "vdlfl4"
local `var'_lab "MMSE write a sentence"
local `var'_domain "Language, fluency"
la var `var' "``var'_lab'"

* vdlfl5
local var "vdlfl5"
local `var'_lab "MMSE repeat phrase"
local `var'_domain "Language, fluency"
la var `var' "``var'_lab'"

* vdlfl6
local var "vdlfl6"
local `var'_lab "MMSE three step command"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"

* vdlfl7
local var "vdlfl7"
local `var'_lab "Read and follow command"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"

* vdlfl8
local var "vdlfl8"
local `var'_lab "CSID naming"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"

* vdmie2o
local var "vdmie2o" 
local `var'_lab "MMSE 3 word recognition (0-3), original coding"
local `var'_domain "Memory, immediate episodic"
la var `var' "``var'_lab'"

* vdlfl2o
local var "vdlfl2o"
local `var'_lab "Naming 2 items HRS TICS scissors and bridge, original coding"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"

* vdlfl3o
local var "vdlfl3o"
local `var'_lab "Naming 2 items MMSE, original coding"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"

* vdlfl6o
local var "vdlfl6o"
local `var'_lab "MMSE three step command, original coding"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"

* vdlfl8o
local var "vdlfl8o"
local `var'_lab "CSID naming, original coding"
local `var'_domain "Langauge, fluency"
la var `var' "``var'_lab'"


** create the descriptive summary report
texdoc init "`path'\descriptive_summary.tex", replace
tex \documentclass{article}
tex 
tex \usepackage{stata}
tex \usepackage{multirow}
tex \usepackage{graphicx}
tex 
tex \begin{document}
tex 
tex \begin{center}
tex \bf{\huge{Data Statistics Report}} \\
tex \Large{February 2024}
tex \end{center}
tex 
tex 
tex 
tex \section{Variables}
tex 

foreach var of varlist head-tail {
	if "`var'"~="head" & "`var'"~="tail" {
		cap confirm file "`path_photo'\\`var'.png"
		if _rc~=0 {
			local discreteis ""
			distinct `var'
			if `r(ndistinct)'<40 {
				local discreteis "discrete"
			}
			gr tw hist `var', xscale(off) yscale(off) `discreteis' ysize(1) xsize(3) color(gs12)
			gr export "`path_photo'\\`var'.png", replace width(250)
		}
		tex \subsection{``var'_lab'}
		tex {\bf `var'} (``var'_domain') \\
		tex \begin{tabular}{|p{3cm}|p{3cm}|p{6.42cm}|}
		distinct `var'
		tex \hline
		tex Distinct values & `r(ndistinct)' &
	    tex  \multirow{4}{*}{\includegraphics[width=6.42cm]{photo/`var'.png}} \\
		qmissing `var'
		tex \cline{1-2}
		tex Missing N (\%) & `r(nmiss)' (`r(pmiss)'\%) & \\
		tex \cline{1-2}
		atmax `var'
		tex At max N (\%) & `r(nmax)' (`r(pmax)'\%) & \\
		tex \cline{1-2}
		atmin `var'
		tex At min N (\%) & `r(nmin)' (`r(pmin)'\%) & \\
		tex \cline{1-2}
		cormm `var'
		tex Corr(MMSE) & `r(cormm)' & \\
		tex \hline
		tex \end{tabular}\\
		distinct `var'
		if `r(ndistinct)'>8 {
			tex \begin{tabular}{|p{3cm}|p{3cm}|p{3cm}|p{3cm}|}
			rangeis `var'
			tex \hline
			tex \end{tabular}\\
		}
		tex \begin{tabular}{|p{3cm}|p{3cm}|p{6.42cm}|}
		corrange `var'
		tex \multicolumn{3}{|l|}{Range of correlation coefficients with other items}\\
		tex \hline
		tex max & `r(maxis)' & `r(maxisname)' (``r(maxisname)'_lab') \\
		tex \hline
		tex min & `r(minis)' & `r(minisname)' (``r(minisname)'_lab') \\
		tex \end{tabular}\\
		tex \begin{tabular}{|p{3cm}|p{3cm}|p{3cm}|p{3cm}|}
		tex \hline
		tex median & `r(medis)' & IQI & [`r(lqis)' - `r(uqis)'] \\
		tex \hline
		tex \end{tabular}\\[0.5cm]
		tex  
	} 
} 

tex \end{document}







