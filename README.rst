ProbABEL Pipeline
=================

SUMMARY
-------

The purpose of this document is to concisely describe the pipeline used to compute ProbABEL results from imputed genotypes.

USAGE
-----

The pipeline is run via the run_pipeline.bash script. The sole command line parameter is the path to the imputed genotype files. By default these are .gen and .sample files from IMPUTE. Behavior of the programs can be futher modified by changing variables at the top of the run_pipeline.bash script.

The run_pipeline.bash script itself runs another 6 bash scripts in 4 steps:

STEP 1
~~~~~~
Script: 00_polygenic.bash

Optional as long as the required file for ProbABEL is present i.e., a polygenic matrix file (e.g., invsigma.dat). Otherwise, this file needs to be computed from a kinship martix and phenotype file using the R/GenABEL polygenic function. Moreover, this should only be run once, and only re-run if the phenotype or kindship matrix is changed.

To enable or diable this step toggle the DO_POLYGENIC variable.

Also in this step, SNPs are filtered based on informativity.  This should only need to be computed once, unless the informativity information for each SNP happends to change. Currently, the informavivity information is based on tuk317k and tuk610kplus data.

To enable or diable this step toggle the DO_FILTERINFO variable.

STEP 2
~~~~~~
Script: 01_impute2databel.bash

This step converts IMPUTE genotypes to DatABEL format for use with ProbABEL. For a given set of imputed genotypes this step only needs to be run once.

To enable or diable this step toggle the DO_DATABEL variable.

STEP 3
~~~~~~

Scripts: 02_mlinfo.bash, 03_map.bash, 04_probabel.bash

This step computes additional files for input into ProbABEL, then runs ProbABEL.  Specifically, it computes MLINFO file from IMPUTE data and computes MAP file from IMPUTE data (MAP file is optional for ProbABEL, but necessary to get SNP position information to migrate to results).

ProbABEL is then run using data from STEP 1, STEP 2 and STEP 3 (this step).

NOTE: With SGE, individual jobs from this step are on hold until their corresponding job from STEP 2 is complete.

STEP 4
~~~~~~

Script: 05_graphs.bash 

This step merges results across all chunks (or chromosomes) from Step 3, ultimately generating a Manhattan plot, a QQ plot, and a top snps table, amoung other results.

NOTE: With SGE, this step is on hold until the entirety of STEP 3 is complete.

EXAMPLE
-------

::

bash ~/share/vince.forgetta/0712-probabel-pipeline/bin/run_pipeline.sh ~/archive/t123TUK/imputed/1kGenomes.Phase1/gen.sample/chunks/

REQUIREMENTS
------------

* Linux OS
* Grid Engine is preferable but not necessary.
* R statistical package with the GenABEL and gap libraries.
* ProbABEL's palinear is provided in the bin directory, but a more recent version may be preferable. Replace it if necessary.


AUTHOR
------
Written by Vincenzo Forgetta, vincenzo.forgetta@mail.mcgill.ca.
