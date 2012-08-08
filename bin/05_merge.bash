#!/bin/bash


PROBABEL_DIR=$1
LOG_DIR=$2
PROBABEL_OUT_PREFIX="probabel_merge"

# MERGE PROBABEL RESULTS
head -n 1 `ls ${PROBABEL_DIR}/*_add.out.txt | head -n 1` | cut -d ' ' -f 1,2,3,9,10,11,12,13 > ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.txt
for f in `ls ${PROBABEL_DIR}/*_add.out.txt`
do
    tail -n +2 $f | cut -d ' ' -f 1,2,3,9,10,11,12,13 >> ${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.txt
done

cat > merge.r << EOT
fn = paste(c("${PROBABEL_DIR}", "/", "${PROBABEL_OUT_PREFIX}.txt"), collapse="")
probabel_res = read.table(fn, header=T, sep=" ")
pvalue = pchisq((probabel_res\$beta_SNP_add/probabel_res\$sebeta_SNP_add)^2, df=1, lower=F)
probabel_res = cbind(probabel_res, pvalue)
probabel_res = probabel_res[with(probabel_res, order(probabel_res\$chrom, probabel_res\$position)), ]
write.table(probabel_res, file="probabel_res.txt", row.names=F, col.names=T, quote=F)
save(probabel_res, file="${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.RData")
EOT

R --no-save < merge.r &> ${LOG_DIR}/${PROBABEL_OUT_PREFIX}.log