#!/bin/bash

## Written by Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca

## Runs ProbABEL as part of a larger pipeline. Includes generating proper input files and calculating p-values.

PREFIX=$1
CHROM=$2
INVSIGMA=$3
PHENO=$4
BINDIR=$5
DATABEL_DIR=$6
PROBABEL_DIR=$7
LOG_DIR=$8
GENOFILE=$9

${BINDIR}/02_mlinfo.bash ${GENOFILE} ${PREFIX} ${PROBABEL_DIR}

${BINDIR}/03_map.bash ${GENOFILE} ${PREFIX} ${PROBABEL_DIR}

${BINDIR}/palinear \
    --pheno ${PHENO} \
    --dose ${DATABEL_DIR}/${PREFIX}.dose.fvi \
    --info ${PROBABEL_DIR}/${PREFIX}.mlinfo \
    --mmscore ${INVSIGMA} \
    --chrom ${CHROM} \
    --map ${PROBABEL_DIR}/${PREFIX}.map \
    --out ${PROBABEL_DIR}/${PREFIX} &> ${LOG_DIR}/${PREFIX}_probabel.log

cat > ${PROBABEL_DIR}/pvalue_${PREFIX}.r << EOT
probabel_res = read.table("${PROBABEL_DIR}/${PREFIX}_add.out.txt", header=T, sep=" ")
pvalue = pchisq((probabel_res\$beta_SNP_add/probabel_res\$sebeta_SNP_add)^2, df=1, lower=F)
probabel_res = cbind(probabel_res, pvalue)
probabel_res = probabel_res[with(probabel_res, order(probabel_res\$chrom, probabel_res\$position)), ]
write.table(probabel_res, file="${PROBABEL_DIR}/${PREFIX}_add.out.txt.pvalue", row.names=F, col.names=T, quote=F)
EOT

R --no-save < ${PROBABEL_DIR}/pvalue_${PREFIX}.r &> ${LOG_DIR}/pvalue_${PREFIX}.log
