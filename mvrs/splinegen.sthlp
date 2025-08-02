{smcl}
{* *! version 1.2.2  05dec2012}{...}
{hline}
help for {hi:splinegen}{right:Patrick Royston}
{hline}


{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:splinegen} {hline 2}}Generate regression spline basis functions{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:splinegen} {it:varname} [ {it:#} [ {it:# ...}]] [{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,}
{cmdab:ba:sis(}{it:stubname}{cmd:)}
{cmdab:bk:nots(}{it:# #}{cmd:)}
{cmdab:deg:ree(}{it:#}{cmd:)}
{cmd:df(}{it:#}{cmd:)}
{cmdab:kf:ig(}{it:#}{cmd:)}
{cmdab:o:rthog}
{cmdab:unique}
]


{title:Description}

{pstd}
{cmd:splinegen} creates new variables named {it:varname}{hi:_1},
{it:varname}{hi:_2}, ..., containing basis functions for regression
splines using knots specified either in {it:#} [{it:#} {it:...}]
or via the {cmd:df()} option.


{title:Options}

{phang}
{cmd:basis(}{it:stubname}{cmd:)} defines {it:stubname} as the first
characters of the names of the new variables holding the basis
functions. Default {it:stubname} is {it:varname}. The new variables
are called {it:stubname}{hi:_1}, {it:stubname}{hi:_2}, ... .

{phang}
{cmd:bknots(}{it:# #}{cmd:)} define boundary knots for the
spline. The spline function is linear beyond the boundary
knots. Default values of {it:# #} are the minimum and maximum
values of {it:varname}.

{phang}
{cmd:degree(}{it:#}{cmd:)} is the degree of spline basis functions
desired. Possible values of {it:#} are 0, 1, 3. Quadratic
splines or splines higher than cubic are not supported at
this time. Default {it:#} is 3, meaning cubic spline.

{phang}
{cmd:df(}{it:#}{cmd:)} sets the desired degrees of freedom
(df) of the spline basis. The number of knots required
is one less than the df for linear and cubic splines, and
equal to the df for zero-order splines (i.e. a
step-function or dummy-variable basis). Knots are placed
at equally spaced centiles of the distribution of
{it:varname}, e.g. for linear or cubic splines
with {cmd:df(4)}, knots are placed
at the 25th, 50th and 75th centiles of the distribution of
{it:varname}. For degree 1 and 3, default {it:#} is determined
from the formula int(n^0.25)-1 where n is the sample size;
for degree 0, {it:#} is int(n^0.25).

{phang}
{cmd:kfig(}{it:#}{cmd:)} determines the amount of rounding
applied to the knots determined automatically from the
distribution of {it:varname}. The default {it:#} is 6,
meaning 4 significant figures are preserved. You are
unlikely to need this option.

{phang}
{cmd:orthog} creates orthogonalized basis functions. After orthogonalization,
all the basis functions are uncorrelated and have mean 0 and SD 1. 
The default is to create non-orthogonalized basis functions, which are
typically highly correlated.

{phang}
{cmd:unique} chooses knots based only on unique values of {it:varname}.
If {it:varname} has ties, only a single representative of each tied
set is used, so the sample on which knots are calculated is effectively
reduced. If {it:varname} has no ties, {cmd:unique} has no effect.


{title:Examples}

{phang}{cmd:. splinegen x 12 20 40}

{phang}{cmd:. splinegen x, df(3) name(Z)}

{phang}{cmd:. splinegen x, df(4) degree(1) orthog unique}


{title:Author}

{pstd}
Patrick Royston, MRC Clinical Trials Unit at UCL, London.{break}
j.royston@ucl.ac.uk


{title:Acknowledgment}

{pstd}
Gareth Ambler (Dept of Statistical Science, UCL, London) played a major
role in developing the code for {cmd:splinegen}.


{title:Also see}

{psee}
Online:  help for {help mvrs}, {help uvrs}
