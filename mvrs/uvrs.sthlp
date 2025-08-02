{smcl}
{* *! version 2.0.0  24apr2012}{...}
{hline}
help for {hi:uvrs}{right:Patrick Royston}
{hline}


{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{hi:uvrs} {hline 2}}Univariate regression spline models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:uvrs}
[, {cmd:all}
{cmdab:al:pha}{cmd:(}{it:#}{cmd:)}
{cmdab:deg:ree}{cmd:(}{it:#}{cmd:)}
{cmd:df(}{it:#}{cmd:)}
{cmdab:kn:ots}{cmd:(}{it:knot_list}{cmd:)}
{cmdab:noorth:og}
{cmdab:rep:ort}{cmd:(}{it:numlist}{cmd:)}
{cmdab:tra:ce}
]
{cmd::}
{it:regression_cmd}
[{it:yvar}]
{it:xvar}
[{it:covars}]
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{it:weight}]
[{cmd:,}
{it:regression_cmd_options}
]

{pstd}
where

{p 8 8 2}
{it:regression_cmd} includes
{help clogit},
{help glm},
{help logistic},
{help logit},
{help ologit},
{help oprobit},
{help poisson},
{help probit},
{help qreg},
{help regress},
{help stcox},
{help streg},
{help xtgee}.

{p 8 8 2}
{it:yvar} is required with all {it:regression_cmd}s except
{cmd:stcox}, {cmd:streg} and {cmd:stpm2} (if installed).
For the these three commands, {it:yvar} is not
allowed, and you must have {help stset} your data first.

{pstd}
{cmd:uvrs}
shares the features of all estimation commands; see help {help estcom}.

{pstd}
{cmd:xfracplot} (same syntax as {help fracplot}) may be used following
{cmd:uvrs} to show plots of fitted values and partial residuals.
{cmd:xfracpred} (same syntax as {help fracpred}) may be used for prediction.

{pstd}
All weight types supported by {it:regression_cmd} are allowed; see help
{help weights}.

{pstd}
{it:covars} may include factor variables. {it:xvar} cannot be a factor variable.


{title:Description}

{pstd}
{cmd:uvrs} selects the regression spline (RS) model which best predicts the
outcome variable {it:yvar} from the continuous RHS variable {it:xvar}, adjusting
linearly for covariates in {it:covars} (if specified).


{title:Options}

{phang}
{cmd:all} includes out of sample observations when generating the spline
transformations of {it:xvar}. By default, the generated variables contain
missing values outside the estimation sample.

{phang}
{cmd:alpha(}{it:#}{cmd:)} determines the nominal P-value used for
testing the statistical significance of basis functions 
representing knots in the spline model. Default {it:#} is 1,
meaning fit the full spline model without simplification.

{phang}
{cmd:degree(}{it:#}{cmd:)} specifies the degree of spline. Allowed choices
for {it:#} are 0 (meaning a step function), 1 (meaning a linear spline),
and 3 (meaning a cubic spline). Default {it:#} is 3.

{phang}
{cmd:df(}{it:#}{cmd:)} determines how many spline terms in {it:xvar}
are used initially.  The default is 4 which corresponds to 3 interior knots.

{phang}
{cmd:knots(}{it:knot_list}{cmd:)} specifies knots in {it:knot_list}
 and over-rides the default knots implied by {cmd:df()}.

{phang}
{opt noorthog} suppresses orthogonalization of the spline basis functions. By
default, the basis functions are linearly transformed to have mean 0, SD 1
and correlation 0 with each other. See Remarks.

{phang}
{opt report(numlist)} computes the difference in fitted values between successive
values of {it:xvar1} specified in {it:numlist}, together with confidence interval.
The values of {it:xvar1} in {it:numlist} are stored in a matrix {cmd:e(repx)},
 and the difference and its standard error in matrices {cmd:e(repdiff)}
 and {cmd:e(repse)}, respectively.

{phang}
{cmd:trace} provides details of all models fitted and the progress of 
the knot selection algorithm.

{phang}
{it:regression_cmd_options} are options appropriate to the regression
command in use.  For example, for {opt stcox}, {it:regression_cmd_options} may
include {opt efron} or some other alternate method for handling tied failures.


{title:Remarks}

{pstd}
{cmd:uvrs} leaves variables in the data named {it:xvar}{cmd:_0},
 {it:xvar}{cmd:_1}, {it:xvar}{cmd:_2}, ..., the number of variables
 depending on the number of knots in the selected model. These variables
 are the basis functions for the regression spline. With degree 3,
 these are linearly transformed to be orthonormal, {it:xvar}{cmd:_0}
 being {it:xvar} standardized to have mean 0 and variance 1.

    {title:Method of RS model selection}

{pstd}
To determine an RS model for a given continuous predictor x, the following
approach is used. The algorithm, which is implemented in {cmd:uvrs},
embodies a closed test procedure, a sequence of tests designed to maintain
the overall type I error probability at a prespecified nominal level, alpha,
such as 0.05. The value of alpha is controlled through the {cmd:alpha(}{it:#}{cmd:)} option.
The quantity alpha is the key determinant of the complexity (in dimension
and therefore in shape) of a selected function.

{pstd}
Initially, the most complex permitted RS model is chosen. This is determined
by the d.f. assigned to the RS function by the {cmd:df()} option. As explained
above, the d.f. equals m + 1, where m is the maximum number of knots to be
considered and m = 0 means the linear function.

{pstd}
Let us call the most complex model M_m and the linear function M_0. First,
model M_m is compared with the null model (omitting x), using a chisquare
test with m + 1 d.f. If the test is not significant at the alpha level,
the procedure stops and x is eliminated. Otherwise, the algorithm next
compares the fit of M_m with that of M_0, on m d.f. If the deviance difference
is not significant at the alpha level, M_0 is chosen by default and the
algorithm stops.

{pstd}
Now consider the m possible RS models using just one of the m available knots.
The best-fitting of these models, say M_1, is found and compared with M_m.
If M_m does not fit significantly better than M_1 at the alpha level, there
is no evidence that the more complex model is needed, so model M_1 is
accepted and the algorithm stops. Otherwise, M_1 is augmented with each
of the remaining m - 1 knots in turn, the best fitting model, M_2, is found,
and M_2 is compared with M_m. The procedure continues in this fashion until
either a test is non-significant and the procedure stops, or all the tests
are significant, in which case model M_m is the final choice.

{pstd}
If x is to be `forced' into the model, the first comparison, between M_m and
the null model, is omitted. All tests are based on chisquare statistics from
deviance (-2× log-likelihood) differences.

    {title:Orthogonalization and prediction}

{pstd}
The {opt noorthog} option comes into its own when one is predicting fitted
values from a spline model estimated on one dataset into a second dataset (or
on a subset of a given dataset). Consider the following sequence of commands:

{phang}{cmd: . use dataset1}{p_end}
{phang}{cmd: . uvrs regress y x, noorthog}{p_end}
{phang}{cmd: . predict fit1}{p_end}
{phang}{cmd: . local knots `e(knots)'}{p_end}
{phang}{cmd: . local bknots `e(bknots)'}{p_end}
{phang}{cmd: . estimates save uvrs_ests, replace}{p_end}
{phang}{cmd: . // Create basis variables on 2nd dataset, restore estimates and predict fitted values}{p_end}
{phang}{cmd: . use dataset2, replace}{p_end}
{phang}{cmd: . splinegen x `knots', bknots(`bknots')}{p_end}
{phang}{cmd: . estimates use uvrs_ests}{p_end}
{phang}{cmd: . predict fit2}{p_end}

{pstd}
The variable {cmd:fit2} contains the values of {cmd:y} predicted from the
parameters estimated from the spline model of {cmd:y} on {cmd:x} in the first
dataset. The {opt noorthog} option is used when fitting the {cmd:uvrs} model
to avoid the problems that would arise when trying to orthogonalize the basis
functions in the second dataset. This requires the use of a particular matrix,
which is not available in the present implementation.


{title:Examples}

{phang}
{cmd:. uvrs: regress mpg weight}

{phang}
{cmd:. uvrs, df(3) report(2000(1000)5000) : regress mpg weight displacement i.foreign}

{phang}
{cmd:. uvrs, df(6) degree(1) alpha(0.05) trace : regress mpg weight displacement i.foreign}

{phang}
{cmd:. xfracplot weight}

{phang}
{cmd:. xfracplot displacement}


{title:Author}

{pstd}
Patrick Royston, MRC Clinical Trials Unit, London.{break}
pr@ctu.mrc.ac.uk


{title:Acknowledgment}

{pstd}
Gareth Ambler (Department of Statistical Science, University College, London) played a major
role in developing the code for {cmd:splinegen}.


{title:Also see}

{p 4 13 2}
Online:  help for {help estcom}, {help postest};
{help fracpoly}; {help mfp}; {help mvrs}; {help splinegen}
{p_end}
