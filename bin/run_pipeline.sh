#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## This pipeline runs ProbABEL analysis using imputed genotypes from SNPTEST or IMPUTE.
## IMPORTANT: 
##           1. Chromosome number is parsed from the genotype file name e.g. chr7.gen parses to "7".
##           2. By default, it is assumed the polygenic matrix exists (see INVSIGMA variable). To create one, set 
##              COMPUTE_POLYGENIC=true.
##           3. By default, genotype files end in .gen and sample files in .sample.
##           4. By default, SGE is used. To disable it, set USE_SGE=false.

echoerr() { echo "$@" 1>&2; }

# Where the genotype and sample info files are located
GENDIR=$1
# Suffix for genotype files
GENO_SUFFIX="gen"
# Suffix for sample files
SAMP_SUFFIX="sample"
# Location of phenotype file
PHENO=~/share/vince.forgetta/0712-probabel-pipeline/static/fabmd.txt
# Location of kinship matrix
KINSHIP_MAT=~/archive/t123TUK/imputed/HapMap/GenABEL/kinship-comb.RData
# Formula used to compute polygenic matrix
FORMULA="fa_d_st"
# Output name for polygenic matrix
INVSIGMA=~/share/vince.forgetta/0712-probabel-pipeline/static/invsigma.dat
# Compute polygenic matrix?
COMPUTE_POLYGENIC=false
# Use SGE
USE_SGE=true
# P-value cutoff fot top snps
PVALUE_CUTOFF="5e-06"
# Output directories
DATABEL_DIR=databel
PROBABEL_DIR=probabel
LOG_DIR=log

# Where the binaries and scripts are located. Only change this if you move this directory.
BINDIR=~/share/vince.forgetta/0712-probabel-pipeline/bin

## !!!! MODIFY CODE BELOW WITH CARE !!!!

echoerr "Pipeline started at " `date`

mkdir -p ${DATABEL_DIR}
mkdir -p ${PROBABEL_DIR}
mkdir -p ${LOG_DIR}

# STEP1: COMPUTE POLYGENIC MATRIX
if $COMPUTE_POLYGENIC; then
    echoerr "Polygenic started at " `date`
    ${BINDIR}/00_polygenic.bash ${KINSHIP_MAT} ${PHENO} ${INVSIGMA} ${FORMULA} ${LOG_DIR}
    echoerr "Polygenic ended at " `date`
fi

# STEP2: IMPUTE TO DATABEL CONVERSION
echoerr "Genabel started at " `date`
for GENOFILE in `ls ${GENDIR}/*.${GENO_SUFFIX}`
do
    mkdir -p sge_job_log
    PREFIX=`basename ${GENOFILE} .${GENO_SUFFIX}`
    SAMPFILE="${GENDIR}/${PREFIX}.${SAMP_SUFFIX}"
    if $USE_SGE; then
	echo "${BINDIR}/01_impute2databel.bash ${GENOFILE} ${SAMPFILE} ${PREFIX} ${DATABEL_DIR} ${LOG_DIR}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N ${PREFIX}_databel -sync y &
    else
	${BINDIR}/01_impute2databel.bash ${GENOFILE} ${SAMPFILE} ${PREFIX} ${DATABEL_DIR} ${LOG_DIR}
    fi
done
wait
echoerr "Genabel ended at " `date`

# STEP 3: PROBABEL
echoerr "Probabel started at " `date`
for GENOFILE in `ls ${GENDIR}/*.${GENO_SUFFIX}`
do
    mkdir -p sge_job_log
    PREFIX=`basename ${GENOFILE} .${GENO_SUFFIX}`
    SAMPFILE="${GENDIR}/${PREFIX}.${SAMP_SUFFIX}"
    # *** Parsing of chromosome name from genotype file ***
    CHROM=`echo ${PREFIX} | perl -p -e "s/.*chr([0-9XY]+)\..*/\1/;"`
    ${BINDIR}/02_mlinfo.bash ${GENOFILE} ${PREFIX} ${PROBABEL_DIR}
    ${BINDIR}/03_map.bash ${GENOFILE} ${PREFIX} ${PROBABEL_DIR}
    if $USE_SGE; then
	echo "${BINDIR}/04_probabel.bash ${PREFIX} ${CHROM} ${INVSIGMA} ${PHENO} ${BINDIR} ${DATABEL_DIR} ${PROBABEL_DIR} ${LOG_DIR}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N ${PREFIX}_probabel -sync y &
    else
	${BINDIR}/04_probabel.bash ${PREFIX} ${CHROM} ${INVSIGMA} ${PHENO} ${BINDIR} ${DATABEL_DIR} ${PROBABEL_DIR} ${LOG_DIR}
    fi
done
wait
echoerr "Probabel ended at " `date`

# STEP 4: GRAPHS AND RESULTS
echoerr "Graphs started at " `date`
${BINDIR}/05_graphs.bash ${PROBABEL_DIR}
echoerr "Graphs ended at " `date`

echoerr "Pipeline ended at " `date`