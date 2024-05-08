*************************************************
* The Transgender Population Face Severe and Wide-Ranging Disadvantages Analysis
*************************************************
local origdatadir "C:\Users\EYT\OneDrive - The University of Melbourne\Desktop\HILDA22\NewDATA"    // Location of original HILDA u data files
local newdatadir  "C:\Users\EYT\OneDrive - The University of Melbourne\Desktop\HILDA22\Transgender"     // Location to which to write new data files
global Excel "C:\Users\EYT\OneDrive - The University of Melbourne\Desktop\HILDA22\Transgender\Means.xlsx" //Mean Outputs
cd "C:\Users\EYT\OneDrive - The University of Melbourne\Desktop\HILDA22\Transgender" //Directory

*************************************************
* SECTION A: CREATING THE DATASET 
*************************************************

// Specify directories (use "." to point to current directory)
clear
set memory 1g

local varstokeep xwaveid wave hgsex ftsex scsxgn scgndr hgage ancob edhigh1 hhrih hhtype hhadult ghmh losat losatlc lssupvl esbrd lstrust ghgh hhwtrp hhwtsc hh0_4 hh5_9 hh10_14 hhd0_4 hhd5_9 hhd1014 hhd1524 hifefp hifefn hifdip hifdin fiprosp hhwte phlfyi mrcurr hhra hhstate tifdip tifdin tifefp tifefn tifpiip tifpiin lssexor edfts jbtprhr esdtl helth helthwk helthdg jbmcnt jbtu jbmunio jbempt jbmsch jbmlh edfts esempst jbempt jbou jbmo61 jbmi61 jbmwps jbmwpsz jbmmwp jbmemsz jbmems2 jbmunio jbtu jbmmply jbmsvsr jbtprhr jbmtuea jbn tcn04 tcn1524 tcn25 tcn514 tcnr tcr tcr04 tcr1524 tcr25 tcr514 tcyng hhfty gh1 wscei wschave jbmsall ioadult hhhfmo hhhqmo hhpqmo hgi hgivw hhrhid jbhrua jbmh jbhruc jbmhrha jbmhrhw jbmhruc tchad jbmwpsz iolocn rcage1 rcage2 rcage3 rcage4 rcage5 rcage6 rcage7 rcage8 rcage9 rcage10 rcage11 rcage12 rcage13 jbmhruc anatsi losatfs levio lssupvl lejls levio lepcm tcn04 tcn514 tcnr tcr tcr04 tcr514 tchave rcyng losatsf pnsymp pntemp pnemote pnopene hsmgfv fiprbmr //variables we wish to keep 
 
use "`origdatadir'\Combined_v220u" //Access wave 22 u files
renpfix v   //rip the v prefix
gen wave = 22 
gen year = 2022

// select variables needed
if ("`varstokeep'"!="") {
	local tokeep                                 // empty to keep list
	foreach var of local varstokeep {            // loop over all selected variables
		capture confirm variable `var'           // check whether variable exists in current wave
		if (!_rc) local tokeep `tokeep' `var'    // mark for inclusion if variable exists
		}
	keep xwaveid wave `tokeep' // keep selected variables
}

order xwaveid wave
sort  xwaveid wave

save "`newdatadir'\long-file-unbalanced", replace
 
*************************************************
* SECTION B: Clean dataset
*************************************************
//Get rid of any missing data
mvdecode _all, mv(-1=. \ -2=. \ -3=. \ -4=. \ -5=. \ -6=. \ -7=.\-8=. \ -9=. \ -10=.)


*************************************************
* SECTION C: Creating Variables
*************************************************
/*=====================*/
/*Gender related variables */

*Splitting Original Cisgender to Cis-man and Cis-woman
*Cisman
gen byte scsxgn_cis = 1 if scsxgn == 1 & scgndr == 1
*Ciswoman
replace scsxgn_cis = 2 if scsxgn == 1 & scgndr == 2
*Transgender and Gender Diverse
replace scsxgn_cis = 3 if scsxgn == 2
*Inadequately described
replace scsxgn_cis = 4 if scsxgn == 3
lab def scsxgn_cis 1 "Cisgender Man" 2 "Cisgender Woman" 3 "Transgender and Gender Diverse" 4 "Inadequately described"
lab val scsxgn_cis scsxgn_cis
la var scsxgn_cis "Cisgender Sexes, and Transgender and Gender Diverse "

/*=====================*/
/* Educational attainment */

replace edhigh1=. if edhigh1==10 //dropping undetermined

//Recoding the education variable into broader categories
recode edhigh1 (9 = 1 "Year 11 and below") (8=2 "Year 12") (4/5=3 "Vocational") (1/3 = 4 "Bachelor and higher") (else=.), gen(education)
lab var education "Education level"
//Generate education dummy variables
tab education, gen (education)

/*=====================*/
/*Labour force and employment status*/

*Unemployed
gen unemploy = esbrd == 2
replace unemploy=. if esbrd>=.
lab def unemploy 0 "Other" 1 "Unemployed" 
lab val unemploy unemploy   
la var unemploy "Unemployed"

*Employed
gen employ = esbrd == 1
replace employ=. if esbrd>=.
lab def employ 0 "Other" 1 "Employed" 
lab val employ employ   
la var employ "Employed"

*Not in the Labour Force
gen NILF = esbrd == 3
replace NILF=. if esbrd>=.
lab def NILF 0 "Other" 1 "Not in the labour force" 
lab val NILF NILF   
la var NILF "Not in the Labour Force"

/*=====================*/
/*Underemployment*/
gen prefermorehrs=(jbtprhr-jbhruc)>0 //Calculate whether the worker wishes to work more hours
replace prefermorehrs=. if jbtprhr>=. | jbhruc>=. //ensure that missing values in the original variables are missing in the new variable
gen underemp=esdtl==2 & prefermorehrs==1 if esdtl<. & prefermorehrs<. //Generate underemployed variable if the worker wishes to work more hours and is employed part-time
replace underemp=. if esdtl>=.
lab def underemp 0 "Non" 1 "Underemployed" 
lab val underemp underemp   
la var underemp "Underemployment"

/*Expland the labour force variable to include underemployed */
gen esbrd2 = esbrd
replace esbrd2=. if (jbtprhr>=. | jbhruc>=.) & (esbrd==1) 
recode esbrd2 (1=1) (2=3) (3=4)
replace esbrd2=2 if underemp==1
lab def esbrd2 1 "Fully employed" 2 "Underempolyed" 3 "Unemployed" 4 "Not in the labour force"
lab val esbrd2 esbrd2   
la var esbrd2 "Labour Force-Underemployed"

/*Renaming Labour Force Variables*/
rename esbrd LF
rename esbrd2 LFE
tab LF, gen(LF)
tab LFE, gen(LFE)

/*=====================*/
/* Age */
rename hgage age

/*Age squared*/
gen hgagesq = age^2
la var hgagesq "Age^2"

/*=====================*/
/*Income */

/*Equivalence scale*/
*Number of adults
gen hhnadults=hhadult
la var hhnadults "# people aged 15+ in household"

*Number of persons aged <15
gen hhnchildren=hh0_4+hh5_9+hh10_14
la var hhnchildren "# people aged <15 in household"

*Child present dummy
gen hhchildren=hhnchildren>0
lab def hhchildren 0 "No child" 1 "Child present in HH" 
lab val hhchildren hhchildren  
la var hhchildren "Child Present in HH"

*Equivalence scale
gen escale=1 + (0.5*(hhnadults-1)) + (0.3*hhnchildren)

/*Nominal hh gross income*/ 
gen hhnginc=hifefp-hifefn
la var hhnginc "H/hold nom gross income"

/*Nominal hh disposable income*/
gen hhndinc=(hifdip-hifdin)
la var hhndinc "H/hold nom disp income"

/*equivalised nominal household disposable income*/               
gen hhneqdinc=hhndinc/escale
replace hhneqdinc=0 if hhneqdinc<0
la var hhneqdinc "H/hold nominal equiv disp income"

/*log equivalised nominal household disposable income*/  
gen ln_hhneqdinc = ln(hhneqdinc)
la var ln_hhneqdinc " Log of H/hold nominal equiv disp income"

/*nominal personal disposable*/ 
gen pdinc=(tifdip-tifdin)
la var pdinc "nominal personal disposable income"

/*nominal log personal disposable*/ 
gen ln_pdinc=ln(pdinc)
la var ln_pdinc "log of personal nominal disposable income"
 
/*=====================*/
/*Household Poverty Line*/
qui sum hhneqdinc [aw=hhwte] if wave==22, d
gen apovline22=0.5*r(p50)
lab var apovline22 "Anchored PL (2022 median)"
gen inapov22p=1*(hhneqdinc<apovline22) if hhneqdinc<.
lab def inapov22p 0 "Not in poverty" 1 "In poverty" 
lab val inapov22p inapov22p  
la var inapov22p "In poverty"

/*=====================*/
/* Ethnicity and place of birth */

//Create dummy variable for Aboriginal or Torres Strait Islander origin
recode anatsi (-10/-1=.) (1=0) (2/4=1), gen(indigenous)

//Create broard country of birth variable
recode ancob (-10/-1=.) (.=.) (1101 = 1 "Australia") (1201 2100 2201 9225 8104 8102 = 2 "Other English-speaking") (else=3 "Other non-English-speaking"), gen(aus_born)
replace aus_born =4 if indigenous==1 //Creating category for: aboriginal or Torres Strait Islander origin
lab def Aus_born 1 "Australia" 2 "Other English-speaking" 3 "Other non-English-speaking" 4 "Aboriginal or Torres Strait Islander"
lab val aus_born Aus_born  
la var aus_born "Country of Birth"
tab aus_born, gen (aus_born)

/*=====================*/
/*Health and disability*/
gen healthcon=0 if helth==2 | helthwk==2 | helthdg==0  //people without a long term health condition that limits their work
replace healthcon=1 if (helthwk==1 & helthdg>=1) | helthwk==3 //people with a long term health condition that limits their work
la var healthcon "long term health condition"

/*Self-assessed Health*/
recode gh1 (1=5 "Excellent") (2=4 "Very good") (3=3 "Good") (4=2 "Fair") (5=1 "Poor"), gen (SelfHealth) // recoding variable into ascending order
tab SelfHealth, gen(SelfHealth)

/*=====================*/
/*Employment related variables*/

*Employment 
generate jbmcnt2 = jbmcnt
replace jbmcnt2 = 4 if esempst == 2 | esempst == 3
recode jbmcnt2 (8=5)
lab def jbmcnt2 1 "Fixed-term" 2 "Casual" 3 "Permanent or ongoing" 4 "Self-Employed" 5 "Other" 
lab val jbmcnt2 jbmcnt2  
la var jbmcnt2 "Empolyment Contract"

*Employment Dummies
tab jbmcnt2, gen (jbmcnt2)
rename jbmcnt21 Fixed
rename jbmcnt22 Casual
rename jbmcnt23 Permanent
rename jbmcnt24 Self_Employed
rename jbmcnt25 Other 

/*Job Tenure*/
recode jbempt (0/0.9807693=1 "Less then 1 year") (1=2 "1 to <2 years") (2/4=3 "2 to <5 years") (5/9=4 "5 to <10 years") (10/19=5 "10 to <20 years") (20/100=6 "20 or more years"), gen(tenure) 
tab tenure, gen(tenure)

/*Occupation and industry dummies*/
tab jbmo61, gen(Occupation_dummy)
tab jbmi61, gen(Industry_dummy)

/*Firm size*/
recode jbmems2 (1/4=1 "1-19") (5=2 "20-99") (6=3 "100-499") (7/10=4 ">500") (11=1) (12=2) (13=5 "Unknown"), gen(firms)
tab firms, gen(firms_dummy)

/* Superviser */
recode jbmsvsr (1=1 "[1] Has supervisory responsibilities ") (2=0 "[0] Doesn't have supervisory responsibilities "), gen(supervise)

/*Multiple Jobs Holder */
recode jbn (1=1 "[1] Employed in more than one job ") (2=0 "[0] Only employed in one job"), gen(MultiJobs)

/*Union member*/
recode jbtu (1=1 "[1] Trade union member") (2=0 "[0] Not a trade union member"), gen(TradeUnion)

/*Sector of employment*/
recode jbmmply (2=1 "Public Sector") (5=1) (1=0 "Private Sector") (3/4=0), gen(Public) 

/*Total Hours worked*/
gen total_hours_mainjob = jbmhruc
gen total_hours_alljobs = jbhruc
gen total_hours = total_hours_alljobs
la var total_hours "Total hours worked"
replace total_hours = total_hours_mainjob if jbn==1	
gen hours2=total_hours*total_hours

/*Propration of hours worked from home*/
recode jbmhrhw (997=.) // drop undetermined
gen proporationwfh = (jbmhrhw/jbhruc) //Hours per week spenf WFH / Hours per week worked
replace proporationwfh=0 if jbmh==2
la var proporationwfh "Propration of hours WFH"

/*weekly, all jobs*/ 
gen wwage=wscei if wschave==1
replace wwage=. if age<15|wwage<100  
la var wwage "Weekly wage" 

/*hourly wages, all jobs*/
gen hwage=wwage/jbhruc
replace hwage=. if (hwage<2|hwage>600)
la var hwage "Hourly wage"
gen ln_hwage = ln(hwage) //log
la var ln_hwage "Log of Hourly wage"

/*=====================*/
/*Family Variables*/

//Recoding count of own dependent children aged 0-4 to a dummy variable = 1 if present
recode tcr04 (0=0) (1/99=1), gen (own0_4)
la var own0_4 "Own dependent children 0-4"
//Recoding count of own dependent children aged 5-14 to a dummy variable = 1 if present
recode tcr514 (0=0) (1/99=1), gen (own514) 
la var own514 "Own dependent children 5-14"
//Generate variable for those with no own dependent children
gen No_ownchild = 0 if own0_4==1|own514==1
replace No_ownchild = 1 if own0_4==0 & own514==0

/*=====================*/
/*Other demographic characteristics*/ 

/*State dummies*/
tab hhstate, gen (hhstate_dummy)

/*Remoteness dummies*/
gen hhrar=hhra+1  // change scale to start at 1
recode hhrar (5=3) (4=3), gen(remote) //combine outer regional and remote
label define remote 1 "Major cities" 2 "Inner regional" 3 "Outer regional or remote"
label values remote remote
drop hhrar hhra
tab remote, gen (remote_dummy)

/*Marriage dummies*/
tab mrcurr, gen (mrcurr_dummy)

/*Recoding Relations Variable*/
recode mrcurr (1=1 "Married") (2=2 "Cohabiting") (3/6=3 "Single") (else=.), gen(Marriage)
tab Marriage, gen (Marriage)

/*=====================*/
/*Interview Questions*/ 

/* Other Present In Interview */
recode ioadult (2=0)

/* Mode of Interview*/
recode hgi (1=0 "Interview in person") (2=1 "Interviewed by phone"), gen(Phone)

/*=====================*/
/*Recoding Crime variables*/
recode levio (1=0 "No") (2=1 "Yes"), gen(violence)
recode lepcm (1=0 "No") (2=1 "Yes"), gen(property_crime)

/*=====================*/
/*Savings Data*/
save "Working_Data.dta", replace


*************************************************
* SECTION D: Means
*************************************************

*limiting sample to those between the age of 18-64
keep if age>17 & age<65

*Set excel output
putexcel set "$Excel", sheet("Means") replace

*Means that we will analyse
local list age education1 education2 education3 education4 proporationwfh healthcon Phone ioadult Marriage1 Marriage2 Marriage3 aus_born1 aus_born2 aus_born3 aus_born4 hhstate_dummy1 hhstate_dummy2 hhstate_dummy3 hhstate_dummy4 hhstate_dummy5 hhstate_dummy6 hhstate_dummy7 hhstate_dummy8 remote_dummy1 remote_dummy2 remote_dummy3 tenure1 tenure2 tenure3 tenure4 tenure5 tenure6 Fixed Casual Permanent Self_Employed Other Industry_dummy1 Industry_dummy2 Industry_dummy3 Industry_dummy4 Industry_dummy5 Industry_dummy6 Industry_dummy7 Industry_dummy8 Industry_dummy9 Industry_dummy10 Industry_dummy11 Industry_dummy12 Industry_dummy13 Industry_dummy14 Industry_dummy15 Industry_dummy16 Industry_dummy17 Industry_dummy18 Industry_dummy19 Occupation_dummy1 Occupation_dummy2 Occupation_dummy3 Occupation_dummy4 Occupation_dummy5 Occupation_dummy6 Occupation_dummy7 Occupation_dummy8 total_hours supervise MultiJobs TradeUnion Public firms_dummy1 firms_dummy2 firms_dummy3 firms_dummy4 firms_dummy5 losat ghgh ghmh inapov22p losatfs ln_pdinc ln_hhneqdinc ln_hwage jbmsall LFE1 LFE2 LFE3 LFE4 property_crime violence own0_4 own514

*Transgender variable for the means
local over scsxgn_cis

*These commands specify where to put the data in excel. i=2 is row 2 and col= 66 is column A (B is 67, C is 68, and so on)
local col = 66
local i = 2

*The main command here is "mean `var', over(`over')", everything else is to put this data into excel. 
foreach var of local list{
	mean `var', over(`over') //calculates means
	matrix b = e(b) //vector of mean estimates
	matrix c = e(sd) //vector of standard deviation estimates
	putexcel B`i' = matrix(b), nformat(number_d2)
	putexcel G`i' = matrix(c), nformat(number_d2)
	
	describe `var' // put variable labels into excel
	local varlabel : var label `var'
    putexcel A`i' = ("`varlabel'")
	
	local i = `i' + 1
}

levelsof `over', local(colnames) //Places categorical labels into columns
foreach o in `colnames'{
	local alpha = substr("`c(alphs)'", 1, 1)
	putexcel `=char(`col')'1 = "`: lab `: val lab `over'' `o''"
	local col = `col' + 5
	putexcel `=char(`col')'1 = "`: lab `: val lab `over'' `o''_SD"
	local col = `col' - 4
}

*************************************************
* SECTION E: Regressions
*************************************************

*limiting sample to those between the age of 18-64
keep if age>17 & age<65

/*Covariates*/
global covariates ib3.scsxgn_cis age hgagesq Bib2.education ib1.hhstate ib3.Marriage own0_4 own514 ib1.aus_born hhadult Phone ioadult ib1.remote    

global JobCovariates ib3.scsxgn_cis proporationwfh age hgagesq ib3.Marriage own0_4 own514 ib1.aus_born healthcon ib2.education ib3.jbmcnt2 ib1.tenure ib8.jbmo61 ib13.jbmi61 ib1.remote ib1.hhstate hhadult Phone ioadult total_hours hours2 supervise MultiJobs TradeUnion Public ib1.firms  

**********LABOUR MARKET*******************
/*Employment*/ 
mlogit LFE $covariates [pw=hhwtsc], base(1) vce(robust) 
/*Job Satisfaction*/
ologit jbmsall $JobCovariates [pw=hhwtsc], vce(robust)
/* Wage */
reg ln_hwage $JobCovariates [pw=hhwtsc], vce(robust)

********Income / Financial well-being*******
/*Finance*/
//Household equivalised disposable FY income   
reg ln_hhneqdinc $covariates [pw=hhwtsc], vce(robust)
//Personal FY (disposable) income 
reg ln_pdinc $covariates [pw=hhwtsc], vce(robust)
//Satisfaction with financial situation 
ologit losatfs $covariates [pw=hhwtsc], vce(robust) 
//Poverty Measure
logit inapov22p $covariates [pw=hhwtsc], vce(robust) 

********Health and Wellbeing*******
//Linear Mental health
reg ghmh $covariates [pw=hhwtsc], vce(robust)
//Linear General health
reg ghgh $covariates [pw=hhwtsc], vce(robust)
//Life statisfaction ordered logit
ologit losat $covariates [pw=hhwtsc], vce(robust)
//Binary Victim of physical violence
logit violence $covariates [pw=hhwtsc], vce(robust)
//Binary Victim of property crime
logit property_crime $covariates [pw=hhwtsc], vce(robust) 

*******Linear Alternatives*******
reg jbmsall $JobCovariates [pw=hhwtsc], vce(robust) 
reg losatfs $covariates [pw=hhwtsc], vce(robust)
reg inapov22p $covariates [pw=hhwtsc], vce(robust)
reg violence $covariates [pw=hhwtsc], vce(robust) 
reg property_crime $covariates [pw=hhwtsc], vce(robust) 
reg losat $covariates [pw=hhwtsc], vce(robust) 




