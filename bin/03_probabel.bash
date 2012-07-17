#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## Runs ProbABEL as part of a larger pipeline.

PREFIX=$1
CHROM=$2
INVSIGMA=$3
PHENO=$4
BINDIR=$5

${BINDIR}/palinear \
    --pheno ${PHENO} \
    --dose ${PREFIX}.dose.fvi \
    --info ${PREFIX}.mlinfo \
    --mmscore ${INVSIGMA} \
    --chrom ${CHROM} \
    --out ${PREFIX}