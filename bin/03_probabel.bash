#!/bin/bash

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