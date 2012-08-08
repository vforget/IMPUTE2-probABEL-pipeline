#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## This pipeline runs ProbABEL analysis using imputed genotypes from SNPTEST or IMPUTE.
## IMPORTANT: 
##           1. Chromosome number is parsed from the genotype file name e.g. chr7.gen parses to "7".
##           2. By default, it is assumed the polygenic matrix exists (see INVSIGMA variable). To create one, set 
##              DO_POLYGENIC=true.
##           3. By default, genotype files end in .gen and sample files in .sample.
##           4. By default, SGE is used. To disable it, set USE_SGE=false.

echoerr() { echo "$@" 1>&2; } # function to print to stderr

# Use SGE
USE_SGE=true

#################
## IMPUTE DATA ##
#################

# Where the genotype and sample info files are located
GENDIR=$1
# Suffix for genotype files
GENO_SUFFIX="gen"
# Suffix for sample files
SAMP_SUFFIX="sample"

####################
## PHENOTYPE DATA ##
####################

# Location of phenotype file
PHENO=~/share/vince.forgetta/0712-probabel-pipeline/static/fabmd.txt
# Location of kinship matrix
KINSHIP_MAT=~/archive/t123TUK/imputed/HapMap/GenABEL/kinship-comb.RData
# Formula used to compute polygenic matrix
FORMULA="fa_d_st"
# Output name for polygenic matrix
INVSIGMA=~/share/vince.forgetta/0712-probabel-pipeline/static/invsigma.dat

########################
## OUTPUT DIRECTORIES ##
########################

DATABEL_DIR=databel
PROBABEL_DIR=probabel
LOG_DIR=log

####################
## PIPELINE STEPS ##
####################

# Which steps of the pipeline to run
# Compute polygenic matrix?
DO_POLYGENIC=false
# Convert impute to databel formar?
DO_DATABEL=true
# Run probabel on databel data?
DO_PROBABEL=true
# P-value cutoff for probabel top snps
PVALUE_CUTOFF="5e-06"
# Generate output graphs and tables?
DO_GRAPHS=true

# Where the binaries and scripts are located. Only change this if you move this directory.
BINDIR=~/share/vince.forgetta/0712-probabel-pipeline/bin

###########################################
## !!!! MODIFY VARIABLES ABOVE ONLY !!!! ##
## !!!! MODIFY CODE BELOW WITH CARE !!!! ##
###########################################

mkdir -p ${DATABEL_DIR}  
mkdir -p ${PROBABEL_DIR} 
mkdir -p ${LOG_DIR} 
mkdir -p sge_job_log

# STEP1: COMPUTE POLYGENIC MATRIX
if $DO_POLYGENIC; then
    echoerr "Polygenic started at " `date`
    ${BINDIR}/00_polygenic.bash ${KINSHIP_MAT} ${PHENO} ${INVSIGMA} ${FORMULA} ${LOG_DIR}
    echoerr "Polygenic ended at " `date`
fi

# STEP2: IMPUTE TO DATABEL CONVERSION
if $DO_DATABEL; then
    for GENOFILE in `ls ${GENDIR}/*.${GENO_SUFFIX}`
    do
	PREFIX=`basename ${GENOFILE} .${GENO_SUFFIX}`
	SAMPFILE="${GENDIR}/${PREFIX}.${SAMP_SUFFIX}"
	CMD="${BINDIR}/01_impute2databel.bash ${GENOFILE} ${SAMPFILE} ${PREFIX} ${DATABEL_DIR} ${LOG_DIR}"
	if $USE_SGE; then
	    echo $CMD | qsub -V -cwd -o sge_job_log -e sge_job_log -N ${PREFIX}_databel -q all.q
	else
	    $CMD
	fi
    done
fi

# STEP 3: PROBABEL
if $DO_PROBABEL; then
    PROBABEL_ID="p$RANDOM"
    
    for GENOFILE in `ls ${GENDIR}/*.${GENO_SUFFIX}`
    do
	mkdir -p sge_job_log
	PREFIX=`basename ${GENOFILE} .${GENO_SUFFIX}`
	SAMPFILE="${GENDIR}/${PREFIX}.${SAMP_SUFFIX}"
        # *** Parsing of chromosome name from genotype file ***
	CHROM=`echo ${PREFIX} | perl -p -e "s/.*chr([0-9XY]+)\..*/\1/;"`
	CMD="${BINDIR}/04_probabel.bash ${PREFIX} ${CHROM} ${INVSIGMA} ${PHENO} ${BINDIR} ${DATABEL_DIR} ${PROBABEL_DIR} ${LOG_DIR} ${GENOFILE}"
	if $USE_SGE; then
	    echo $CMD | qsub -V -cwd -o sge_job_log -e sge_job_log -N $PROBABEL_ID -hold_jid ${PREFIX}_databel -q 10.q
	else
	    $CMD
	fi
    done    
fi

# STEP 4: GRAPHS AND RESULTS
if $DO_GRAPHS; then
    MERGE_ID="m$RANDOM"
    echo "${BINDIR}/05_merge.bash ${PROBABEL_DIR} ${LOG_DIR}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N $MERGE_ID -hold_jid $PROBABEL_ID -q all.q
    echo "${BINDIR}/05_graphs.bash ${PROBABEL_DIR} ${PVALUE_CUTOFF} ${LOG_DIR}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N "PrPipRes" -hold_jid $PROBABEL_ID,$MERGE_ID -q all.q
fi


    