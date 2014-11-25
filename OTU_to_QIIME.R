args=(commandArgs(TRUE))
infile <- paste(args[1], "/OTU_tag_mapped.txt", sep="")
outfile <- paste(args[1], "/td_OTU_tag_mapped.txt", sep="")
d <- read.table(infile, header=T, stringsAsFactors=T, row.names=1, sep="\t")

print(c(infile,outfile))
#remove the OTU_ text
cn <- gsub("OTU_", "", colnames(d))
colnames(d) <- cn

#remove the total and remainder columns
d$Ltag.Rtag <- NULL
d$total <- NULL
d$rem <- NULL
td <- t(d)
#add the proper headers for QIIME
cntd <- colnames(td)
cntd[1] <- paste("#metadata here\n#OTU ID\t", cntd[1], sep="")
colnames(td) <- cntd
write.table(td, outfile, sep="\t", row.names=T, quote=F)
