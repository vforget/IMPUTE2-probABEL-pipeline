#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## Merges probabel results into one file (removing some columns of data). 
## Filter SNPs for info [0.4,inf) , Mean_Predictor_Freq [0.01,0.99], beta [-1.5,1.5], se_beta [0.01,inf)

PROBABEL_DIR=$1
INFO_SNP_FILE=$2
LOG_DIR=$3
PROBABEL_OUT_PREFIX=$4
BINDIR=$5

# MERGE PROBABEL RESULTS
for f in `ls ${PROBABEL_DIR}/*_add.out.txt.pvalue`
do
    tail -n +2 $f | cut -d ' ' -f 1,2,3,9,10,11,12,13,14 | sort -k5n,6n  > ${f}.sort
done

# Sort output by chrom and pos
sort -m -k5n,6n ${PROBABEL_DIR}/*_add.out.txt.pvalue.sort > ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.sort.txt

# Filter for info SNPs
join -t " " -j 1 ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.sort.txt ${INFO_SNP_FILE} | cut -f 1-9 -d " " >  ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.filtered.tmp

# Filter for Mean_Predictor_Freq, beta and se_beta
head -n 1 `ls ${PROBABEL_DIR}/*_add.out.txt.pvalue | head -n 1` | cut -d ' ' -f 1,2,3,9,10,11,12,13,14 > ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.filtered
awk '{ if ((($4 != "NA") && ($7 != "NA") && ($8 != "NA")) && ($4 >= 0.01) && ($4 <= 0.99) && ($7 >= -1.5) && ($7 <= 1.5) && ($8 >= 0.01)) print $0 }' ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.filtered.tmp >> ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.filtered

# Save as R image (for faster loading later ...)
cat > ${PROBABEL_DIR}/save_${PROBABEL_OUT_PREFIX}.r << EOT
probabel_res = read.table("${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.filtered", header=T, sep=" ")
save(probabel_res, file="probabel/${PROBABEL_OUT_PREFIX}.RData")
EOT

R --no-save < ${PROBABEL_DIR}/save_${PROBABEL_OUT_PREFIX}.r &> ${LOG_DIR}/save_${PROBABEL_OUT_PREFIX}.log