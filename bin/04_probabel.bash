#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## Runs ProbABEL as part of a larger pipeline.

PREFIX=$1
CHROM=$2
INVSIGMA=$3
PHENO=$4
BINDIR=$5
DATABEL_DIR=$6
PROBABEL_DIR=$7
LOG_DIR=$8

${BINDIR}/palinear \
    --pheno ${PHENO} \
    --dose ${DATABEL_DIR}/${PREFIX}.dose.fvi \
    --info ${PROBABEL_DIR}/${PREFIX}.mlinfo \
    --mmscore ${INVSIGMA} \
    --chrom ${CHROM} \
    --map ${PROBABEL_DIR}/${PREFIX}.map \
    --out ${PROBABEL_DIR}/${PREFIX} &> ${LOG_DIR}/${PREFIX}_probabel.log