{smcl}
{* *! version 2.0.1  07nov2013}{...}
{hline}
help for {hi:mvrs}{right:Patrick Royston}
{hline}


{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{hi:mvrs} {hline 2}}Multivariable regression spline models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:mvrs}
[{cmd:,}
{cmd:all}
{cmdab:al:pha}{cmd:(}{it:alpha_list}{cmd:)}
{cmdab:cyc:les}{cmd:(}{it:#}{cmd:)}
{cmd:df(}{it:df_list}{cmd:)}
{cmdab:deg:ree}{cmd:(}{it:#}{cmd:)}
{cmdab:dfd:efault}{cmd:(}{it:#}{cmd:)}
{cmdab:kn:ots}{cmd:(}{it:knot_list}{cmd:)}
{cmdab:orth:og}
{cmdab:sel:ect}{cmd:(}{it:select_list}{cmd:)}
{cmdab:xo:rder}{cmd:(}{c -(}{cmd:+}|{cmd:-}|{cmd:n}{c )-}{cmd:)}
]
{cmd::}
{it:regression_cmd}
[{it:yvar}]
{it:xvarlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{it:weight}]
[
{it:regression_cmd_options}
]

{pstd}
where

{phang}
{it:regression_cmd} includes
{helpb clogit},
{helpb cnreg},
{helpb glm},
{helpb logistic},
{helpb logit},
{helpb mlogit},
{helpb nbreg},
{helpb ologit},
{helpb oprobit},
{helpb poisson},
{helpb probit},
{helpb qreg},
{helpb regress},
{helpb stcox},
{helpb streg},
{helpb xtgee}.

{phang}
{it:xvarlist} has elements of type {it:varlist} and/or
{cmd:(}{it:varlist}{cmd:)}, e.g.,

{p 12 12 2}
{cmd:x1 x2 (x3 x4 x5)}

{phang}
{it:xvarlist} may include factor variables.

{phang}
{it:yvar} is required with all {it:regression_cmd}s except
{cmd:stcox} and {cmd:streg}.  For the latter two commands, {it:yvar} is not
allowed, and you must have {help stset} your data first.

{pstd}
{cmd:mvrs}
shares the features of all estimation commands; see help {help estcom}.

{pstd}
{help xfracplot} may be used following {cmd:mvrs} to show plots of fitted values
and partial residuals. {help xfracpred} may be used for prediction.

{pstd}
All weight types supported by {it:regression_cmd} are allowed; see help
{help weights}.


{title:Description}

{pstd}
{cmd:mvrs} selects the regression spline (RS) model which best predicts the
outcome variable {it:yvar} from the RHS variables in {it:xvarlist}.


{title:Options}

{phang}
{cmd:all} includes out of sample observations when generating the spline
transformations of predictors. By default, the generated variables contain
missing values outside the estimation sample.

{phang}
{cmd:alpha(}{it:alpha_list}{cmd:)}
    sets the significance levels for testing between RS models
    of differing complexity (numbers of knots).
    The rules for {it:alpha_list} are the same as for
    {it:df_list} in the {cmd:df()} option (see below).
    The default nominal P-value (significance level, selection level) is 0.05
    for all variables.

{pin}
    Example:  {cmd:alpha(0.01)} specifies all variables have RS
    selection level 1 percent.

{pin}
    Example:  {cmd:alpha(0.05, weight:0.1)}
    specifies all variables except {cmd:weight} have RS selection level 5
    percent; {cmd:weight} has level 10 percent.

{phang}
{cmd:cycles(}{it:#}{cmd:)} is the maximum number of iteration cycles
    permitted.  {cmd:cycles(5)} is the default.

{phang}
{cmd:degree(}{it:#}{cmd:)} determines the type of spline transformation
    to be used. Valid values of {it:#} are 0, 1 and 3. The value of 0
    denotes a step function whereas 1 and 3 denote linear and cubic splines,
    respectively. The cubic splines are 'natural', that is are forced to
    be linear beyond the observed range of the covariate in question.
    Default {it:#} is 3, meaning a natural cubic spline.

{phang}
{cmd:df(}{it:df_list}{cmd:)}
    sets up the degrees of freedom (df) for each predictor. For splines
    of degree 1 and 3, the df (not counting the regression constant,
    {cmd:_cons}) are equal to the number of knots plus 1. For splines
    of degree 0 (i.e. step functions), the df are equal to the number
    of knots. Specifying {cmd:df(1)} forces linear functions (no knots)
    for splines of degree 1 or 3, but forces dichotomization at the
    median for splines of degree 0.
    The first item in {it:df_list} may be either {it:#} or
    {it:varlist}{cmd::}{it:#}.  Subsequent items must be
    {it:varlist}{cmd::}{it:#}.  Items are separated by commas and {it:varlist}
    is specified in the usual way for variables.  With the first type of item,
    the df for all predictors are taken to be {it:#}.  With the second type of
    item, all members of {it:varlist} (which must be a subset of
    {it:xvarlist}) have {it:#} df.

{pin}
    The default degrees of freedom for a predictor of type varlist specified in
    {it:xvarlist} but not in {it:df_list} are assigned according to the
     number of distinct (unique) values of the predictor, as follows:

        {hline 43}
        # of distinct values    default df
        {hline 43}
        One                     (invalid predictor)
        Two or three            1
        Four or five            min(2, {cmd:dfdefault()})
        Six or more             {cmd:dfdefault()}
        {hline 43}

{pin}
    Example:  {cmd:df(4)}{break}
    All variables have 4 df.

{pin}
    Example:  {cmd:df(2, weight displ:4)}{break}
    {cmd:weight} and {cmd:displ} have 4 df, all other variables have 2 df.

{pin}
    Example:  {cmd:df(weight displ:4, mpg:2)}{break}
    {cmd:weight} and {cmd:displ} have 4 df, {cmd:mpg} has 2 df, all other
    variables have the default of 1 df.

{pin}
    Example:  {cmd:df(weight displ:4, 2)}{break}
    This combination is invalid. The final 2 would override the earlier 4.

{phang}
{cmd:dfdefault(}{it:#}{cmd:)} determines the default maximum degrees of
    freedom (df) for a predictor. Default # is 4 (3 knots for degree 1
    or 3, 4 knots for degree 0).

{phang}
{cmd:knots}{cmd:(}{it:knot_list}{cmd:)}
    sets knots for covariates individually.  The syntax of
    {it:knot_list} is the same as for {it:df_list} in the {cmd:df()}
    option. By default, knots are placed at equally spaced percentiles
    of the distribution of the covariate {it:x} in question. For example,
    by default three knots are placed at the 25th, 50th and 75th
    percentiles of any continuous {it:x}. The {cmd:knots()} option can
    be used to over-ride this choice.

{pin}
    Example:  {cmd:knots(1 3 5)}{break}
    All variables have knots at 1,3,5 (unlikely to be sensible).

{pin}
    Example:  {cmd:knots(x5:1 3 5)}{break}
    All variables except {cmd:x5} have default knots, x5 has knots at 1,3,5.

{phang}
{cmd:orthog} creates orthogonalized spline basis functions. After
orthogonalization, all the basis functions are uncorrelated and have
mean 0 and SD 1. The default is to create orthogonalized basis functions.
{opt noorthog} produces non-orthogonalized basis functions. They are
typically highly correlated, possibly resulting in numerical instability
when fitting the model.

{phang}
{cmd:select(}{it:select_list}{cmd:)}
    sets the nominal P-values (significance levels) for variable selection by
    backward elimination.  A variable is dropped if its removal causes a
    non-significant increase in deviance.  The rules for {it:select_list} are
    the same as for {it:df_list} in the {cmd:df()} option (see above).  Using
    the default selection level of 1 for all variables forces them all into
    the model.  Setting the nominal P-value to be 1 for a given variable
    forces it into the model, leaving others to be selected or not. The
    nominal P-value for elements {it:varlist} of {it:xvarlist} is specified
    by including {cmd:(}{it:varlist}{cmd:)} in {it:select_list}.
    See also the {cmd:alpha()} option and {it:Remarks}). The nominal P-value
    for elements {it:varlist} of {it:xvarlist} bound by parentheses is
    specified by including {cmd:(}{it:varlist}{cmd:)} in {it:select_list}.

{pin}
    Example:  {cmd:select(0.05)}{break}
    All variables have nominal P-value 5 percent.

{pin}
    Example:  {cmd:select(0.05, weight:1)}
    All variables except {cmd:weight} have nominal P-value 5 percent,
    {cmd:weight} is forced into the model.

{phang}
{cmd:xorder}{cmd:(}{c -(}{cmd:+}|{cmd:-}|{cmd:n}{c )-}{cmd:)}
    determines the order of entry of the covariates into the model selection
    algorithm. The default is {cmd:xorder(+)}, which enters them in decreasing
    order of significance in a multiple linear regression (most significant
    first). {cmd:xorder(-)} places them in reverse significance order whereas
    {cmd:xorder(n)} respects the original order in {it:xvarlist}.

{phang}
{it:regression_cmd_options} may be any of the options appropriate to
    {it:regression_cmd}.


{title:Remarks}

{pstd}
For elements in {it:xvarlist}, {cmd:mvrs} leaves
variables in the data named {it:xvar}{cmd:_1},
{it:xvar}{cmd:_2}, ...  where {it:xvar} represents the
letters of the name of {it:xvar1}, and so on for {it:xvar2}, {it:xvar3}, etc.
The new variables contain the spline basis variables for the best-fitting
spline model for {it:xvar1}, {it:xvar2}, ...

    {title:Iteration report}

{pstd}
By default, for each continuous predictor, X, {cmd:mvrs} compares null, linear
and lower-dimensional spline models for X with the most complex spline model
allowed by the specification ({cmd:df()} and {cmd:dfdefault()} options).
The deviance for each of these nested sub-models is given in the column
headed Deviance. The column labelled "Final knots" shows the knots
selected as best-fitting, subject to the testing procedure.
All the other predictors currently selected are included, with
their transformations (if any).  For models specified as having 1 d.f.,
the only choice is whether the variable enters the model or not.

    {title:Estimation algorithm}

{pstd}
The model-selection algorithm has the flavour of a closed-test procedure.
The {it:xvars} are processed in turn.
Initially, {cmd:mvrs} silently arranges {it:xvarlist} in order of increasing
P-value (i.e., of decreasing statistical significance) for omitting each
predictor from the model comprising {it:xvarlist} with each term linear.  The
aim is to model relatively important variables before unimportant ones.  This
may help to reduce potential model-fitting difficulties caused by collinearity
or, more generally, `concurvity' among the predictors.  (See the
{cmd:xorder()} option above for details of how to change the ordering.)

{pstd}
At the initial cycle, the best-fitting RS function for {it:xvar1} (the first
of {it:xvarlist}) is determined, with all the other variables assumed linear.
For details of the procedure, see Method of RS Model Selection, below).
The functional form (but NOT the estimated
regression coefficients) for {it:xvar1} is kept, and the process is repeated
for {it:xvar2}, {it:xvar3}, etc.  The first iteration concludes when all the
variables have been processed in this way.  The next cycle is similar, except
that the functional forms from the initial cycle are retained for all
variables excepting the one currently being processed.

{pstd}
A variable whose functional form is prespecified to be linear (i.e. to have 1
df) is tested only for exclusion within the above procedure when its nominal
P-value (selection level) according to {cmd:select()} is less than 1.

{pstd}
Updating of RS functions and candidate variables continues until the functions
and variables included in the overall model do not change (convergence).
Convergence is usually achieved within 1 to 4 cycles.

    {title:Method of RS model selection}

{pstd}
The model-selection algorithm in {cmd:mvrs} embodies a type of backward elimination with
the flavour of a closed test procedure. The latter is a sequence of tests
maintaining the overall type I error rate at a prespecified nominal level
such as 5%. The algorithm starts from a most complex permitted RS model and
attempts to simplify the model by removing spline terms according to their
statistical significance.

{pstd}
The closed test procedure for choosing an RS model with maximum
permitted d.f. determined by {cmd:df()}, 
for a single continuous predictor, {it:x},
is described in the {it:Remarks} section of {help uvrs}.


{title:Examples}

{phang}
{cmd:. mvrs: regress mpg weight displacement i.foreign}

{phang}
{cmd:. mvrs, df(1, displacement:4) : regress mpg weight displacement i.foreign}

{phang}
{cmd:. mvrs, df(2, foreign:1) degree(1) select(0.05, i.foreign:1) : regress mpg weight displacement i.foreign}

{phang}
{cmd:. mvrs, dfdefault(2) select(0.05, foreign i.rep78:1) : regress mpg weight displacement foreign i.rep78}

{phang}
{cmd:. xi: mvrs, dfdefault(2) degree(0) : regress mpg weight displacement i.foreign i.rep78}

{phang}
{cmd:. xfracplot weight}


{title:Author}

{pstd}
Patrick Royston, MRC Clinical Trials Unit at UCL, London.{break}
j.royston@ucl.ac.uk


{title:Also see}

{p 4 13 2}
Manual:  {hi:[R] mfp}

{p 4 13 2}
Online:  help for {help estcom}, {help postest}; {help uvrs};
{help splinegen}; {help fracpoly}; {help mfp}
{p_end}
