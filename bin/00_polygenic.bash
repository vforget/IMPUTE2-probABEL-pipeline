#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## Compute the polygenic matrix using R and GenABEL. 
## As per ProbABEL requirements, must remove individuals with no
## phenotype from polygenic matrix.

KINSHIP_MAT=$1
PHENO=$2
INVSIGMA=$3
FORMULA=$4

cat > polygenic.r << EOT
# Generate a polygenic matrix given a kinship matrix and phenotype data
library(GenABEL)

# kinship data from HapMap imputed data
load("${KINSHIP_MAT}")

# phenotype data from Hou Feng, inserting missing samples and sex
ph = read.table("${PHENO}", header=T, sep=" ")
attach(ph)

# compute polygenic matrix
poly = polygenic(${FORMULA}, kin=geno_comb.gkin, data=ph, starth2=0.6, opt.method="optim")

# remove id with no phenotype
ph_no_na = na.omit(ph)
subset = poly$InvSigma[as.character(ph_no_na$id), as.character(ph_no_na$id)]

write.table(subset, file="${INVSIGMA}", row.names=T, col.names=F, quote=F)

EOT

R --no-save < polygenic.r &> polygenic.log