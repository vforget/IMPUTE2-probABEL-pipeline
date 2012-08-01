#!/bin/bash

## Written by: Vince Forgetta, vincenzo.forgetta@mail.mcgill.ca.

## Merge data and produce graphs

cat > graphs.r << EOT
library(GenABEL)
library(gap)
files = list.files(pattern="*_add.out.txt")
print(files[1])
probabel_res = read.table(files[1], header=T, sep=" ")
for(i in 2:length(files)) {
    fn = files[i]
    print (fn)
    pr = read.table(fn, header=T, sep=" ")
    probabel_res = rbind(probabel_res, pr)
    
}
pvalue = pchisq((probabel_res\$beta_SNP_add/probabel_res\$sebeta_SNP_add)^2, df=1, lower=F)
probabel_res = cbind(probabel_res, pvalue)
write.table(probabel_res, file="probabel_res.txt")

png(filename="qqplot.png")
qqunif(probabel_res\$pvalue, pch=21, cex=.51, bg="black", bty="n", col="1", main=paste(c("QQ plot (", length(probabel_res\$pvalue), " SNPs)"), collapse=""))
dev.off()

png(filename="mhtplot.png")
mhtplot(data.frame(probabel_res\$chrom, probabel_res\$position, probabel_res\$pvalue), xlab="SNP Position", ylab="-log10(p-value)", mht.control(cex=3, labels=probabel_res\$chrom, col=seq(1:22)), pch=".")
dev.off()

top_snps = subset(probabel, pvalue < 5e-06)
write.table(top_snps, file="top_snps.txt")

EOT

R --no-save < graphs.r