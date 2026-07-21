# Selection 

## Description of the program

![img-0.jpeg](img-0.jpeg)
in cooperation with the Roslin Institute

Developed by Marc J.M. Rutten and Piter Bijma, 2001<br>Animal Breeding and Genetics Group<br>Department of Animal Sciences<br>Wageningen University

with financial support from The Netherlands Technology Foundation

# What is SELACTION 

SELACTION is a computer program that predicts response to selection and rates of inbreeding for practical livestock improvement programs. The program uses deterministic simulation and requires little computing time; it can be used as an interactive optimization tool. SELACTION makes the existing theory on breeding programs available as a userfriendly tool for breeding companies and scientists.

## What can SELACTION do?

SELACTION can predict response to selection and/or inbreeding for the following types of breeding schemes and combinations thereof.

- Multitrait selection. SELACTION predicts response to selection for breeding schemes with up to 20 traits.
- BLUP. SELACTION predicts response to selection on Best Linear Unbiased Predictors of breeding values using an animal model.
- Sib and progeny info. SELACTION predicts response to selection for breeding programs using information from full and half sibs and/or progeny.
- Multistage selection. SELACTION predicts response to selection for breeding schemes where selection takes place in 2 or 3 stages.
- Discrete and overlapping generations. SELACTION predicts response to selection both for populations with discrete generations and for populations with overlapping generations. Populations with overlapping generations can have up to 20 age classes.
- Inbreeding. SELACTION predicts the rate of inbreeding for populations with discrete generations and multitrait selection. (Prediction of the rate of inbreeding takes account of selection.)
The examples included in the SELACTION manual illustrate the variety of breeding schemes that SELACTION can deal with.


## How does SELACTION work?

SELACTION uses deterministic methods to predict response to selection and rates of inbreeding of livestock breeding schemes. Prediction of response to selection is based on advanced selection index theory. Prediction of the rate of inbreeding is based on the longterm genetic contribution theory. SELACTION uses a hierarchical mating structure where dams are nested within sires and random mating of selected animals is applied.
The genetic model for each trait is $P=A+C+E$, where $P$ is the phenotype, $A$ is the breeding value, $C$ is the common environment of full sibs (optional) and $E$ is the individual environmental component. $P, A, C$ and $E$ are assumed to follow an approximate normal distribution.
SELACTION requires the user to define the breeding goal. The breeding goal is the sum of a maximum of 20 traits weighted by their economic values, $H=\mathbf{a}^{\prime} \mathbf{v}$, where $\mathbf{a}$ is a vector of breeding values and $\mathbf{v}$ is a vector of economic values for all traits in the breeding goal. An index $I$ of information sources is used to predict genetic merit of individuals for the breeding

goal, $I=\mathbf{b}^{\prime} \mathbf{x}$, where $\mathbf{b}$ is a vector of selection index weights and $\mathbf{x}$ is a vector of information sources. Traits in the index and in the breeding goal are allowed to be different traits. SELACTION predicts response to selection for all traits in the index and breeding goal. Index weights are determined as $\mathbf{b}=\mathbf{P}^{-1} \mathbf{G v}$, where is the (co)variance matrix of the information sources, $\mathbf{P}=\operatorname{Var}(\mathbf{x})$ and $\mathbf{G}$ is the covariance matrix of information sources and breeding goal traits, $\mathbf{G}=\operatorname{Cov}(\mathbf{x}, \mathbf{a})$. Genetic selection differentials for each trait and for the breeding goal are determined as in Villanueva et al. (1993).
For each trait, the index may contain the following information sources: a) own performance, b) pedigree information, c) average phenotypic performance of full sibs, d) average phenotypic performance of half sibs, e) average phenotypic performance of progeny. All information sources are optional. A maximum of 20 distinct full-sib, half-sib and progeny groups can be used in the program. For example, if the half sibs are divided into two groups and a different trait is recorded on each group, then the program correctly treats those groups as different individuals (see examples in the manual). Pedigree information consists of the estimated breeding values (EBV) of the sire and dam and the mean EBV of the dams of each half-sib group. Including EBVs of parents as information sources in the selection index enables prediction of response to BLUP selection with an animal model (Wray and Hill, 1989; Villanueva et al. 1993).
SELACTION predicts selection response and inbreeding for the (Bulmer) equilibrium situation. With discrete generations, Bulmers (1971) equilibrium genetic parameters are obtained by iterating on the selection index equations as in Villanueva et al. (1993). With overlapping generations, genetic parameters of the selected parents in each age class are determined as in Villanueva et al. (1993). Subsequently, the updated genetic variances (covariances) are calculated as a weighted sum of the values of each age class plus the sum of squares (cross products) of deviations of the mean values of age classes from the overall mean (see e.g. Meuwissen, 1989 or Bijma et al. 2000). Iteration is continued until equilibrium parameters are reached.
SELACTION takes account of the effect of correlations between index values of full and half sibs on the selection intensity. For each sex-age class, the correlation between index values of full and half sibs are calculated from the selection index equations (see e.g. Bijma and Van Arendonk, 1998). Next, selection intensities are adjusted for each sex-age class using the method of Meuwissen (1991). Response to selection is calculated using the adjusted selection intensities.
Prediction of the rate of inbreeding is based on the long-term genetic contribution theory (Wray and Thompson, 1990). The equations that SELACTION uses are a multitrait analogy of the equations given in Bijma and Woolliams (2000, see also Bijma 2000). Compared to prediction of inbreeding for single trait selection, the breeding value $A$ is replaced by the breeding goal $H$ and the single trait EBV is replaced by the index $I$.
With multistage selection, only individuals that are selected in a certain stage are selection candidates for the next stage. Reproduction takes place only after the final stage of selection. (Multistage selection should not be confused with multiple age classes in

overlapping generations, where all, not only the selected, candidates shift from one age class to the next). SELACTION predicts response to selection for 2 and 3 stage selection. With two (three) stage selection the overall selected proportion is $\mathrm{p}_{\text {tot }}=\mathrm{p}_{1} \times \mathrm{p}_{2}\left(\times \mathrm{p}_{3}\right)$. Prediction of response to selection is based on multivariate normal distribution theory. Genetic selection differentials are obtained as the conditional expectation of traits after truncation on the indexes of the different stages (Ducrocq and Colleau, 1986). Conditional expectations of traits after truncation are obtained from the moment generating function of the truncated multi-normal distribution (Tallis, 1961). Contrary to step wise approaches, this approach deals properly with deviations from normality after the first stage of selection.
For overlapping generations, SELACTION has two options to determine the number of selected animals from each age-class; the user can either enter fixed numbers, or the number selected from each age class is determined by truncation selection on index values across age classes (Ducrocq and Quaas, 1988). When truncation selection is chosen, SELACTION has the option to exclude certain age-classes from selection (e.g. classes that are not yet reproductive). Equations used for overlapping generations are a multitrait analogy of the equations given in appendix A of Bijma et al. 2000.

# Input of SELACTION 

SELACTION requires the following input

- Number of traits, names of traits and economic values of traits.
- Phenotypic variance, heritability, common environment, genetic correlations, phenotypic correlations and common environmental correlations for all traits.
- Number of selected sires, number of selected dams, number of selection candidates per dam, selected proportions.
- Available groups of relatives (FS, HS and progeny) that provide information for breeding value estimation among the selection candidates.
- Available information sources for each trait for each sex-age class.


## Output of SELACTION

SELACTION gives the following output

- Bulmer equilibrium genetic parameters for all traits
- Selection response per unit of time for all traits, in trait units and in economic units, selection response due to selection among sires and due to selection among dams.
- Contribution (\%) of each sex and each trait to the total selection response.
- For multi stage selection, selection response after each stage, in trait units, economic units, separate for sires, dams and total.
- Accuracy of selection and index variance for sires and dams in each age class.
- The number of selected sires and dams from each age class.
- The rate of inbreeding in case of discrete generations.

# System requirements 

SELACTION can be installed on a normal PC. A Pentium 500 with 32MB RAM is sufficient. SELACTION is programmed in Borland Delphi, and runs under Microsoft Windows 95/98/NT.

## Acknowledgements

Vincent Ducrocq is acknowledged for providing routines to calculate multivariate normal probabilities. Theo Meuwissen is acknowledged for providing a routine to calculate selection intensities that account for correlations between index values of full and half sibs. John Woolliams is acknowledged for providing routines to calculate rates of inbreeding. Holland Genetics, Nutreco and IPG are acknowledged for testing preliminary versions of SELACTION.

## References

Bijma, P. and J.A. Woolliams. 2000. Prediction of rates of inbreeding in populations selected on Best Linear Unbiased Prediction of breeding value. Genetics 156:361-373.
Bijma, P., J.A.M. van Arendonk and J.A. Woolliams. 2001. Predicting rates of inbreeding for livestock improvement schemes. J. Anim. Sci. 79:840-853.
Bulmer, M.G. 1971. The effect of selection on genetic variability. Am. Nat. 105:201-211.
Ducrocq, V. and J.J. Colleau. 1986. Interest in quantitative genetics of Dutt's and Deak's methods for numerical computation of multivariate normal probability integrals. Genet. Sel. Evol. 18:447-47.
Ducrocq, V. and R.L. Quaas. 1988. Prediction of genetic response to truncation selection across generations. J. Dairy Sci. 71:2543-2553.
Meuwissen, T.H.E. 1989. A deterministic model for the optimization of dairy cattle breeding based on BLUP breeding value estimates. Anim. Prod. 49:193-202.
Meuwissen, T.H.E. 1991. Reduction of selection differentials in finite populations with a nested full-half sib family structure. Biometrics 47:195-203.
Tallis, G.M. 1961. The moment generating function of the truncated multi-normal distribution. J. R. Statist. Soc. B. 23:223-229.
Villanueva, B., N.R. Wray and R. Thompson. 1993. Prediction of asymptotic rates of response from selection on multiple traits using univariate and multivariate best linear unbiased predictors. Anim. Prod. 57:1-13.
Woolliams, J.A. and P. Bijma. 2000. Predicting rates of inbreeding in populations undergoing selection. Genetics 154:1851-1864.
Wray, N.R. and W.G. Hill. 1989. Asymptotic rates of response from index selection. Anim Prod. 49:217-227.
Wray, N.R. and R. Thompson. 1990. Prediction of rates of inbreeding in selected populations. Genet. Res. Camb. $55: 41-54$.