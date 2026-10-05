# SelAction Manual

**Developed by Marc J. M. Rutten and Piter Bijma (2001)**  

Animal Breeding and Genetics Group  

Department of Animal Sciences  

Wageningen University  

With financial support from The Netherlands Technology Foundation

*SelAction manual, January 2002*

<!-- Page 1 -->

## Contents

1. Starting SelAction
2. The start window
3. The main window
4. The traits window
5. The population window
6. The groups window
7. The index window
8. The correlations window
9. The calculate command
10. General remarks
11. Examples

---

<!-- Page 3 -->

## 1. Starting SelAction

To start SelAction, you can either: 

1. open Windows Explorer, go the directory where the file "SelAction.exe" is located and double click the file
2. include a link to SelAction in the Windows Start menu and click the link
3. you can create a link to SelAction on your desktop and click the link. 

This manual is a step wise guide through SelAction. When using SelAction for the first
time it is advised to start with a simple breeding scheme, for example a population with discrete
generations, selection in a single step and a limited number of traits. To work with SelAction you
need to have at least a basic understanding of livestock improvement and quantitative genetics.
**Please make sure that the input values you are entering are realistic**.

## 2. The start window

After starting SelAction, the following window appears on your screen:

![insert figure 1]

In this window you can click five different options for the type of breeding scheme that you want to
use, three options for discrete generations and two options for overlapping generations. (A
detailed description of the meaning of the different options is in the general description of
SelAction.) The options are:

**Discrete generations**

- 1-stage selection; Selection takes place in a single step.
- 2-stage selection; Selection takes place in two steps, individuals that are not selected in the first step are not candidates in the second step.
- 3-stage selection; Selection takes place in three steps, individuals that are not selected in a certain step are not candidates in the next step.

**Overlapping generations**

1. Truncation selection; Animals are selected by truncation on an index value across age
classes, all animals with an index value above the truncation point are selected as parents of
the next generation, animals with an index value below the truncation point are not selected.
The program calculates the truncation point so that the number of selected individuals
equals the desired number of parents of each sex.

---

<!-- Page 4 -->

2. Selection on fixed proportions; when choosing this option, the user has to specify (later on)
the selected proportions in each age class, they are not determined by the program.

After clicking one of the five options, the program will proceed to the main window. If after working
with one of the five population structures you want to work with another type of population, please
close the program by clicking the "Exit" button and restart the program. This will only take a
second.

## 3. The main window

The main window of SelAction looks as follows

![insert figure 2]

The menu lists the following options: Open, Save Input, Print, Exit, Traits, Population, Groups,
Index, Correlations, Calculate and Save Output.

- **Open** - This option allows you to open a preexisting SelAction input file.
- **Save Input** - This option allows you to save an SelAction input file
- **Exit** This option allows you to exit SelAction. Do not use the window closing butting in the
right top corner of the window, since this will close the window but parts of the program will
remain active in the background which may cause problems when starting the program
again.
- **Traits** - When clicking this option, you proceed to the window where you can enter traits and
trait information.
- **Population** - When clicking this option, you proceed to the window where you can enter
population parameters such as the number of parents, selected proportions etc.
- **Groups** - When clicking this option, you proceed to the window where you can enter the
characteristics of the groups of animals that provide information for the selection index of
selection candidates.
- **Index** - When clicking this option, you proceed to the window where you can enter the
information sources that are included in the selection index.
- **Correlations** - When clicking this option, you proceed to the window where you can enter
genetic, phenotypic and common environmental correlations between all traits.
- **Calculate** - This is the "run" button, when clicking it the programs starts the calculations and
subsequently shows the results.
- **Save output** - When clicking this option the program saves the results.

---

<!-- Page 5 -->

The options in the main menu have to be worked through in order, from left to right. At this
moment, you can only click the options Open, Exit, and Traits. To proceed, click the option
"Traits", which opens the traits window.

## 4. The traits window.

After clicking the option "Traits" in the main menu, the following window appears (excluding the
example values).

![insert figure 3]

In the Traits box you can enter the number of traits. The default value is a single trait. When you
increase the number of traits, the program adds a row for each trait. You can move through the
fields by using the TAB-key or by using the mouse. After entering the number of traits, the
window contains a row for each trait with the fields Name, Var(p), h2, c2, H and EV. The meaning
of those fields is the following:

- **Name** - name of this trait.
- **Var(p)** - phenotypic variance of this trait.
- **h2** - heritability of this trait, h2 = add. genetic variance/phenotypic variance.
- **c2** - common environmental variance between full sibs for this trait as a proportion of the
phenotypic variance, c2 = comm. environmental variance of FS/phenotypic variance.
- **H** - By clicking this box (use either the mouse or the space bar) you include the trait in the
breeding goal, meaning that improvement of this trait is desired. When you do not click the
trait, then SelAction can use this trait only as an information source to predict breeding values
for other traits. For example, when interest is in increasing lean% in pigs but backfat is the
trait that is recorded on the animals, then you should click the H-box for lean% and not for
backfat.
- **EV** - you can only enter values in this box for traits that are included in the breeding goal. For
those traits, you have to specify the economic value of the trait in this field.

After you have entered the field for all traits, please proceed by clicking  the option "Population" of
the main menu, which will open the population window.

---

<!-- Page 6 -->

## 5. The population window

After clicking the option "Population", the following window appears (excluding the example
values).

![insert figure 3]

The window differs slightly between single stage and multi stage selection and between discrete
and overlapping generations. With overlapping generations there are no fields for selected
proportions, whereas with multi stage selection there are multiple fields for selected proportions.
The meaning of the fields is the following:

- **Number of selected animals** - the number of male and female parents selected in the breeding
program. With multistage selection it is the number of selected animals after the final stage of
selection. With overlapping generations it is the total number of selected parents, summed
over all age classes.
- **Number of offspring per dam** - The number of male and female offspring (selection
candidates) born per dam. (This information is needed to calculate selection intensities
adjusted for correlations of index values of relatives using the method of Meuwissen, see
general description of SelAction)
- **Proportion selected animals (not with overlapping generations)** - The selected proportions
among male and female candidates. Thus the values are the number of selected animals
divided by the number of candidates. With single stage selection, there is only a single
selected proportion for each sex, thus in total there are two values to be entered. With multi
stage selection, selected proportions have to be entered for each stage of selection and in
addition the total selected proportion has to be entered. The default value for the total
selected proportion is \( p_t = p_1 × p_2 (× p_3) \) and is suggested automatically by SelAction.
(Selected proportions are used to calculate the selection intensities for each sex. In principle,
selected proportions could be calculated from the numbers of sires and dams and the
number of offspring born per dam, however, the program allows the user to deviate from
values obtained in that way.)

After values in the population window are entered, please click the option "Groups" on the main
menu to proceed to the groups window.

---

<!-- Page 7 -->

## 6. The groups window

When clicking the groups option in the main menu, the following window appears (excluding the
example values)

![insert figure 4]

In the groups window you can enter which groups of animals (relatives of the selection candidate)
are available to provide information for the selection index (or the breeding value estimation) of
candidates. SelAction distinguishes three types of groups; groups of full sibs, groups of half sibs
and groups of progeny. For example, a group of full sibs is a group of individuals that are full sibs
of the selection candidate. The meaning of the field is:

- **Full-sib groups** - Here you can enter the number of different full sib groups. When doing so,
SelAction creates input fields for the number of individuals within each full sib group. Note
that individuals in different groups are distinct individuals. For example, if selection
candidates in a pig-breeding program have 8 full sibs providing records for growth and in
addition 3 of them have records on feed intake, then there are two groups. The first group
has 5 individuals with records on growth and the second group has 3 individuals with records
on both growth and feed intake. Thus in this case you have to specify two full sib groups with
5 and 3 individuals. (The traits that they provide information on can be entered later in the
index window.)
- **Half-sib groups** - Here you can enter the number of different half sib groups. When doing so,
SelAction creates input fields for the number of individuals within each half sib group and for
the number of dams that produces this half sib group. (The number of dams is required to
take account of the fact that half sibs of the selection candidate may be full sibs of each
other). As with full sibs, individuals in different groups are distinct individuals. Continuing the
example of the pig-breeding program and assuming that each dam is mated to three sires,
then there 16 half sibs in total (3×8 – 8 FS). The 16 half sibs consist of two groups, 10
individuals providing information only on growth and 6 individuals providing information on
both growth and feed intake. Thus in this case you have to specify two half sib groups, the
first with 10 individuals of 1.25 dams and the second with 6 individuals of 0.8 dams. (The
information that they provide can be entered later on in the index window.)

---

<!-- Page 8 -->

- **Progeny groups** - Here you can enter the number of different progeny groups. When doing so,
SelAction creates input fields for the number of individuals within each progeny group and for
the number of dams that produces this progeny group. (The number of dams is required to
take account of the fact that a proportion of the progeny of male selection candidates may be
full sibs of each other). Individuals in different groups are distinct individuals. In a dairy cattle
breeding program, for example, production traits may be recorded on 100 daughters whereas
conformation traits may be recorded on only 60 out of the 100 daughters per bull. In this case
you have to specify two progeny groups, the first with 40 daughters of 40 dams (assuming
there is no twinning) and the second with 60 daughters of 60 dams.

After completing the groups window, please continue to the index window by clicking the option
"index" in the main menu.

## 7. The index window

The index window allows you to enter the information sources that are available for breeding
value estimation on the selection candidates. For each sex and for each trait you have to enter
which information is available. The groups that you've entered in the groups window appear as
clickable options in the index field.

![insert figure 5]

- Start with the field "Indexes". In this field you can click whether males and females have
identical indexes or different indexes. When selection of males and females is based on the
same information, then click the option "use identical indexes for sires and dams". If not, click
the option "use different indexes for sires and dams". In dairy cattle for example bulls are
selected based on pedigree, sib and progeny information whereas cows are selected based
on pedigree, sib and own performance information. Thus in this situation bulls and cows have
different indexes. (Note that with identical indexes for males and females the accuracy will be
the same for males and females.) Proceed to the field "Index".

**The Index field**. The set-up of the Index field depends on the type of population that you have
chosen in the start window. For all types of populations, however, there are the following potential
information sources: OP = own performance of the selection candidate; BLUP = breeding value
estimation using BLUP with an animal model and full pedigree; #FS = the full sibs groups that
were entered in the groups window, #HS of #dams = the half sib groups that were entered in the

---

<!-- Page 9 -->

groups window, #progs of # dams = the progeny groups that were entered in the groups window.
When clicking these information sources, they are included in the breeding value estimation for
the selection candidates. The number of sub fields in the index field depends on the type of
population entered in the start window.

For discrete generations with 1-stage selection the window looks as follows (excluding the
example values).

![insert figure 6]

When sires and dams have different indexes then there are two sub fields in the index field, one
for sires and one for dams. Otherwise there is a single field only. Please click the information
sources for the first trait and subsequently go to the traits field and increase the trait number by
one to go to the next trait, go back to the indexes field, etc, until the index is entered for all traits.
For discrete generations with 3-stage selection the window looks as follows.

![insert figure 7]

For each stage of selection there is a separate sub field where information sources can be
clicked. In addition, there are separate fields for sires and dams when the index differs between

---

<!-- Page 10 -->

the sexes. Thus there are at most six sub fields per trait. With multistage selection, information
can only be added. This means that information sources available in the first stage are also
available in the second and third stage, they cannot be deleted. **Thus a subsequent stage of
selection can have more information sources but not less**. SelAction automatically clicks
information sources in subsequent stages when they are clicked in a preceding stage. Do not
remove those clicks. Please click the information sources for the first trait in all stages and in both
sexes and subsequently go to the traits field, increase the trait number by one, go back to the
indexes field, etc, until the index is entered for all traits.

For overlapping generations with truncation selection the window looks as follows.

![insert figure 8]

The "index of" field lists the age class that is displayed in the other fields. The "number of
animals" field lists the number of selection candidates in this age class for each sex, and the
"sires" and "dams" fields list the information sources that can be clicked for this age class. Please
enter the number of selection candidates in the "number of animals field". (The default value is
zero). Next click the appropriate information sources in the "sires" and "dams" fields, go to the
"index of" field, increase the number of age classes by one and go back to the "number of
animals",  "sires" and "dams" fields, etc, until the index is entered for all age classes. The number
of age classes is equal to the highest age class for which you entered the index information
sources. Note that with truncation selection the selected proportion in each age class is
determined automatically by truncation across age classes, so you do not have to enter selected
proportions. SelAction determines the truncation point such that the number of selected parents is
equal to the desired number of parents. (Make sure that the number of candidates is entered
correctly for each age class, otherwise selected proportions will be incorrect also.)

For overlapping generations with selection on fixed proportions the index window looks as
follows.

---

<!-- Page 11 -->

![insert figure 9]

The fields are the same as with overlapping generations and truncation selection, but in addition
you have to enter the selected proportion for each age class. Make sure that the number of
selected parents, that is the product of selected proportion and number of candidates summed
per sex across age classes, is equal to the number of parents that you entered in the population
window.

In case of multiple traits, proceed by clicking the "Correlations" option in the main menu.
Otherwise  click the "Save Input" option of the main menu and proceed to the "Calculate" option.

## 8. The correlations window

The correlations window allows you to enter phenotypic, genetic and common environmental
correlations between all traits. When clicking the option "Correlations" in the main menu, the
following window appears.

![insert figure 10]

In this window, click the option "Phenotypic" and subsequently the "continue" arrow. The following
window appears where you can enter the phenotypic correlations between all trait.

---

<!-- Page 12 -->

![insert figure 11]

After entering the phenotypic correlations click "Save and Exit" to go back to the main correlations
window and click the option "Genetic". Enter the genetic correlations, click "Save and Exit" and
finally click the option "Common Environmental" and enter the common environmental
correlations. SelAction does not check whether the correlation matrixes are positive definite.
Please check this by yourselves. If the correlation matrixes are not positive definite then errors
may occur on execution. Click the "Save Input" option in the main menu and proceed to the
"Calculate" Command.

## 9. The calculate command

At this stage you (should) have entered all the required information to run the program. Before
clicking the option "calculate" in the main menu, please save your input by clicking the option
"Save Input" in the main menu. In case there is a typo in the input, the calculations may crash. By
saving your input you prevent losing them.

To run the program, click the option "Calculate" in the main menu. For complex breeding
schemes with many traits and many age classes calculation of the results may take some time.
Next the results appear on the screen. The results sheet shows the input and the corresponding
output. Examples of results sheets are given with the examples below. To save the results, click
the option "Save Output" in the main menu.

## 10. General remarks

In case the program crashes, check before starting it again whether something is still running in
the background. Press Ctrl+Alt+Del to see which tasks are running. If SelAction is running, click
the End Task button to close it down. This will avoid problems when restarting SelAction.

## 11. Examples

### Example 1: Mass selection for growth in pigs

This is an example of discrete generations with selection in a single stage. Consider a mass selection
program for growth in pigs. The heritability of growth is 0.35, the phenotypic standard deviation is
50g/day, common environment among full sibs is c2 = 0.1, each generation 20 boars and 200 sows are
selected and each sow produces 8 offspring, 4 of each sex. Selected proportions for boars are pm =
20/(200×4) = 0.025 and pf = 200/(200×4) = 0.25. Below are the results and an explanation of the results.

---

<!-- Page 13 -->

```text
*************************  begin of output  ********************************
RESULTS
  TRAITS USED
      growth
   TRAIT PARAMETERS
             phenotypic variance  heritability  com.env.effect
     growth      2,500.000          0.350          0.100
 1BREEDING GOAL INFORMATION
           1.000 * growth
  POPULATION SIZE
                      number of selected sires :   20.0
                       number of selected dams :  200.0
   number of male selection candidates per dam :    4.0
 number of female selection candidates per dam :    4.0
               total selected proportion sires :  0.025
                total selected proportion dams :  0.250
 2INDEX INFORMATION :
                    Own performance of growth
            ******************   RESULTS   *******************
 3EQUILIBRIUM PARAMETERS
            phenotypic variance  heritability  com.env.effect
     growth      2,326.823          0.302          0.107
 4RESPONSE
                                     sires           dams          total
     growth
               trait units:          16.898          9.220         26.118
            economic units:          16.898          9.220         26.118
        % of totalresponse:          64.698         35.302        100.000
5TOTALRESPONSE
                                     sires           dams          total
            economic units:          16.898          9.220         26.118
        6variance of index:          211.687        211.687
 7variance of breeding goal:         701.825
        8accuracy of index:            0.549          0.549
    9increase of inbreeding:           1.074 % per generation
                      ******  end of output  ******
```

Explanation of the output

1. **Breeding goal** - lists all traits included in the breeding goal and their economic value
2. **Index information** - lists all information sources that are used to calculate the selection index. With mass
selection that is only own performance, both for sires and dams.
3. **Equilibrium parameters** - lists the Bulmer equilibrium genetic parameters that are reached after iteration.

---

<!-- Page 14 -->

4. **Response** - lists the response separately for each trait and each sex, in trait units, in economic units and as
a percentage of the total economic response. (In this example there is only a single trait with an economic
weight of 1.0, so response in trait units, in economic units and total response are the same.)
5. **Total response** - lists the total response in economic units, separately for sires and dams.
6. **Variance of index** - Bulmer equilibrium variance of the index. Separate values are given for sires and dams
because their index may differ.
7. **Variance of breeding goal** - In this case it is equal to the equilibrium additive genetic variance of growth
because there is only a single trait with a weight of 1. The breeding goal is always the same for both sexes,
thus only a single value is printed.
8. **Accuracy of index** - Bulmer equilibrium accuracy of selection. Because the index may differ between sires
and dams, a value is printed for each sex. In this case it is equal to the square root of the equilibrium
heritability because it is a mass selection scheme.
9. **Rate of inbreeding** - The rate of inbreeding per generation that this selection program results in. Thus a
value of 1.074% means that ∆F = 0.01074/generation.

### Example 2: Selection for growth in pigs using BLUP with an animal model

This is an example of discrete generations with selection in a single stage on estimated breeding values
obtained with BLUP and an animal model. The heritability of growth is 0.35, the phenotypic standard
deviation is 50g/day, common environment among full sibs is c2 = 0.1, each generation 20 boars and 200
sows are selected and each sow produces 8 offspring, 4 of each sex. Selected proportions for boars are pm =
20/(200×4) = 0.025 and pf = 200/(200×4) = 0.25. Since litter size is 8, each selection candidate has 7 full
sibs that also have a record on growth. Sire family size is 10 × 8 = 80 individuals, thus there are 80 – 8FS =
72 half sibs produced by 9 dams. Below are the results.

```text
*************************  begin of output  *****************************************
RESULTS
  TRAITS USED
     growth
  TRAIT PARAMETERS
           phenotypic variance  heritability  com.env.effect
     growth      2,500.000          0.350          0.100
 BREEDING GOAL INFORMATION
           1.000 * growth
  POPULATION SIZE
                      number of selected sires :   20.0
                       number of selected dams :  200.0
   number of male selection candidates per dam :    4.0
 number of female selection candidates per dam :    4.0
               total selected proportion sires :  0.025
                total selected proportion dams :  0.250
 CHARACTERISTICS OF THE USED GROUPS
 full-sib group 1 with        7.0 animals
 half-sib group 1 with        9.0 dams, producing       72.0 animals
 1INDEX INFORMATION :
                   Own performance of growth
           Dam BLUP breeding value of growth
          Sire BLUP breeding value of growth
  Observations on full-Sib group 1 on growth
  Observations on half-sib group 1 on growth

Mean EBV of the dams of hs-group 1 on growth
             ******************   RESULTS   *******************
 EQUILIBRIUM PARAMETERS
           phenotypic variance  heritability  com.env.effect
     growth      2,298.360          0.293          0.109
  RESPONSE
                                     sires           dams          total
     growth
               trait units:          18.011          9.874         27.885
            economic units:          18.011          9.874         27.885
        % of totalresponse:          64.590         35.410        100.000
  TOTALRESPONSE
                                     sires           dams          total
            economic units:          18.011          9.874         27.885
         variance of index:         246.479        246.479
 variance of breeding goal:         673.361
         accuracy of index:           0.605          0.605
    increase of inbreeding:           2.124 % per generation
                      ******  end of output  ******
```

Explanation of the output

Most elements of the output are the same as in example 1 and are therefore not explained.

1. **Index information** - Lists the information sources included in the index. Breeding value estimation using
BLUP is accounted for by including the dam BLUP breeding value, the sire BLUP breeding value and the
mean EBV of the dams of the half sibs (see general description of SelAction).
Notice the increased response to selection but also the increased rate of inbreeding compared to the mass
selection scheme (Example 1). The increase in selection response compared to mass selection may seem
surprisingly small, i.e. the extra information available with BLUP has only limited benefits. The reasons are
the following. First, BLUP yields a higher accuracy, but differences in response are not proportional to
differences in accuracy because higher accuracy results in lower equilibrium values of the breeding goal
variance (Bulmer effect). Second, with selection on BLUP EBV the correlation between EBV of full and
half sibs is higher than with mass selection. The selection intensity with BLUP is therefore a little bit lower
than that with mass selection. (Note that BLUP is important with respect to the estimation of fixed effects,
which is problematic with mass selection. Thus BLUP is to be preferred but restriction of the rate of
inbreeding deserves attention).

### Example 3: Single trait selection for milk yield in dairy cattle

This is an example for overlapping generations with truncation selection. Annual milk yield has a
heritability of 0.3 and a phenotypic standard deviation of 1000kg. The population consists of overlapping
generations with a maximum age for both cows and bulls of eight years. The age class interval is one year,
thus there are 8 age classes. Cows and bulls are at  least two-years-old when their first offspring are born,
thus parents cannot be selected from age class one because those individuals are not yet reproductive.
Annually there is 10% culling among selection candidates for reasons of health and survival. Each year, 10
sires and 200 cows are selected as parents of the newborn year class. Fertility of the selected dams is 80%,
thus a single selected cow is expected to produce 0.4 male and 0.4 female offspring on average. When bulls
are five years of age, information on milk yield of 100 progeny becomes available.

```text
*****************************output file*********************

RESULTS
  TRAITS USED
      milk yield
  TRAIT PARAMETERS
        phenotypic variance  heritability
     milk yield  1,000,000.000          0.300
 BREEDING GOAL INFORMATION
           1.000 * milk yield
   POPULATION SIZE
                       number of selected sires :  10.0
                       number of selected dams :  200.0
   number of male selection candidates per dam :    0.4
 number of female selection candidates per dam :    0.4
    selected proportion sires in age class 1 :  0.067 x  0.000 =  0.000
    selected proportion sires in age class 2 :  0.008 x 72.000 =  0.550
    selected proportion sires in age class 3 :  0.001 x 64.800 =  0.038
    selected proportion sires in age class 4 :  0.000 x 58.320 =  0.001
    selected proportion sires in age class 5 :  0.088 x 52.490 =  4.634
    selected proportion sires in age class 6 :  0.056 x 47.240 =  2.629
    selected proportion sires in age class 7 :  0.033 x 42.520 =  1.420
    selected proportion sires in age class 8 :  0.019 x 38.260 =  0.728
     selected proportion dams in age class 9 : 1.000 x  0.000 =  0.000
     selected proportion dams in age class 10 : 0.992 x 72.000 = 71.427
     selected proportion dams in age class 11 : 0.752 x 64.800 = 48.754
     selected proportion dams in age class 12 : 0.600 x 58.320 = 35.014
     selected proportion dams in age class 13 : 0.431 x 52.490 = 22.632
     selected proportion dams in age class 14 : 0.274 x 47.240 = 12.939
     selected proportion dams in age class 15 : 0.152 x 42.520 =  6.454
     selected proportion dams in age class 16 : 0.073 x 38.260 =  2.779
 generation interval :  4.515 cohort intervals
 CHARACTERISTICS OF THE USED GROUPS
 half-sib group 1 with        7.0 dams, producing        7.0 animals
 half-sib group 2 with        8.0 dams, producing        8.0 animals
 progeny group information
 progeny group 1 with      100.0 dams, producing      100.0 progeny
 INDEX INFORMATION :
 sire class : 1
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
 sire class : 2
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
 sire class : 3
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 2 on milk yield
Mean EBV of the dams of hs-group 2 on milk yield
 sire class : 4
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 2 on milk yield
Mean EBV of the dams of hs-group 2 on milk yield
 sire class : 5
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 2 on milk yield
Mean EBV of the dams of hs-group 2 on milk yield
   Observations on progeny group 1 on milk yield
 sire class : 6
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 2 on milk yield
Mean EBV of the dams of hs-group 2 on milk yield
   Observations on progeny group 1 on milk yield
 sire class : 7
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 2 on milk yield
Mean EBV of the dams of hs-group 2 on milk yield
   Observations on progeny group 1 on milk yield
 sire class : 8
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 2 on milk yield
Mean EBV of the dams of hs-group 2 on milk yield
   Observations on progeny group 1 on milk yield
  dam class : 1 (= age class 9)
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  dam class : 2 (= age class 10)
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  dam class : 3 (= age class 11)
                   Own performance of milk yield
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 1 on milk yield
Mean EBV of the dams of hs-group 1 on milk yield
  dam class : 4 (= age class 12)
                   Own performance of milk yield
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 1 on milk yield
Mean EBV of the dams of hs-group 1 on milk yield
  dam class : 5 (= age class 13)
                   Own performance of milk yield
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 1 on milk yield
Mean EBV of the dams of hs-group 1 on milk yield
  dam class : 6 (= age class 14)
                   Own performance of milk yield
           Dam BLUP breeding value of milk yield

Sire BLUP breeding value of milk yield
  Observations on half-sib group 1 on milk yield
Mean EBV of the dams of hs-group 1 on milk yield
  dam class : 7 (= age class 15)
                   Own performance of milk yield
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 1 on milk yield
Mean EBV of the dams of hs-group 1 on milk yield
  dam class : 8 (= age class 16)
                   Own performance of milk yield
           Dam BLUP breeding value of milk yield
          Sire BLUP breeding value of milk yield
  Observations on half-sib group 1 on milk yield
Mean EBV of the dams of hs-group 1 on milk yield

             ******************   RESULTS   *******************

 EQUILIBRIUM PARAMETERS
       phenotypic variance  heritability
     milk yield    916,151.131          0.236
  RESPONSE
                                     sires           dams          total
     milk yield
               trait units:          90.922         12.810        103.732
            economic units:          90.922         12.810        103.732
        % of totalresponse:          87.651         12.349        100.000
  TOTALRESPONSE
                                     sires           dams          total
            economic units:          90.922         12.810        103.732
 sire class 1 variance of index:      12,460.481
              accuracy of index:           0.240
 sire class 2 variance of index:      12,460.481
              accuracy of index:           0.240
 sire class 3 variance of index:      13,317.017
              accuracy of index:           0.248
 sire class 4 variance of index:      13,317.017
              accuracy of index:           0.248
 sire class 5 variance of index:     185,459.586
              accuracy of index:           0.926
 sire class 6 variance of index:     185,459.586
              accuracy of index:           0.926
 sire class 7 variance of index:     185,459.586
              accuracy of index:           0.926
 sire class 8 variance of index:     185,459.586
              accuracy of index:           0.926

dam class 1 variance of index:      12,460.481
              accuracy of index:           0.240
  dam class 2 variance of index:      12,460.481
              accuracy of index:           0.240
  dam class 3 variance of index:      58,826.215
              accuracy of index:           0.522
  dam class 4 variance of index:      58,826.215
              accuracy of index:           0.522
  dam class 5 variance of index:      58,826.215
              accuracy of index:           0.522
  dam class 6 variance of index:      58,826.215
              accuracy of index:           0.522
  dam class 7 variance of index:      58,826.215
              accuracy of index:           0.522
  dam class 8 variance of index:      58,826.215
              accuracy of index:           0.522
 variance of breeding goal:     216,149.591
                       ******  end of output  ******
```

### Example 4: combined crossbred purebred selection in pigs

The previous examples have considered simple breeding schemes, considerably simpler than practical
breeding schemes. However, the power of SelAction is that it can deal with complex breeding schemes that
occur in practice. This example considers a more complicated breeding scheme in pigs where information
on crossbred relatives is used to increase selection response in the purebred lines.
Consider a pig-breeding program that aims to improve three traits, daily gain (DG, g/day), carcass lean
content (LC, %) and feed intake (FI, g/day). It is a 3-way breeding program with a single sire line and two
dam lines. This example concerns genetic improvement of the sire line. Because the crossbreds are the final
products, the breeding goal is defined at the crossbred level, meaning that crossbred traits have an
economic value whereas purebred traits do not.

The purebred line consists of 40 boars and 200 sows per generation. Each sow produces 8 offspring, 4
males and 4 females. Traits recorded in the purebred line are DG, FI and back fat thickness (BF, mm)
which is used as an indicator trait for carcass lean content. Carcass lean content itself is not recorded in the
purebred lines. All 8 offspring of each of the 200 litters have records on DG and BF. FI is recorded only on
2 males out of each litter. Only males that have a record on feed intake are selection candidates, thus there
are 200 × 2 = 400 male selection candidates, so that pm = 0.1. All female offspring per litter are selection
candidates, thus there are 800 female selection candidates, so that pf = 0.25.

Carcass lean content is measured on the crossbred fattening pigs in the slaughterhouses. It is assumed that
the sires of the purebred selection candidates are also used as sires of crossbred fattening pigs. Purebred
selection candidates therefore have crossbred half sibs with a record on carcass lean content. It is assumed
that each purebred sire has 64 crossbred fattening pigs with a record for LC which are born out of 8 sows.
Thus each purebred selection candidate has information on LC of 64 crossbred half sibs out of 8 dams.
The correlation between the same trait in a purebred and in a crossbred may deviate from 1 due to
dominance and genotype by environment interaction. This correlation is commonly called the "purebred-
crossbred correlation", rpc. Here it is assumed that rpc = 0.8. Thus purebred and crossbred performance are
different traits. Hence, we have to make a distinction between DG in purebreds and crossbreds, giving two
traits, DGPB and DGCB; the same holds for the other traits. In total there are six traits; DGPB, BFPB,
FIPB, DGCB, LCCB and FICB. It is not needed to include LCPB and BFCB because those traits are not
recorded and have no economic importance.

---

<!-- Page 20 -->

The traits
Genetic parameters and economic values for the traits are taken from the Ph.D.-theses of Alfred de Vries
and Jacco Eissen.
     trait
 phen. var.          h2                 c2
EV
     DGPB
2,500.000          0.350          0.100
-
     BFPB
       4.000          0.500          0.100
-
     FIPB                  52,900.000          0.350          0.100
-
     DGCB
2,500.000          0.350          0.100
0.08 €/g/day
     LCCB
     25.000          0.350          0.100
1.34 €/%
     FICB                  52,900.000          0.350          0.100
–0.006 €/g/day
The population
40 males
200 females
2 male offsp.
4 female offsp.
pm = 0.1
pf = 0.25
The groups
Within each litter, all 8 individuals have records for DG and BF and 2 males have records for FI. Thus for
males there are two full sib groups:
FS-group 1 with 1 individuals with records on DGPB, BFPB and FIPB.
FS-group 2 with 6 individuals with records on DGPB and BFPB.
Note that individuals in different groups are different individuals, so that in total there are 7 full sibs.
For females there are also two full sib groups:
FS-group 3 with 2 individuals with records on DGPB, BFPB and FIPB.
FS-group 4 with 5 individuals with records on DGPB and BFPB.
Each sire is mated to 5 dams and each dam produces 8 offspring. Thus in total there are (5–1) × 8 = 32
purebred half sibs, and within each litter 2 out of the 8 individuals have a record for feed intake. In addition
there are 64 crossbred half sibs. Thus there are three half sib groups, they are the same for sires and dams.
HS-group 1 with 8 individuals out of 4 dams with records on DGPB, BFPB and FIPB.
HS-group 2 with 24 individuals out of 4 dams with records on DGPB and BFPB.
HS-group 3 with 64 individuals out of 8 dams with records on LCCB.
The index
There is BLUP breeding value estimation for all traits, thus the box BLUP should be clicked for all traits.
For males, own performance information is available on DGPB, BFPB and FIPB. For females, own
performance information is available on DGPB and BFPB. For the full and half sibs groups, for a particular
trait the box for a group should be clicked if that group provides information for the trait (see groups above,
the results file printed below shows which index information sources were included for which traits).
The correlations
Phenotypic
             DGPB     BFPB     FIPB     DGCB     LCCB    FICB
     DGPB   1.000
     BFPB   0.150    1.000
     FIPB   0.700    0.500    1.000
     DGCB   0.280    0.050    0.200     1.000
     LCCB - 0.030   -0.270   -0.080    -0.100    1.000
     FICB   0.200    0.170    0.280     0.700   -0.300   1.000
Genetic
              DGPB    BFPB       FIPB     DGCB     LCCB    FICB
     DGPB    1.000
     BFPB    0.150    1.000
     FIPB    0.700    0.500     1.000
     DGCB    0.800    0.120     0.560    1.000

---

<!-- Page 21 -->

LCCB   -0.080   -0.640    -0.240   -0.100     1.000
     FICB    0.560    0.400     0.800    0.700    -0.300   1.000
Common environmental
All common environmental correlations were assumed to be zero.
*************************  begin of output  *****************************************
RESULTS
  TRAITS USED
     DGPB
     BFPB
     FIPB
     DGCB
     LCCB
     FICB
  TRAIT PARAMETERS
              phenotypic variance  heritability  com.env.effect
     DGPB      2,500.000          0.350          0.100
     BFPB          4.000          0.500          0.100
     FIPB     52,900.000          0.350          0.100
     DGCB      2,500.000          0.350          0.100
     LCCB         25.000          0.350          0.100
     FICB     52,900.000          0.350          0.100
  PHENOTYPIC CORRELATIONS
             DGPB    BFPB     FIPB      DGCB     LCCB    FICB
     DGPB   1.000
     BFPB   0.150    1.000
     FIPB   0.700    0.500    1.000
     DGCB   0.280    0.050    0.200     1.000
     LCCB  -0.030   -0.270   -0.080    -0.100    1.000
     FICB   0.200    0.170    0.280     0.700   -0.300   1.000
  GENETIC CORRELATIONS
              DGPB     BFPB     FIPB    DGCB      LCCB    FICB
     DGPB    1.000
     BFPB    0.150    1.000
     FIPB    0.700    0.500    1.000
     DGCB    0.800    0.120    0.560    1.000
     LCCB   -0.080   -0.640   -0.240   -0.100     1.000
     FICB    0.560    0.400    0.800    0.700    -0.300   1.000
  COMMON ENVIRONMENTAL CORRELATIONS
            DGPB     BFPB    FIPB    DGCB    LCCB   FICB
  DGPB
1.000
  BFPB
0.000   1.000
  FIPB
0.000   0.000   1.000
  DGCB
0.000   0.000   0.000   1.000
  LCCB
0.000   0.000   0.000   0.000   1.000
  FICB
0.000   0.000   0.000   0.000   0.000   1.000
 BREEDING GOAL INFORMATION
          0.080 * DGCB
          1.340 * LCCB
         -0.006 * FICB
  POPULATION SIZE
 number of selected sires :
 40.0
 number of selected dams :
200.0
 number of male selection candidates per dam :
2.0

---

<!-- Page 22 -->

number of female selection candidates per dam :
4.0
               total selected proportion sires :
0.100
               total selected proportion dams :
0.250
 CHARACTERISTICS OF THE USED GROUPS
 full-sib group 1 with        1.0 animals
 full-sib group 2 with        6.0 animals
 full-sib group 3 with        2.0 animals
 full-sib group 4 with        5.0 animals
 half-sib group 1 with        4.0 dams, producing        8.0 animals
 half-sib group 2 with        4.0 dams, producing       24.0 animals
 half-sib group 3 with        8.0 dams, producing       64.0 animals
 INDEX INFORMATION FOR SIRES :
Own performance of DGPB
Dam BLUP breeding value of DGPB
Sire BLUP breeding value of DGPB
Observations on full-Sib group 1 on DGPB

Observations on full-Sib group 2 on DGPB

Observations on half-sib group 1 on DGPB

Observations on half-sib group 2 on DGPB
Mean EBV of the dams of hs-group 1 on DGPB
Mean EBV of the dams of hs-group 2 on DGPB
             Own performance of BFPB

Dam BLUP breeding value of BFPB

Sire BLUP breeding value of BFPB

Observations on full-Sib group 1 on BFPB

Observations on full-Sib group 2 on BFPB

Observations on half-sib group 1 on BFPB

Observations on half-sib group 2 on BFPB
Mean EBV of the dams of hs-group 1 on BFPB
Mean EBV of the dams of hs-group 2 on BFPB

Own performance of FIPB

Dam BLUP breeding value of FIPB

Sire BLUP breeding value of FIPB

Observations on full-Sib group 1 on FIPB

Observations on half-sib group 1 on FIPB
Mean EBV of the dams of hs-group 1 on FIPB

Dam BLUP breeding value of DGCB

Sire BLUP breeding value of DGCB

Dam BLUP breeding value of LCCB

Sire BLUP breeding value of LCCB

Observations on half-sib group 3 on LCCB
Mean EBV of the dams of hs-group 3 on LCCB

Dam BLUP breeding value of FICB

Sire BLUP breeding value of FICB
  INDEX INFORMATION FOR DAMS :
Own performance of DGPB
Dam BLUP breeding value of DGPB
Sire BLUP breeding value of DGPB
Observations on full-Sib group 3 on DGPB

Observations on full-Sib group 4 on DGPB

Observations on half-sib group 1 on DGPB

Observations on half-sib group 2 on DGPB
Mean EBV of the dams of hs-group 1 on DGPB
Mean EBV of the dams of hs-group 2 on DGPB

---

<!-- Page 23 -->

Own performance of BFPB

Dam BLUP breeding value of BFPB

Sire BLUP breeding value of BFPB

Observations on full-Sib group 3 on BFPB

Observations on full-Sib group 4 on BFPB

Observations on half-sib group 1 on BFPB

Observations on half-sib group 2 on BFPB
Mean EBV of the dams of hs-group 1 on BFPB
Mean EBV of the dams of hs-group 2 on BFPB
Dam BLUP breeding value of FIPB

Sire BLUP breeding value of FIPB

Observations on full-Sib group 3 on FIPB

Observations on half-sib group 1 on FIPB
Mean EBV of the dams of hs-group 1 on FIPB
Dam BLUP breeding value of DGCB

Sire BLUP breeding value of DGCB

Dam BLUP breeding value of LCCB

Sire BLUP breeding value of LCCB

Observations on half-sib group 3 on LCCB
Mean EBV of the dams of hs-group 3 on LCCB

Dam BLUP breeding value of FICB

Sire BLUP breeding value of FICB
             ******************   RESULTS   *******************
EQUILIBRIUM PARAMETERS
       phenotypic variance  heritability  com.env.effect
     DGPB      2,485.566          0.346          0.101
     BFPB          3.679          0.456          0.109
     FIPB     52,825.614          0.349          0.100
     DGCB      2,491.939          0.348          0.100
     LCCB         23.701          0.314          0.105
     FICB     52,801.438          0.349          0.100
  PHENOTYPIC CORRELATIONS
           DGPB     BFPB     FIPB     DGCB     LCCB    FICB
  DGPB    1.000
  BFPB    0.179    1.000
  FIPB    0.705    0.511    1.000
  DGCB    0.277    0.069    0.203    1.000
  LCCB   -0.049   -0.220   -0.074   -0.116    1.000
  FICB    0.204    0.165    0.279    0.704   -0.298    1.000
  GENETIC CORRELATIONS
           DGPB     BFPB     FIPB     DGCB     LCCB    FICB
  DGPB    1.000
  BFPB    0.222    1.000
  FIPB    0.715    0.520    1.000
  DGCB    0.798    0.174    0.570    1.000
  LCCB   -0.141   -0.574   -0.235   -0.149    1.000
  FICB    0.576    0.406    0.799    0.712   -0.296    1.000
  COMMON ENVIRONMENTAL CORRELATIONS
          DGPB      BFPB     FIPB     DGCB     LCCB    FICB
  DGPB    1.000
  BFPB    0.000    1.000
  FIPB    0.000    0.000    1.000
  DGCB    0.000    0.000    0.000    1.000
  LCCB    0.000    0.000    0.000    0.000    1.000

---

<!-- Page 24 -->

FICB    0.000    0.000    0.000    0.000    0.000    1.000
  RESPONSE
                                     sires           dams          total
     DGCB
               trait units:           2.686          2.039          4.725
            economic units:           0.215          0.163          0.378
        % of totalresponse:           7.041          5.344         12.385
     LCCB
               trait units:           1.127          0.796          1.923
            economic units:           1.510          1.067          2.576
        % of totalresponse:          49.460         34.942         84.403
     FICB
               trait units:          -8.286         -8.057        -16.343
            economic units:           0.050          0.048          0.098
        % of totalresponse:           1.629          1.584          3.213
  CORRELATED RESPONSE
                                     sires           dams          total
     DGPB
               trait units:           3.632          2.749          6.381
     BFPB
               trait units:          -0.558         -0.397         -0.955
     FIPB
               trait units:          -6.574         -7.299        -13.873
  TOTALRESPONSE
                                     sires           dams          total
            economic units:           1.774          1.278          3.052
         variance of index:           4.165          4.098
 variance of breeding goal:          16.048
         accuracy of index:           0.509          0.505
    increase of inbreeding:           1.017 % per generation
                      ******  end of output  ******

### Example 5: Two stage selection for growth and feed intake in pigs

This example considers a two stage breeding program for growth and feed intake in pigs. Because
recording of feed intake is expensive, it is only recorded on males and after preselection on growth.
Preselection takes place half way through the growth period and is based on growth in the first part of the
growth period and full pedigree information. The final stage of selection takes place at the end of the
growth period and is based on full pedigree, growth over the full growth period and feed intake for males.
Growth during the first part of the growth period is considered to be a different trait than growth over the
full period, a genetic and phenotypic correlation of 0.7 is assumed.
Thus there are three traits:
•
DG1, daily gain during the first part of the growth period (g/day)
•
DG, daily gain over the full growth period (g/day)
•
FI, feed intake (g/day)
Genetic parameters are given in the results below. Note that DG1 has no economic importance in itself, it is
an index trait providing information on DG.
The breeding program has 40 boars and 200 sows with litter size of 8, 4 males and 4 females. Information
sources available at the preselection are:
•
full pedigree for all traits (meaning, EBVs of the previous generation for all traits).

---

<!-- Page 25 -->

•
own performance for DG1
•
7 full sibs with records on DG1
•
32 half sibs out of 4 dams with records on DG1
Selected proportions in the preselection are p1,m = 0.25 and p1,f = 0.5.
The preselection halves the number of selection candidates, thus in the final stage of selection there are
fewer. When halving the family size there would be 3.5 FS which we round down to 3 FS with records on
DG. Only males have records for FI, thus females have 1.5 FS with records on FI and males have 0.5 ≈ 0
FS with records on FI. In addition there are 16HS, 8 with records on both FI and DG and 8 with records
only on DG. Thus additional (compared to preselection) information sources in the final stage are, for
males:
•
own performance for DG and FI
•
3 FS with records on DG
•
8 HS with records on DG
•
8 HS with records on DG and FI
and for females
•
own performance for DG
•
1.5 FS with records on DG
•
1.5 FS with records on DG and FI
•
8 HS with records on DG
•
8 HS with records on DG and FI
Selected proportions in the final stage are p2,m = 0.2 and pf,2 = 0.5 so that overall selected proportions are pm
= 0.25 × 0.2 = 0.05 = 40/(200×4) and pf = 0.5 × 0.5 = 0.25 = 200/(200×4).
The results of SelAction is given below. Notice that the first stage selection results in an (undesired)
increase of FI because there is only information on DG1 available in the first stage. In the final stage, males
have information on FI and the increase of FI due to the first stage is reduced in the final stage selection of
boars.
*************************  begin of output  *****************************************
RESULTS
  TRAITS USED
     DG1
     DG
     FI
  TRAIT PARAMETERS
         phenotypic variance  heritability  com.env.effect
     DG1       625.000          0.350          0.100
     DG      2,500.000          0.350          0.100
     FI     52,900.000          0.350          0.100
  PHENOTYPIC CORRELATIONS
             DG1      DG      FI
     DG1   1.000
     DG    0.700    1.000
     FI    0.500    0.700    1.000
  GENETIC CORRELATIONS
            DG1       DG      FI
     DG1   1.000
     DG    0.700    1.000
     FI    0.500    0.700    1.000
  COMMON ENVIRONMENTAL CORRELATIONS
         DG1       DG      FI
  DG1   1.000
  DG    0.000    1.000

---

<!-- Page 26 -->

FI    0.000    0.000    1.000
 BREEDING GOAL INFORMATION
          0.080 * DG
         -0.012 * FI
  POPULATION SIZE
                      number of selected sires :   40.0
                       number of selected dams :  200.0
   number of male selection candidates per dam :    4.0
 number of female selection candidates per dam :    4.0
          selected proportion sires in stage 1 :  0.250
          selected proportion sires in stage 2 :  0.200
           selected proportion dams in stage 1 :  0.500
           selected proportion dams in stage 2 :  0.500
               total selected proportion sires :  0.050
                total selected proportion dams :  0.250
 CHARACTERISTICS OF THE USED GROUPS
 full-sib group 1 with        7.0 animals
 full-sib group 2 with        1.5 animals
 full-sib group 3 with        1.5 animals
 full-sib group 4 with        3.0 animals
 half-sib group 1 with        4.0 dams, producing       32.0 animals
 half-sib group 2 with        4.0 dams, producing        8.0 animals
 half-sib group 3 with        4.0 dams, producing        8.0 animals
 STAGE 1 INDEX INFORMATION FOR SIRES :
                   Own performance of DG1
           Dam BLUP breeding value of DG1
          Sire BLUP breeding value of DG1
  Observations on full-Sib group 1 on DG1
  Observations on half-sib group 1 on DG1
Mean EBV of the dams of hs-group 1 on DG1
            Dam BLUP breeding value of DG
           Sire BLUP breeding value of DG
            Dam BLUP breeding value of FI
           Sire BLUP breeding value of FI
  STAGE 1 INDEX INFORMATION FOR DAMS :
                   Own performance of DG1
           Dam BLUP breeding value on DG1
          Sire BLUP breeding value on DG1
  Observations on full-Sib group 1 on DG1
  Observations on half-sib group 1 on DG1
Mean EBV of the dams of hs-group 1 on DG1
            Dam BLUP breeding value on DG
           Sire BLUP breeding value on DG
            Dam BLUP breeding value on FI
           Sire BLUP breeding value on FI
 STAGE 2 INDEX INFORMATION FOR SIRES :
                   Own performance of DG1
           Dam BLUP breeding value of DG1

---

<!-- Page 27 -->

Sire BLUP breeding value of DG1
  Observations on full-Sib group 1 on DG1
  Observations on half-sib group 1 on DG1
Mean EBV of the dams of hs-group 1 on DG1
                   Own performance of DG
           Dam BLUP breeding value of DG
          Sire BLUP breeding value of DG
  Observations on full-Sib group 4 on DG
  Observations on half-sib group 2 on DG
  Observations on half-sib group 3 on DG
Mean EBV of the dams of hs-group 2 on DG
Mean EBV of the dams of hs-group 3 on DG
                   Own performance of FI
           Dam BLUP breeding value of FI
          Sire BLUP breeding value of FI
  Observations on half-sib group 2 on FI
Mean EBV of the dams of hs-group 2 on FI
  STAGE 2 INDEX INFORMATION FOR DAMS :
                   Own performance of DG1
           Dam BLUP breeding value on DG1
          Sire BLUP breeding value on DG1
  Observations on full-Sib group 1 on DG1
  Observations on half-sib group 1 on DG1
Mean EBV of the dams of hs-group 1 on DG1
                    Own performance of DG
            Dam BLUP breeding value on DG
           Sire BLUP breeding value on DG
   Observations on full-Sib group 2 on DG
   Observations on full-Sib group 3 on DG
   Observations on half-sib group 2 on DG
   Observations on half-sib group 3 on DG
 Mean EBV of the dams of hs-group 2 on DG
 Mean EBV of the dams of hs-group 3 on DG
            Dam BLUP breeding value on FI
           Sire BLUP breeding value on FI
   Observations on full-Sib group 2 on FI
   Observations on half-sib group 2 on FI
 Mean EBV of the dams of hs-group 2 on FI
             ******************   RESULTS   *******************
EQUILIBRIUM PARAMETERS
        phenotypic variance  heritability  com.env.effect
     DG1        608.967          0.333          0.103
     DG       2,373.194          0.315          0.105
     FI      52,529.100          0.345          0.101
  PHENOTYPIC CORRELATIONS
         DG1       DG       FI
  DG1   1.000
  DG    0.690    1.000
  FI    0.498    0.706    1.000
  GENETIC CORRELATIONS
          DG1      DG       FI
  DG1   1.000
  DG    0.671    1.000
  FI    0.493    0.720    1.000
  COMMON ENVIRONMENTAL CORRELATIONS
          DG1      DG       FI

---

<!-- Page 28 -->

DG1   1.000
  DG    0.000    1.000
  FI    0.000    0.000    1.000
  RESPONSE AFTER STAGE 1
                                     sires           dams          total
     DG
               trait units:           6.759          4.244         11.003
            economic units:           0.541          0.340          0.880
        % of totalresponse:         109.418         68.704        178.122
     FI
               trait units:          19.762         12.409         32.171
            economic units:          -0.237         -0.149         -0.386
        % of totalresponse:         -47.989        -30.133        -78.122
  CORRELATED RESPONSE AFTER STAGE 1
                                     sires           dams          total
     DG1
               trait units:           4.437          2.786          7.223
  TOTALRESPONSE AFTER STAGE 1
                                     sires           dams          total
            economic units:           0.304          0.191          0.494
         variance of index:           0.231          0.231
 variance of breeding goal:           2.309
         accuracy of index:           0.316          0.316
  RESPONSE AFTER STAGE 2
                                     sires           dams          total
     DG
               trait units:          12.339          8.599         20.938
            economic units:           0.987          0.688          1.675
        % of totalresponse:          76.222         53.121        129.343
     FI
               trait units:          10.347         21.320         31.667
            economic units:          -0.124         -0.256         -0.380
        % of totalresponse:          -9.588        -19.756        -29.343
  CORRELATED RESPONSE AFTER STAGE 2
                                     sires           dams          total
     DG1
               trait units:           5.375          3.724          9.099
  TOTALRESPONSE AFTER STAGE 2
                                     sires           dams          total
            economic units:           0.863          0.432          1.295
         variance of index:           0.817          0.519
 variance of breeding goal:           2.309
         accuracy of index:           0.595          0.474
                      ******  end of output  ******

---

<!-- Page 29 -->

### Example 6: Maintaining the fertility level in dairy cattle

Though it is often difficult to derive exact economic values for traits, it may be possible to define desired
changes or levels of traits. In dairy cattle for example, it may be difficult to derive an exact economic value
for fertility. However, it may be considered desirable to maintain the present level of fertility, i.e. to avoid a
continued reduction of fertility due to selection for production traits. SelAction can accommodate such
situations. The program is sufficiently quick to allow the user to iterate on the economic weights until the
desired gain is achieved. Below are the results of a dairy cattle-breeding program that achieves zero change
in calving interval while improving protein yield. The economic weight of calving interval is determined so
that genetic gain for it is zero.

Without a negative weight on calving interval, calving interval increased annually by an amount of 0.6
days. In that case, selection response in protein yield was +3.790 kg/yr (results not shown). To avoid an
increase of calving interval, a negative economic weight was given to calving interval, and its value was
increased until calving interval did not increase any longer. This required an economic value of – 1.67/day
(note that the weight on protein yield was arbitrarily set to 1). With no selection response in calving
interval, genetic gain in protein yield was 3.239, which is 14% less than without a restriction on calving
interval. Thus the cost of avoiding a decrease in calving interval was a 14% reduction of genetic gain in
protein yield.

*************************************start of output***********************************************
RESULTS
  TRAITS USED
      milk
      c_interval
  TRAIT PARAMETERS
        phenotypic variance  heritability
     milk
1,225.000          0.300
     c_interval    441.000
0.100
  PHENOTYPIC CORRELATIONS
                 milk     c_interval
     milk          1.000
     c_interval    0.500    1.000
  GENETIC CORRELATIONS
                 milk     c_interval
     milk          1.000
     c_interval    0.500    1.000
 BREEDING GOAL INFORMATION
           1.000 * milk
          -1.670 * c_interval
  POPULATION SIZE
                      number of selected sires :   10.0
                       number of selected dams :  200.0
   number of male selection candidates per dam :    0.4
 number of female selection candidates per dam :    0.4
    selected proportion sires in age class 1 :  0.063 x  0.000 =  0.000
    selected proportion sires in age class 2 :  0.006 x 80.000 =  0.447
    selected proportion sires in age class 3 :  0.000 x 72.000 =  0.023
    selected proportion sires in age class 4 :  0.000 x 65.000 =  0.000
    selected proportion sires in age class 5 :  0.083 x 58.000 =  4.805
    selected proportion sires in age class 6 :  0.051 x 52.000 =  2.641
    selected proportion sires in age class 7 :  0.030 x 47.000 =  1.387

---

<!-- Page 30 -->

selected proportion sires in age class 8 :  0.016 x 43.000 =  0.697
     selected proportion dams in age class 9  : 0.999 x  0.000 =  0.000
     selected proportion dams in age class 10 : 0.984 x 80.000 = 78.740
     selected proportion dams in age class 11 : 0.697 x 72.000 = 50.161
     selected proportion dams in age class 12 : 0.525 x 65.000 = 34.129
     selected proportion dams in age class 13 : 0.349 x 58.000 = 20.218
     selected proportion dams in age class 14 : 0.200 x 52.000 = 10.407
     selected proportion dams in age class 15 : 0.098 x 47.000 =  4.605
     selected proportion dams in age class 16 : 0.040 x 43.000 =  1.741
 generation interval :  4.441 cohort intervals
CHARACTERISTICS OF THE USED GROUPS
 half-sib group 1 with        8.0 dams, producing        8.0 animals
 half-sib group 2 with        7.0 dams, producing        7.0 animals
 progeny group information
 progeny group 1 with      100.0 dams, producing      100.0 progeny
 INDEX INFORMATION :
 sire class : 1
          Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
          Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
 sire class : 2
          Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
          Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
 sire class : 3
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 1 on milk
Mean EBV of the dams of hs-group 1 on milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 1 on c_interval
Mean EBV of the dams of hs-group 1 on c_interval
 sire class : 4
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 1 on milk
Mean EBV of the dams of hs-group 1 on milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 1 on c_interval
Mean EBV of the dams of hs-group 1 on c_interval
 sire class : 5
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 1 on milk
Mean EBV of the dams of hs-group 1 on milk
   Observations on progeny group 1 on milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 1 on c_interval

---

<!-- Page 31 -->

Mean EBV of the dams of hs-group 1 on c_interval
   Observations on progeny group 1 on c_interval
 sire class : 6
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 1 on milk
Mean EBV of the dams of hs-group 1 on milk
   Observations on progeny group 1 on milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 1 on c_interval
Mean EBV of the dams of hs-group 1 on c_interval
   Observations on progeny group 1 on c_interval
 sire class : 7
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 1 on milk
Mean EBV of the dams of hs-group 1 on milk
   Observations on progeny group 1 on milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 1 on c_interval
Mean EBV of the dams of hs-group 1 on c_interval
   Observations on progeny group 1 on c_interval
 sire class : 8
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 1 on milk
Mean EBV of the dams of hs-group 1 on milk
   Observations on progeny group 1 on milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 1 on c_interval
Mean EBV of the dams of hs-group 1 on c_interval
   Observations on progeny group 1 on c_interval
  dam class : 1 (= age class 9)
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  dam class : 2 (= age class 10)
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  dam class : 3 (= age class 11)
                   Own performance of milk
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 2 on milk
Mean EBV of the dams of hs-group 2 on milk
                   Own performance of c_interval
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 2 on c_interval
Mean EBV of the dams of hs-group 2 on c_interval

---

<!-- Page 32 -->

dam class : 4 (= age class 12)
                   Own performance of milk
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 2 on milk
Mean EBV of the dams of hs-group 2 on milk
                   Own performance of c_interval
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 2 on c_interval
Mean EBV of the dams of hs-group 2 on c_interval
  dam class : 5 (= age class 13)
                   Own performance of milk
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 2 on milk
Mean EBV of the dams of hs-group 2 on milk
                   Own performance of c_interval
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 2 on c_interval
Mean EBV of the dams of hs-group 2 on c_interval
  dam class : 6 (= age class 14)
                   Own performance of milk
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 2 on milk
Mean EBV of the dams of hs-group 2 on milk
                   Own performance of c_interval
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 2 on c_interval
Mean EBV of the dams of hs-group 2 on c_interval
  dam class : 7 (= age class 15)
                   Own performance of milk
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 2 on milk
Mean EBV of the dams of hs-group 2 on milk
                   Own performance of c_interval
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 2 on c_interval
Mean EBV of the dams of hs-group 2 on c_interval
  dam class : 8 (= age class 16)
                   Own performance of milk
           Dam BLUP breeding value of milk
          Sire BLUP breeding value of milk
  Observations on half-sib group 2 on milk
Mean EBV of the dams of hs-group 2 on milk
                   Own performance of c_interval
           Dam BLUP breeding value of c_interval
          Sire BLUP breeding value of c_interval
  Observations on half-sib group 2 on c_interval
Mean EBV of the dams of hs-group 2 on c_interval
             ******************   RESULTS   *******************

---

<!-- Page 33 -->

EQUILIBRIUM PARAMETERS
               phenotypic variance  heritability
     milk            1,148.078          0.253
     c_interval        440.984          0.100
  PHENOTYPIC CORRELATIONS
                milk   c_interval
  milk          1.000
  c_interval    0.516    1.000
  GENETIC CORRELATIONS
                 milk   c_interval
  milk          1.000
  c_interval    0.561    1.000
  RESPONSE
                                     sires           dams          total
     milk
               trait units:           2.793          0.446          3.239
            economic units:           2.793          0.446          3.239
        % of totalresponse:          86.187         13.779         99.966
     c_interval
               trait units:          -0.026          0.025         -0.001
            economic units:           0.043         -0.042          0.001
        % of totalresponse:           1.316         -1.283          0.034
  TOTALRESPONSE
                                     sires           dams          total
            economic units:           2.835          0.405          3.240
 sire class 1 variance of index:          10.386
              accuracy of index:           0.227
 sire class 2 variance of index:          10.386
              accuracy of index:           0.227
 sire class 3 variance of index:          11.147
              accuracy of index:           0.235
 sire class 4 variance of index:          11.147
              accuracy of index:           0.235
 sire class 5 variance of index:         166.683
              accuracy of index:           0.910
 sire class 6 variance of index:         166.683
              accuracy of index:           0.910
 sire class 7 variance of index:         166.683
              accuracy of index:           0.910
 sire class 8 variance of index:         166.683
              accuracy of index:           0.910
  dam class 1 variance of index:          10.386
              accuracy of index:           0.227
  dam class 2 variance of index:          10.386
              accuracy of index:           0.227
  dam class 3 variance of index:          51.393

---

<!-- Page 34 -->

accuracy of index:           0.505
  dam class 4 variance of index:          51.393
              accuracy of index:           0.505
  dam class 5 variance of index:          51.393
              accuracy of index:           0.505
  dam class 6 variance of index:          51.393
              accuracy of index:           0.505
  dam class 7 variance of index:          51.393
              accuracy of index:           0.505
  dam class 8 variance of index:          51.393
              accuracy of index:           0.505
 variance of breeding goal:         201.371
                      ******  end of output  ******



