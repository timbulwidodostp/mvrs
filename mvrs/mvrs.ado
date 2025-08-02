*! version 2.0.1 PR 23apr2013
program define mvrs, eclass 
	local VV : di "version " string(_caller()) ", missing:"
	version 11.0
	local cmdline : copy local 0
	mata: _parse_colon("hascolon", "rhscmd")	// _parse_colon() is stored in _parse_colon.mo
	if (`hascolon') {
	        `VV' newmvrs `"`0'"' `"`rhscmd'"'
	}
	else {
	        `VV' mvrs_10 `0'
	}
	// ereturn cmdline overwrites e(cmdline) from mvrs_10
	ereturn local cmdline `"mvrs `cmdline'"'
end

program define newmvrs
	local VV : di "version " string(_caller()) ", missing:"
	version 11.0
	args 0 statacmd

	// Extract mvrs options
	syntax, [*]
	local mfpopts `options'

	local 0 `statacmd'
	syntax [anything] [if] [in] [aw fw pw iw], [*]
	if `"`weight'"' != "" local wgt [`weight'`exp']
	local options `options' hascolon
	`VV' mvrs_10 `anything' `if' `in' `wgt', mfpopts(`mfpopts') `options'
end

program define mvrs_10, eclass sortpreserve
local VV : di "version " string(_caller()) ", missing:"
version 11.0

if "`1'" == "" | "`1'"=="," {
	if "`e(fp_cmd2)'"!="mfp" {
		error 301
	}
	syntax [ , level(cilevel) *]
	`VV' FracRep "regression spline" "  df  " "Knots"
	exit
}
if _caller() >= 12 {
	quietly ssd query
	if (r(isSSD)) {
		di as err "mvrs not possible with summary statistic data"
		exit 111
	}
}
local cmdline : copy local 0
gettoken cmd 0 : 0
xfrac_chk `cmd' 
if `s(bad)' {
	di in red "invalid or unrecognized command, `cmd'"
	exit 198
}
/*
	dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
	5 (xtgee), 6(ereg/weibull), 7(streg,stcox).
*/
if "`cmd'" == "cnreg" local cmd _cnreg
local dist `s(dist)'
local glm `s(isglm)'
local qreg `s(isqreg)'
local xtgee `s(isxtgee)'
local normal `s(isnorm)'

global MFpdist `dist'

// separate commands options from -mfp- options
_parse comma lhs rhs : 0
local 0 `rhs'
syntax [, mfpopts(string asis) hascolon DEAD(str) noCONStant * ]
if ("`hascolon'"!="") {
	local cmdopts `options'
	local 0 `lhs' , `mfpopts'
}
else {
	local 0 `lhs', `options'
}

/* parse */
syntax [anything(name=xlist)] [if] [in] [aw fw pw iw] , ///
 [ ADJust(string) ALpha(string) ALL DF(string) ///
 DFDefault(int 4) CYCles(int 20) DEAD(string) DEGree(int 3) noCONStant ///
 KNots(string) SELect(string) XOrder(string) noORTHog * ]

* Disentangle
GetVL `xlist'
_get_diopts diopts options, `options' `cmdopts'

if ("`adjust'"=="") {
	local adjust "`center'"
}
else if ("`center'"!="") {
	di as err "may not specify both adjust() and center()"
	exit 198
}
frac_cox "`dead'" `dist'
/*
	Process options
*/
local regopt `diopts' `options' `constant'
if `degree'==3 & "`orthog'"!="noorthog" local orthog orthog
if "`aic'"!="" { // aic selection for vars and functions
	if "`alpha'`select'"!="" {
		noi di as err "alpha() and select() invalid with aic"
		exit 198
	}
	local alpha -1
	local select -1
}
/*
	Check for missing values in lhs, rhs and model vars.
*/
quietly {
	marksample touse
	markout `touse' $MFP_cur $MFP_dv `dead'
	if `dist'==7 {
		replace `touse' = 0 if _st==0
	}
	frac_wgt "`exp'" `touse' "`weight'"
	local wgt `r(wgt)'				/* [`weight'`exp'] */
	count if `touse'
	local nobs = r(N)
}
/*
	Detect collinearity among covariates, and fail if found.
*/
local ncur: word count $MFP_cur
`VV' _rmcoll $MFP_cur `if' `in' [`weight' `exp'], `constant'
local ncur2: word count `r(varlist)'
if `ncur2'<`ncur' {
	local ncoll=`ncur'-`ncur2'
	if `ncoll'>1 {
		local s ies
	}
	else local s y
	di in red `ncoll' " collinearit`s' detected among covariates"
	exit 198
}
/*
	Rearrange order of variables in varlist
*/
if "`xorder'"=="" local xorder "+"
/*
	Apply fracord to get param estimates
*/
FracOrd `wgt' if `touse', order(`xorder') `regopt' cmd(`cmd')
local nx $MFP_n	/* number of clusters, <= number of predictors */
local lhs $MFP_dv
/*
	Store original order and reverse order
	of each RHS variable/variable set
*/
forvalues i=1/`nx' {
	local r`i' `s(ant`i')'
}
/*
	Initialisation.
*/
forvalues i=1/`nx' {
	local x ${MFP_`i'}
	local nx`i': word count `x'
	local alp`i' .05	/* default FP selection level */
	local h`i' `x'		/* names of H(xvars) 	*/
	local n`i' `x'		/* names of xvars 	*/
	local po`i' 1 		/* to be final knot	*/
	local sel`i' 1		/* default var selection level */
	// Flag if x is a factor variable
	fvexpand `x'
	if "`r(fvops)'" == "true" {
		local isfactor`i' 1
	}
	else local isfactor`i' 0
/*
	Remove old I* variables
*/
	if (`nx`i'' == 1) & !`isfactor`i'' {
		frac_mun `n`i'' purge
	}
}
/*
	Adjustment
*/
FracAdj "`adjust'" `touse'
forvalues i=1/`nx' {
	if "`r(adj`i')'"!="" {
		local adj`i' adjust(`r(adj`i')')
	}
	local uniq`i'=r(uniq`i')
}
/*
	Set up degrees of freedom for each variable
*/
if "`df'"!="" {
	FracDis "`df'" df 1 .
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" {
			local df`i' ${S_`i'}
		}
	}
}
/*
	Assign default df for vars not so far accounted for.
	Give 1 df if 2-3 distinct values, 2 df for 4-5 values,
	dfdefault df for >=6 values.
*/
forvalues i=1/`nx' {
	if (`nx`i'' > 1) | `isfactor`i'' {
		* over-ride all suggestions that df>1 for grouped vars
		local df`i' 1
	}
	else {
		if "`df`i''"=="" {
			if `uniq`i''<=3 {
				local df`i' 1
			}
			else if `uniq`i''<=5 {
				local df`i'=min(2,`dfdefault')
			}
			else local df`i' `dfdefault'
		}
	}
}
/*
	Set up selection level (alpha) for each variable
*/
if "`alpha'"!="" {
	FracDis "`alpha'" alpha -1 1
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" {
			local alp`i' ${S_`i'}
			if `alp`i''<0 local alp`i' -1  // AIC
		}
	}
}
/*
	Set up selection level for each variable
*/
if "`select'"!="" {
	FracDis "`select'" select -1 1
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" {
			local sel`i' ${S_`i'}
			if `sel`i''<0 local sel`i' -1  // AIC
		}
	}
}
/*
	Rationalise select() and alpha() in cases of aic
*/
forvalues i=1/`nx' {
	if `sel`i''==-1 & `alp`i''!=1 local alp`i' -1
	if `alp`i''==-1 & `sel`i''!=1 local sel`i' -1
}
/*
	Set knots for predictors individually.
*/
if "`knots'"!="" {
	FracDis "`knots'" knots
	forvalues i=1/`nx' {
		if "${S_`i'}"!="" & `nx`i''==1 {
			local xknot`i' ${S_`i'}
			local df`i' : word count `xknot`i''
			local ++df`i'
		}
	}
}
/*
	Reserve names for H(predictors) by creating a dummy variable
	for each predictor which potentially needs transformation.
*/
forvalues i = 1 / `nx' {
	if `df`i'' > 1 & !`isfactor`i'' {
		frac_mun `n`i''
		local stub`i' `s(name)'
		qui gen byte `stub`i''_1 = .
	}
}
/*
	Build model.
	`r*' macros present predictors according to FracOrd ordering,
	e.g. i=1, r`i'=3 means most sig predictor is third in user's xvarlist.
*/
local it 0
local initial 1
local stable 0 // convergence flag
while !`stable' & `it'<=`cycles' {
	local ++it
	local pwrs
	local rhs1
	local stable 1 // later changed to 0 if any power or status changes
	local lastch 0 // becomes index of last var which changed status
	forvalues i=1/`nx' {
		local r `r`i''
		local ni `n`r''
		local dfi df(`df`r'')
/*
	Build up RHS2 from the i+1th var to the end 
*/
		local rhs2
		local j `i'
		while `j'<`nx' {
			local ++j
			local rhs2 `rhs2' `h`r`j'''
		}
		if `initial' {
			if "`rhs2'"!="" local fixed "base(`rhs2')"
			else local fixed
			qui splsel `cmd' `lhs' `ni' `wgt' if `touse', ///
			 df(1) `fixed' select(1) `regopt' `unique' deg(`degree')
			local dev=r(dev)
			di as text _n ///
			 "Deviance for model with all terms " ///
			 "untransformed = " as res %9.3f `dev' as text ", " ///
			 as res `nobs' as text " observations"
		}
		if "`rhs1'`rhs2'"!="" local fixed "base(`rhs1' `rhs2')"
		else local fixed
/*
	Vars with df(1) are straight-line
*/
		local pvalopt "alpha(`alp`r'') select(`sel`r'')"
		if `i'==1 di
		local kn
		if `df`r''!=1 & "`xknot`r''"!="" local kn "knot(`xknot`r'')"
		if `df`r''==1 & `sel`r''==1 {	// var is included anyway
			local rhs1 `rhs1' `h`r''
			di as text "[`ni' included with 1 df in model]" _n
		}
		else {
			if "`stub`r''"!="" local n name(`stub`r'')
			else local n
			splsel `cmd' `lhs' `ni' `wgt' if `touse', `dfi' `fixed' ///
			 `h' `regopt' `pvalopt' `unique' deg(`degree') `kn'
			local h`r' "`r(n)'"
			local dev=r(dev)
			local p "`r(knots)'"	/* final knots */
			if "`p'"!="`po`r''" {
				if `nx'>1 local stable 0
				local po`r' "`p'"
				local lastch `i'
			}
			if "`h`r''"!="" local rhs1 `rhs1' `h`r''
		}
		if `initial' {
			local h "nohead"
			local initial 0
		}
	}
	if `lastch'==1 local stable 1 // 1 change only, at i=1
	if !`stable' ///
		di as text "{hline 61}" _n "End of Cycle " as res `it' as text ///
		 ": deviance =   " as res %9.3f `dev' _n as text "{hline 61}"
}
if `nx'>1 {
	local s
	if `it'!=1 local s "s"
	if !`stable' di _n as err "No convergence" _cont
	else di _n as text ///
	 "Regression spline fitting algorithm converged" _cont
	di as text " after " as res `it' as text " cycle`s'."
}
if `stable' di _n as text "Transformations of covariates:" _n
/*
	Remove variables left behind
*/
forvalues i=1/`nx' {
	if "`stub`i''"!="" cap drop `stub`i''*
}
/*
	Store results
*/
if "`all'"!="" local restrict restrict(`touse')
else local ifuse if e(sample)
local finalvl	// predictors in final model
forvalues i=1/`nx' {
	local p=trim("`po`i''")
	local x `n`i''
	if ("`p'" != "") & ("`p'" != ".") {
		if ("`p'" == "1") & (`df`i'' == 1) local p linear
		if ("`p'"=="linear") | (wordcount("`x'") > 1) | `isfactor`i'' {
			local namex `x'
		}
		else {
			qui splinegen `x' `p' `ifuse', deg(`degree') `orthog' `restrict'
			local namex `r(names)'
			local knots`i' : char _dta[knots]
			local basis`i' : char _dta[rcsplines]
		}
		local finalvl `finalvl' `namex'
		local h`i' `namex' /* name(s) of spline transformed var */
	}
}
/*
	Estimate final (model.
*/
quietly `cmd' `lhs' `finalvl' `wgt' if e(sample), `regopt'
global S_1 `finalvl'
global S_2 `dev'
local nx2 0	/* number of predictors after expansion of groups (if any) */
forvalues i=1/`nx' {
	local p `po`i''
	if "`p'"=="" | "`p'"=="." {
		local p .
		local fdf 0
	}
	else if "`p'"=="linear" | "`p'"=="1" local fdf 1
	else {
		local npars: word count `p'
		local fdf=`npars'+(`degree'>0)
	}
	ereturn scalar Fp_fd`i'=`fdf'		// final degrees of freedom
	ereturn scalar Fp_id`i'=`df`i''		// initial degrees of freedom
	ereturn scalar Fp_al`i'=`alp`i''	// FP selection level
	ereturn scalar Fp_se`i'=`sel`i''	// var selection level
	if `degree'==0 local k `p'
	else if `fdf'>0 {
		if `df`i''==1 | `fdf'==1 local k Linear
		else local k [lin] `p' 	// knots plus "K" to make string-length = df
	}
	else local k .
	ereturn local Fp_k`i' `k'

	tokenize `n`i''
	while "`1'"!="" {
		local ++nx2
		ereturn local fp_x`nx2' `1'		// name of ith predictor in user order
		ereturn local fp_k`nx2' `k'
		if "`catz`i''"!="" ereturn local fp_c`nx2' 1
		ereturn local fp_knots`nx2' `knots`i'' 	// all knots
		ereturn local fp_basis`nx2' `basis`i''	// spline basis variables
		// new in Stata 12 version, store name(s) of transformed var(s)
		if wordcount("`n`i''") > 1 ereturn local fp_n`nx2' `1'
		else ereturn local fp_n`nx2' `h`i''
		mac shift
	}
}
ereturn scalar fp_dist=`dist'
ereturn local fp_wgt `weight'
ereturn local fp_exp `exp'
ereturn local fp_depv `lhs'
if `dist'==7 ereturn local fp_depv _t
ereturn scalar fp_dev=`dev'
ereturn local fp_rhs	// deliberately blank for consistency with fracpoly
ereturn local fp_opts `regopt'
ereturn local fp_fvl `finalvl'
ereturn scalar fp_nx=`nx2'
ereturn local fp_t1t "Regression Spline"
FracRep "spline" "  df  " "Knot positions"
ereturn local fp_cmd "fracpoly"
ereturn local fp_cmd2 "mfp"

end


program define ChkDepvar
	args xlist colon spec

	gettoken depvar spec : spec, parse("()") match(par)
	if ("`par'"!="") {
		di as err "invalid syntax"
		exit 198
	}
	fvunab depvar : `depvar'
	gettoken depvar rest : depvar
	global MFP_dv $MFP_dv `depvar'
	c_local `xlist' `rest' `spec'
end

program define GetVL /* [y1 [y2]] xvarlist [(xvarlist)] ... */
	macro drop MFP_*

	local xlist `0'
	if $MFpdist != 7 {
		ChkDepvar xlist : `"`xlist'"'
		if $MFpdist == 8 { /* intreg */ 
			ChkDepvar xlist : `"`xlist'"'
		}
	}
	if (`"`xlist'"'=="") {
		error 102
	}
	gettoken xvar xlist : xlist, parse("()") match(par)
	while (`"`xvar'"'!="" & `"`xvar'"'!="[]") {
		fvunab xvar : `xvar'
		local nvar : word count `xvar'
		if ("`par'"!="" | `nvar'==1) {
			global MFP_n = $MFP_n + 1
			global MFP_$MFP_n "`xvar'"
			global MFP_cur "$MFP_cur `xvar'"
		}
		else {
			tokenize `xvar'
			forvalues i=1/`nvar' {
				global MFP_n = $MFP_n + 1
				global MFP_$MFP_n "``i''"
				global MFP_cur "$MFP_cur ``i''"
			}
		}
		gettoken xvar xlist : xlist, parse("()") match(par)
		if ("`par'"=="(" & `"`xvar'"'=="") {
			di as err "empty () found"
			exit 198
		}
	}
end

program define FracOrd, sclass
local VV : di "version " string(_caller()) ", missing:"
version 11.0
sret clear
syntax [if] [in] [aw fw pw iw] [, CMd(string) ORDer(string) * ]
if "`cmd'"=="" local cmd "regress"
if "`order'"=="" {
	di as err "order() must be specified"
	exit 198
}
local order=substr("`order'",1,1)
if "`order'"!="+" &"`order'"!="-" &"`order'"!="r" &"`order'"!="n" {
	di as err "invalid order()"
	exit 198
}
quietly {
	local nx $MFP_n
	if "`order'"=="n" {
		// variable order as given
		forvalues i=1/`nx' {
			local r`i' `i'
		}
	}
	else {
		if "`order'"=="+" | "`order'"=="-" {
			`VV' `cmd' $MFP_dv $MFP_cur `if' `in' [`weight' `exp'], `options'
		}
		tempvar c n
		tempname p dfnum dfres stat
		gen `c'=.
		gen int `n'=_n in 1/`nx'
		if "`order'"=="+" | "`order'"=="-" {
			forvalues i=1/`nx' {
				local n`i' ${MFP_`i'}
				capture testparm `n`i''	/* could comprise >1 variable */
				local rc=_rc
				if `rc'!=0 {
					noi di as err "could not test ${MFP_`i'}---collinearity?"
					exit 1001
				}
				scalar `p'=r(p)
				if "`order'"=="-" /* reducing P-value */ replace `c'=-`p' in `i'
				else replace `c'=`p' in `i'
			}
		}
		if "`order'"=="r" replace `c'=uniform() in 1/`nx'
		sort `c'
		forvalues i=1/`nx' {
/*
	Store positions of sorted predictors in user's list
*/
			forvalues j=1/`nx' {
				if `i'==`n'[`j'] {
					local r`j' `i'
					local j `nx'
					continue, break
				}
			}
		}
	}
}
/*
	Store original positions of variables in ant1, ant2, ...
*/
forvalues i=1/`nx' {
	sret local ant`i' `r`i''
}
sret local names `names'
end

program define FracAdj, rclass
version 11.0
* Inputs: 1=macro `adjust', 2=case filter.
* Returns adjustment values in r(adj1),...
* Returns number of unique values in r(uniq1),...

args adjust touse
if "`adjust'"=="" {
	FracDis mean adjust
}
else FracDis "`adjust'" adjust
tempname u
forvalues i=1/$MFP_n {
	local x ${MFP_`i'}
	fvexpand `x'
	if "`r(fvops)'" == "true" {
		local a
	}
	else {
		quietly inspect `x' if `touse'
		scalar `u' = r(N_unique)
		local nx: word count `x'
		if `nx' == 1 {	// can only adjust if single predictor
			local a ${S_`i'}
			if "`a'" == "" | "`adjust'" == "" {	// identifies default cases
				if (`u' == 1) local a
				else if `u' == 2 {	// adjust to min value
					quietly summarize `x' if `touse', meanonly
					if (r(min) == 0) local a
					else local a = r(min)
				}
				else local a mean
			}
			else if ("`a'" == "no") local a
			else if ("`a'" != "mean") confirm num `a'
		}
		return scalar uniq`i'=`u'
	}
	return local adj`i' `a'
}
end

program define FracDis
version 11.0
* Disentangle varlist:string clusters---e.g. for DF.
* Returns values in $S_*.
* If `3' is null, lowest and highest value checking is disabled.

local target "`1'"		/* string to be processed */
local tname "`2'"		/* name of option in calling program */
if "`3'" != "" {
	local low "`3'"		/* lowest permitted value */
	local high "`4'"	/* highest permitted value */
}
tokenize "`target'", parse(",")
local ncl 0 			/* # of comma-delimited clusters */
while "`1'" != "" {
	if ("`1'" == ",") mac shift
	local ++ncl
	local clust`ncl' "`1'"
	mac shift
}
if ("`clust`ncl''" == "") local --ncl
if `ncl' > $MFP_n {
	di in red "too many `tname'() values specified"
	exit 198
}
/*
	Disentangle each varlist:string cluster
*/
forvalues i = 1 / `ncl' {
	tokenize "`clust`i''", parse("=:")
	// trailing blanks in list of variables cause problems
	local 1 = trim("`1'")
	if "`2'" != ":" & "`2'" != "=" {
		if `i' > 1 {
				noi di as err "invalid `tname'() value `clust`i'', must be first item"
				exit 198
		}
		local 2 ":"
		local 3 `1'
		local 1
		forvalues j = 1 / $MFP_n { 
			local nxi: word count ${MFP_`j'}
			if (`nxi' > 1) local 1 `1' (${MFP_`j'})
			else local 1 `1' ${MFP_`j'}
		}
	}
	local arg3 `3'
	if "`low'" != "" & "`high'" != "" {
		cap confirm num `arg3'
		if c(rc) {
			noi di as err "invalid `tname'() value `arg3'"
			exit 198
		}
		if `arg3' < `low' | `arg3' > `high' {
			noi di as err "`tname'() value `arg3' out of allowed range"
			exit 198
		}
	}
	while "`1'"!="" {
		gettoken tok 1 : 1
		if substr("`tok'", 1, 1) == "(" {
			local list
			while substr("`tok'", -1, 1) != ")" {
				if "`tok'" == "" {
					noi di as err "varlist invalid"
					exit 198
				}
				local list "`list' `tok'"
				gettoken tok 1 : 1
			}
			fvunab w : `list' `tok'
			FracIn "`w'"
			local v`s(k)' `arg3'
		}
		else {
			fvunab tok : `tok'
			local j 1
			local w : word 1 of `tok'
			while "`w'" != "" {
				FracIn `w'
				local v`s(k)' `arg3'
				local ++j
				local w : word `j' of `tok'
			}
		}
	}
}
forvalues j = 1 / $MFP_n {
	if ("`v`j''" != "") global S_`j' `v`j''
	else global S_`j'
}
end

program define FracIn, sclass /* target varname/varlist */
version 11.0
* Returns s(k) = index # of target in MFP varlists.
args v
sret clear
sret local k 0
forvalues j=1/$MFP_n {
	if "`v'"=="${MFP_`j'}" {
		sret local k `j'
		continue, break
	}
}
if `s(k)'==0 {
   	di as err "`v' is not an xvar"
   	exit 198
}
end

program define FracRep
* 1=descriptor e.g. FRACTIONAL POLYNOMIAL
* 2=param descriptor e.g. df
* 3=param names e.g. powers
version 11.0
args desc param paramv
local l=length("`paramv'")
forvalues i=1/$MFP_n {
	local l=max(`l',length("`e(Fp_k`i')'"))
}
local l=min(`l'+48, 65)
local title "Final multivariable `desc' model for `e(fp_depv)'"
local lt=length("`title'")
di _n as text "`title'"
di as text "{hline 13}{c TT}{hline `l'}"
di as text _skip(4) "Variable {c |}" _col(19) "{hline 5}" _col(24) "Initial" ///
 _col(31) "{hline 5}" _col(46) "{hline 5}" _col(51) "Final" ///
 _col(56) "{hline 5}"
di as text _col(14) "{c |} `param'" ///
 _col(25) "Select" ///
 _col(34) "Alpha" ///
 _col(43) "Status" ///
 _col(51) "`param'" ///
 _col(59) "`paramv'"
di as text "{hline 13}{c +}{hline `l'}"
forvalues i=1/$MFP_n {
	local pars `e(Fp_k`i')'
	if "`pars'"=="" | "`pars'"=="." {
		local final 0
		local status out
		local pars
	}
	else {
		local status in
		local final=e(Fp_fd`i')
	}
	local name ${MFP_`i'}
	local skip=12-length("`name'")
	if `skip'<=0 {
		local name=substr("`name'",1,9)+"..."
		local skip 0
	}
	local select=e(Fp_se`i')
	local alpha=e(Fp_al`i')
	if `select'==-1 local select " A.I.C."
	else local select: di %7.4f `select'
	if `alpha'==-1 local alpha " A.I.C."
	else local alpha: di %7.4f `alpha'

	di as text _skip(`skip') "`name' {c |}" as res ///
	 _col(19) e(Fp_id`i') ///
	 _col(24) "`select'" ///
	 _col(33) "`alpha'" ///
	 _col(45) "`status'" ///
	 _col(53) "`final'" ///
	 _col(59) "`pars'"
}
di as text "{hline 13}{c BT}{hline `l'}"
if "`e(cmd2)'"=="stpm" ml display
else `e(cmd)'
di as text "Deviance:" as res %9.3f e(fp_dev) as text "."
end

program define splsel, rclass
version 11.0
gettoken cmd 0: 0
if $MFpdist == 8 		local vv varlist(min=3 fv)
else if $MFpdist != 7 	local vv varlist(min=2 fv) 
else 				local vv varlist(min=1 fv)
syntax `vv' [if] [in] [aw fw pw iw] [, ///
 ALpha(real .05) SELect(real 1) noHEad DF(int 0) ///
 BAse(string) DEGree(int 3) UNIQUE * ]
local omit = (`select' < 1)
if `df' < 0 {
	noi di as err "invalid df"
	exit 198
}
if (`df' == 0) local df 4
if ("`weight'" != "") local weight "[`weight'`exp']"
tokenize `varlist'
tokenize `varlist'
if $MFpdist == 8 {
	local lhs `1' `2'
	local n `3'
	mac shift 3
}
else if $MFpdist != 7 {
	local lhs `1'
	local n `2'
	mac shift 2
}
else {
	local lhs
	local n `1'
	mac shift 1
}
local nn `*'
if "`head'"=="" {
	di as text "{hline 61}"
	di as text "Variable    Final  Final    Max. spline cf. null   Final knot"
	di as text "             df  deviance   dev. diff. df     P    positions"
	di as text "{hline 61}"
}
local vname `n' `nn'
if length("`vname'")>12 local vname=substr("`vname'",1,9)+"..."
if "`nn'"!="" | `df'==1 {
	// test linear for single or group of predictors, adjusting for base
	local pwrs2 .
	if "`base'"!="" local base base(`base')
	local n `n' `nn'
	local nnn: word count `n'	// no. of vars being tested
	qui TestVars `cmd' `lhs' `n' `if' `in' `weight', `base' `options'
	local P = r(P)
	local dev1 = r(dev1)
	local dev0 = r(dev0)
	local devdiff = r(devdif)
	local vs1 null
	local vs lin.
	local dfirst `dev0'
	local aic 0	// aic not implemented
	if `aic'==0 {
		if `P'<=`select' {
			local star *
			local dev `dev1'
			local dfx 1
			local knots linear
		}
		else {
			local star
			local n
			local dev `dev0'
			local dfx 0
			local knots
		}
	}
	else {	// !! select by AIC not implemented
		if (`dev1'+2*`nnn')<`dev0' {
			local star *
			local dev `dev1'
		}
		else {
			local star
			local n
			local dev `dev0'
		}
	}
	di as text "`vname'" as res _col(15) `dfx' ///
	 _col(17) %9.3f `dev' ///
	 _col(27) %9.3f `devdiff' ///
	 _col(38) %4.0f `df' ///
	 _col(44) %6.3f `P' ///
	 _col(52) "`knots'"

	return local dffinal `dfx'
	return scalar dev=`dev'
	return local n `n'
	return local knots `knots'
	exit
}
local vname `n'
qui uvrs `cmd' `lhs' `n' `base' `if' `in' `weight', linear ///
 df(`df') `unique' degree(`degree') alpha(`alpha') `options'
local n `e(fp_xp)'
local knots `e(fp_k1)'
local dev0=e(fp_d0)		// deviance of model excluding `n'
local dev=e(fp_dev)		// deviance of selected model
local devsat=e(fp_dsat)	// deviance of maximal spline model
local devdiff=e(fp_dd)
local nonzero=(`degree'>0 & "$S_3"!="")
local linear=(`df'==1)
local dfx=e(fp_fdf)		// df of xvar in final model
local P=e(fp_Pful)		// P-value for testing maximal spline model against null
if `omit' & `P'>`select' {
/*
	`Dropping' RHS variable since 1 df test of beta=0 is non-sigficant
	at `select', the overall selection level.
*/
	local dev `dev0'
	local dfx 0
	local n
	local knots
}
di as text "`vname'" as res _col(15) `dfx' ///
 _col(17) %9.3f `dev' ///
 _col(27) %9.3f `dev0'-`devsat' ///
 _col(38) %4.0f `df' ///
 _col(44) %6.3f `P' ///
 _col(52) "`knots'"
return local dffinal `dfx'
return scalar dev=`dev'
return local n `n'
return local knots `knots'
end

* Updated 20apr2012.
program define TestVars, rclass /* LR-blocktests variables in varlist, adj base */
	version 11.0
	gettoken cmd 0 : 0, parse(" ")
	xfrac_chk `cmd' 
	if `s(bad)' {
		di as err "invalid or unrecognised command, `cmd'"
		exit 198
	}
	local dist `s(dist)'
	local glm `s(isglm)'
	local qreg `s(isqreg)'
	local xtgee `s(isxtgee)'
	local normal `s(isnorm)'
	if $MFpdist == 8 local vv varlist(min=3 fv)
	else if $MFpdist != 7 local vv varlist(min=2 fv) 
	else local vv varlist(min=1 fv)
	syntax `vv' [if] [in] [aw fw pw iw], ///
	 [, DEAD(string) noCONStant BASE(varlist fv) * ]
	frac_cox "`dead'" `dist'
	if "`constant'"=="noconstant" {
		if "`cmd'"=="fit" | "`cmd'"=="cox" | $MFpdist==7 {
			di as err "noconstant invalid with `cmd'"
			exit 198
		}
		local options "`options' noconstant"
	}
	tokenize `varlist'
	if $MFpdist != 7 {
		local y `1'
		mac shift
		if $MFpdist == 8 {
			local y1 `y'
			local y2 `1'
			local y `y1' `y2'
			mac shift
		}
	}
	local rhs `*'
	tempvar touse
	quietly {
		mark `touse' [`weight' `exp'] `if' `in'
		if $MFpdist == 8 {
			replace `touse' = 0 if `y1' >= . & `y2' >= .
			markout `touse' `rhs' `base' `dead'
		}
		else markout `touse' `rhs' `y' `base' `dead'
		if "`dead'"!="" {
			local options "`options' dead(`dead')"
		}
	/*
		Deal with weights.
	*/
		frac_wgt `"`exp'"' `touse' `"`weight'"'
		local mnlnwt = r(mnlnwt) /* mean log normalized weights */
		local wgt `r(wgt)'
		count if `touse'
		local nobs = r(N)
	}
	/*
		Calc deviance=-2(log likelihood) for regression on base covars only,
		allowing for possible weights.
	
		Note that for logit/clogit/logistic with nocons, must regress
		on zero, otherwise get r(102) error.
	*/
	if (`glm' | `dist'==1) & "`constant'"=="noconstant" {
		tempvar z0
		qui gen `z0'=0
	}
	qui `cmd' `y' `z0' `base' `wgt' if `touse', `options'
	if `xtgee' & "`base'"=="" {
		global S_E_chi2 0
	}
	if `glm' {
		// Note: with Stata 8 scale param is e(phi); was e(delta) in Stata 6
		// Also e(dispersp) has become e(dispers_p).
 		local scale 1
 		local small 1e-6
 		if abs(e(dispers_p)/e(phi)-1)>`small' & ///
		 abs(e(dispers)/e(phi)-1)>`small' ///
		 local scale = e(phi)
	}
	frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
	local dev0 = r(deviance)
	if `normal' local rsd0=e(rmse)
	/*
		Fit full model
	*/
	`cmd' `y' `rhs' `base' `wgt' if `touse', `options'
	frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
	local dev1 = r(deviance)
	if `normal' local rsd1=e(rmse)
	local df_m = e(df_m)
	// PR 22mar2009 -start-
	fvexpand `rhs'
	if "`r(fvops)'"=="true" {
		local df = wordcount("`r(varlist)'") - 1
	}
	else local df: word count `rhs'
	frac_eqmodel k
	local df = `df' * `k'
	local df_r = `nobs' - `df_m' - ("`constant'"!="noconstant")
	local d = `dev0' - `dev1'
	frac_pv `normal' "`wgt'" `nobs' `d' `df' `df_r'
	local P = r(P)
	di as text "Deviance 1:" as res %9.2g `dev1' as text ". " _cont
	di as text "Deviance 0:" as res %9.2g `dev0' as text ". "
	di as text "Deviance d:" as res %9.2g `d' as text ". P = " as res %8.4f `P'
	// store
	return scalar dev0 = `dev0'
	return scalar dev1 = `dev1'
	if `normal' {
		return scalar s0 = `rsd0'
		return scalar s1 = `rsd1'
	}
	return scalar df_m = `df'
	return scalar df_r = `df_r'
	return scalar devdif = `d'
	return scalar P = `P'
	return scalar N = `nobs'
end
