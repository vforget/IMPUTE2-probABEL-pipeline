#!/bin/bash

## Generate a DATABEL file for PROBABEL from a genotype file from SNPTEST or IMPUTE.
## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca
## This script requries that the R statistical package is installed with the GenABEL library.


GENOFILE=$1    # Genotype file from SNPTEST or IMPUTE.
SAMPFILE=$2    # Sample file from SNPTEST or IMPUTE.
PREFIX=$3      # Filename prefix for output.
DATABEL_DIR=$4 # where to store results
LOG_DIR=$5 

cat > ${DATABEL_DIR}/${PREFIX}_impute2databel.r << EOT
library(GenABEL)
setwd("${DATABEL_DIR}")
impute2databel(genofile="${GENOFILE}", sample="${SAMPFILE}", makeprob=FALSE, outfile="${PREFIX}")
EOT

R --no-save < ${DATABEL_DIR}/${PREFIX}_impute2databel.r &> ${LOG_DIR}/${PREFIX}_impute2databel.log