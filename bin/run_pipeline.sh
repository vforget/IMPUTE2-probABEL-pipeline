#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

echoerr() { echo "$@" 1>&2; }

# Where the genotype and sample info files are located
GENDIR=$1
# Suffix for genotype files
GENO_SUFFIX="gen"
#Suffix for sample files
SAMP_SUFFIX="sample"
# Location of phenotype file
PHENO=~/share/vince.forgetta/0712-probabel-pipeline/static/fabmd.txt
# Location of kinship matrix
KINSHIP_MAT=~/archive/t123TUK/imputed/HapMap/GenABEL/kinship-comb.RData
FORMULA="fa_d_st"
# Output name for polygenic matrix
INVSIGMA=invsigma.dat

# Where the binaries and scripts are located. Only change this if you move this directory.
BINDIR=~/share/vince.forgetta/0712-probabel-pipeline/bin

## !!!! MODIFY CODE BELOW WITH CARE !!!!

echoerr "Pipeline started at " `date`

${BINDIR}/00_polygenic.bash ${KINSHIP_MAT} ${PHENO} ${INVSIGMA} ${FORMULA}

for GENOFILE in `ls ${GENDIR}/*.${GENO_SUFFIX}`
do
    mkdir -p sge_job_log
    PREFIX=`basename ${GENOFILE} .${GENO_SUFFIX}`
    SAMPFILE="${GENDIR}/${PREFIX}.${SAMP_SUFFIX}"
    ${BINDIR}/01_impute2databel.bash ${GENOFILE} ${SAMPFILE} ${PREFIX}
    # SGE
    # echo "${BINDIR}/01_impute2databel.bash ${GENOFILE} ${SAMPFILE} ${PREFIX}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N ${PREFIX}_databel
done
wait

for GENOFILE in `ls ${GENDIR}/*.${GENO_SUFFIX}`
do
    mkdir -p sge_job_log
    PREFIX=`basename ${GENOFILE} .${GENO_SUFFIX}`
    SAMPFILE="${GENDIR}/${PREFIX}.${SAMP_SUFFIX}"
    CHROM=`echo ${PREFIX} | perl -p -e "s/.*chr([0-9XY]+)\..*/\1/;"`
    ${BINDIR}/02_mlinfo.bash ${GENOFILE} ${PREFIX}
    ${BINDIR}/03_probabel.bash ${PREFIX} ${CHROM} ${INVSIGMA} ${PHENO} ${BINDIR}
    # SGE
    # echo "${BINDIR}/03_probabel.bash ${PREFIX} ${CHROM} ${INVSIGMA} ${PHENO} ${BINDIR}" | qsub -V -cwd -o sge_job_log -e sge_job_log -N ${PREFIX}_probabel
done
wait

echoerr "Pipeline ended at " `date`

