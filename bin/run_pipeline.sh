#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## This pipeline runs ProbABEL analysis using imputed genotypes from SNPTEST or IMPUTE.
## IMPORTANT: 
##           1. Chromosome number is parsed from the genotype file name e.g. chr7.gen parses to "7".
##           2. By default, it is assumed the polygenic matrix exists (see INVSIGMA variable). To create one, set 
##              DO_POLYGENIC=true, changing the appropriate variable below in the PHENOTYPE DATA section.
##           3. By default, genotype files end in .gen and sample files in .sample.
##           4. By default, SGE is used. To disable it, set USE_SGE=false.
##           5. By default, SNPs with info >=0.4 are retained as computed from the tuk317K and tuk610Kplus data sets. To change this see the SNP INFORMATIVITY section.

echoerr() { echo "$@" 1>&2; } # function to print to stderr

# Use SGE
USE_SGE=true

###################
## GENOTYPE DATA ##
###################

# Where the genotype and sample info files are located (i.e. .gen files)
GENDIR=$1
# Suffix for genotype files
GENO_SUFFIX="gen"
# Suffix for sample files
SAMP_SUFFIX="sample"

####################
## PHENOTYPE DATA ##
####################

# Compute polygenic matrix? Should only be re-run if phenotype or kinship matrix changes.
DO_POLYGENIC=false
# Location of phenotype file
PHENO=~/share/vince.forgetta/0712-probabel-pipeline/static/fabmd.txt
# Location of kinship matrix
KINSHIP_MAT=~/archive/t123TUK/imputed/HapMap/GenABEL/kinship-comb.RData
# Formula used to compute polygenic matrix
FORMULA="fa_d_st"
# Output name for polygenic matrix
INVSIGMA=~/share/vince.forgetta/0712-probabel-pipeline/static/invsigma.dat

#####################
# SNP INFORMATIVITY #
#####################

# Filter SNPs for informativity? Should only be re-run if source informativity values change (see this steps code below for paths to these source files)
DO_FILTERINFO=false
INFO_FILE_317k=~/archive/t123TUK/imputed/1kGenomes.Phase1/info/info_posterior_tuk317K.b37ph/tuk317K.b37ph.chr1-22.ALL_1000G_phase1interim_jun2011_.posterior_sampled_haps_imputation.impute2_info
INFO_FILE_610kplus=~/archive/t123TUK/imputed/1kGenomes.Phase1/info/info_posterior_tuk610Kplus.b37ph/tuk610Kplus.b37ph.chr1-22.ALL_1000G_phase1interim_jun2011_.posterior_sampled_haps_imputation.impute2_info
# Min. allele freq to include SNP from informativity files
INFO_MIN_FREQ=0.4
# Where informative SNPs are stored
INFO_SNP_FILE=~/share/vince.forgetta/0712-probabel-pipeline/static/tuk.INFOgteq0.4.BOTH.txt.sort

########################
## OUTPUT DIRECTORIES ##
########################

# Use absolute or relative paths. By default, they are relative to the current directory to where run_pipeline was executed.
DATABEL_DIR=databel
PROBABEL_DIR=probabel
LOG_DIR=log

####################
## PIPELINE STEPS ##
####################

# Which steps of the pipeline to run
# Convert impute to databel format?
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


# STEP1: FILTER SNPs FOR INFORMATIVITY AND COMPUTE POLYGENIC MATRIX

if $DO_FILTERINFO; then
    # Files with informativity information for SNPs
    tail -n +2 $INFO_FILE_317k | awk "{ if (\$5 >= b${INFO_MIN_FREQ}){ if (\$1 ~ /\-\-\-/){ split(\$2, a, \"-\"); print \$2, a[1], \$3 }else{ print \$2, \$1, \$3 }}}" > tuk317K.INFOgteq0.4.txt
    tail -n +2 $INFO_FILE_610kplus | awk "{ if (\$5 >= ${INFO_MIN_FREQ}){ if (\$1 ~ /\-\-\-/){ split(\$2, a, \"-\"); print \$2, a[1], \$3 }else{ print \$2, \$1, \$3 }}}" > tuk610Kplus.INFOgteq0.4.txt
    tail -q -n +2 $INFO_FILE_317k $INFO_FILE_610kplus | awk "{ if (\$5 >= ${INFO_MIN_FREQ}){ if (\$1 ~ /\-\-\-/){ split(\$2, a, \"-\"); print \$2, a[1], \$3 }else{ print \$2, \$1, \$3 }}}" | sort -k2n,3n | uniq > tmp.info
    comm -1 -2 tuk317K.INFOgteq0.4.txt tuk610Kplus.INFOgteq0.4.txt | sort -k2n,3n > ${INFO_SNP_FILE}
fi

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
	CHROM=`echo ${PREFIX} | perl -p -e "s/.*chr([0-9XY]+).*/\1/;"`
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
    PROBABEL_PREFIX="probabel"
    echo "${BINDIR}/05_merge.bash ${PROBABEL_DIR} ${INFO_SNP_FILE} ${LOG_DIR} ${PROBABEL_PREFIX} ${BINDIR}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N $MERGE_ID -hold_jid $PROBABEL_ID -q all.q
    echo "${BINDIR}/06_graphs.bash ${PROBABEL_DIR} ${PVALUE_CUTOFF} ${LOG_DIR} ${PROBABEL_PREFIX}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N "PrPipRes" -hold_jid $PROBABEL_ID,$MERGE_ID -q all.q
fi