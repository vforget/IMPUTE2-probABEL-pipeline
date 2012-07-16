#!/bin/bash

## Generate a MLINFO file for PROBABEL from genotype file from SNPTEST or IMPUTE.
## Written by: Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca.

GENOFILE=$1   # Genotype file from SNPTEST or IMPUTE
PREFIX=$2     # Prefix for file output
A_FREQ=0.5847 # Dummy allele freq, not used by probabel. Only migrated to output. Cannot be 0 (zero).

awk "BEGIN { print \"SNP Al1 Al2 Freq1 MAF Quality Rsq\" } { print \$2, \$4, \$5, ${A_FREQ}, ${A_FREQ}, ${A_FREQ}, ${A_FREQ} }" ${GENOFILE} > ${PREFIX}.mlinfo

