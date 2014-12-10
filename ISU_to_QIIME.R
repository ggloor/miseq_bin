args=(commandArgs(TRUE))
infile <- paste(args[1], "/ISU_tag_mapped.txt", sep="")
outfile <- paste(args[1], "/td_ISU_tag_mapped.txt", sep="")
d <- read.table(infile, header=T, stringsAsFactors=T, row.names=1, sep="\t")

print(c(infile,outfile))
#remove the OTU_ text
cn <- gsub("ISU_", "", colnames(d))
colnames(d) <- cn

#remove the total and remainder columns
d$Ltag.Rtag <- NULL
d$total <- NULL
d$rem <- NULL
td <- t(d)
#add the proper headers for QIIME
cntd <- colnames(td)
today <- date()
cntd[1] <- paste("#metadata made ", today,"\n#ISU ID\t", cntd[1], sep="")
colnames(td) <- cntd
write.table(td, outfile, sep="\t", row.names=T, quote=F)
