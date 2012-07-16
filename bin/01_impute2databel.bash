#!/bin/bash

## Generate a DATABEL file for PROBABEL from a genotype file from SNPTEST or IMPUTE.
## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca
## This script requries that the R statistical package is installed with the GenABEL library.


GENOFILE=$1 # Genotype file from SNPTEST or IMPUTE.
SAMPFILE=$2 # Sample file from SNPTEST or IMPUTE.
PREFIX=$3   # Filename prefix for output.

cat > ${PREFIX}_impute2databel.r << EOT
library(GenABEL)
impute2databel(genofile="${GENOFILE}", sample="${SAMPFILE}", makeprob=FALSE, outfile="${PREFIX}")
EOT

R --no-save < ${PREFIX}_impute2databel.r &> ${PREFIX}_impute2databel.log