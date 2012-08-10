#!/bin/bash

## Written by: Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca.

## Draws graphs, prints top snps

PROBABEL_DIR=$1
PVALUE_CUTOFF=$2
LOG_DIR=$3
PROBABEL_OUT_PREFIX=$4

cat > graphs.r << EOT
library(GenABEL)
library(gap)
load("${PROBABEL_DIR}/${PROBABEL_OUT_PREFIX}.RData")

# QQPLOT
png(filename="qqplot.png")
qqunif(probabel_res\$pvalue, pch=21, cex=.51, bg="black", bty="n", col="1", main=paste(c("QQ plot (", length(probabel_res\$pvalue), " SNPs)"), collapse=""))
dev.off()

# MHTPLOT
png("mhtplot.png", width=10, height=13, unit="in", res=200)
colors <- rep(c("blue", "green"),11)
mhtplot(data.frame(probabel_res\$chrom, probabel_res\$position, probabel_res\$pvalue), control=mht.control(usepos=TRUE, colors=colors),pch=19)
# Axis fails for very large datasets. This needs to be fixed.
#axis(2,at=seq(0, max(-log10(probabel_res\$pvalue), na.rm=TRUE)), labels=seq(0, max(-log10(probabel_res\$pvalue), na.rm=TRUE)))
dev.off()

# BOXPLOT
png("boxplots.png")
par(mfrow=c(1,2))
boxplot(probabel_res\$beta_SNP_add, main="beta")
boxplot(probabel_res\$sebeta_SNP_add, main="se_beta")
dev.off()

# TOP SNPS TABLE
top_snps = subset(probabel_res, pvalue < ${PVALUE_CUTOFF})
write.table(top_snps, file="top_snps.txt", row.names=F, col.names=T, quote=F)
EOT

R --no-save < graphs.r &> ${LOG_DIR}/graphs.log