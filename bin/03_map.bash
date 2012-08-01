#!/bin/bash

## Written by: Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca.

## Generate a MLINFO file for PROBABEL from genotype file from SNPTEST or IMPUTE.

GENOFILE=$1   # Genotype file from SNPTEST or IMPUTE
PREFIX=$2     # Prefix for file output

awk "BEGIN { print \"rs position 0 1\" } { print \$2, \$3, \$4, \$5 }" ${GENOFILE} > ${PREFIX}.map



