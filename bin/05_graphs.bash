#!/bin/bash

## Written by: Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca.

## Merge data and produce graphs

PROBABEL_DIR=$1
PVALUE_CUTOFF=$2

cat > graphs.r << EOT
library(GenABEL)
library(gap)
files = list.files(path="${PROBABEL_DIR}/", pattern="*_add.out.txt")
fn = paste(c("${PROBABEL_DIR}", "/", files[1]), collapse="")
probabel_res = read.table(fn, header=T, sep=" ")
for(i in 2:length(files)) {
    fn = paste(c("${PROBABEL_DIR}", "/", files[i]), collapse="")
    pr = read.table(fn, header=T, sep=" ")
    probabel_res = rbind(probabel_res, pr)
    
}
pvalue = pchisq((probabel_res\$beta_SNP_add/probabel_res\$sebeta_SNP_add)^2, df=1, lower=F)
probabel_res = cbind(probabel_res, pvalue)
probabel_res = probabel_res[with(probabel_res, order(probabel_res\$chrom, probabel_res\$position)), ]
write.table(probabel_res, file="probabel_res.txt", row.names=F, col.names=T, quote=F)

png("mhtplot.png", width=10, height=13, unit="in", res=200)
colors <- rep(c("blue", "green"),11)
mhtplot(data.frame(probabel_res\$chrom, probabel_res\$position, probabel_res\$pvalue), control=mht.control(usepos=TRUE, colors=colors),pch=19)
axis(2,at=seq(0, max(-log10(probabel_res\$pvalue), na.rm=TRUE)), labels=seq(0, max(-log10(probabel_res\$pvalue), na.rm=TRUE)))
dev.off()


png(filename="qqplot.png")
qqunif(probabel_res\$pvalue, pch=21, cex=.51, bg="black", bty="n", col="1", main=paste(c("QQ plot (", length(probabel_res\$pvalue), " SNPs)"), collapse=""))
dev.off()

top_snps = subset(probabel_res, pvalue < ${PVALUE_CUTOFF})
write.table(top_snps, file="top_snps.txt", row.names=F, col.names=T, quote=F)
EOT

R --no-save < graphs.r