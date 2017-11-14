# Updated: 18-Oct-2017
# This script is modified by JM from GG's original based on the dada2 tutorial found here:
#http://benjjneb.github.io/dada2/tutorial.html
# I HIGHLY RECOMMEND you cross-reference to the above tutorial to understand what you are doing

# For more information to run the pipeline, scroll down to the README at:
# https://github.com/ggloor/miseq_bin

# This workflow is set up to be run on cjelli, you will need to modify for your own machine

#-------------------------------------------------------
# Before running
#-------------------------------------------------------
# 1) Demultiplex your samples (assign each read to a sample based on the barcode) using demultiplex_dada2.pl
# 2) Start R
#		OR...SOURCE THIS SCRIPT WITH
#		nohup Rscript dada2_workflow.R &
#-------------------------------------------------------
# Setup
#-------------------------------------------------------
#Paths to reference taxonomy and reads
taxpath<-"/Volumes/longlunch/seq/annotationDB/dada2/silva_nr_v123_train_set.fa.gz" #cjelli
#taxpath<-"/Volumes/data/annotationDB/dada2/silva_nr_v123_train_set.fa.gz" #agrajag
reads<-"demultiplex_reads"

#Load needed libraries
library(dada2); packageVersion("dada2")

#Dump the R sessioninfo for later
writeLines(capture.output(sessionInfo()), "RsessionInfo_dada2.txt")

#-------------------------------------------------------
#list the files
#list.files(path)

# Get the filenames with relative path
# sort to ensure same order of fwd/rev reads
fnFs <- sort(list.files(reads, pattern="-R1.fastq", full.names=TRUE))
fnRs <- sort(list.files(reads, pattern="-R2.fastq", full.names=TRUE))
# Get sample names only (remove path, and everything after the first "-")
# Assuming filenames have format: SAMPLENAME-XXX.fastq
sample.names <- sapply(strsplit(basename(fnFs), "-"), `[`, 1)

#check for duplicated sample names before you move on
any(duplicated(names))
# STOP if this is TRUE and check: sample.names[duplicated(sample.names)]

#-------------------------------------------------------
# Check read quality
#-------------------------------------------------------
#This will pick a random subset of 4 samples to look at read quality
ids<-round(runif(4,1,length(sample.names)))

pdf("qualprofiles.pdf")
plotQualityProfile(fnFs[ids])
plotQualityProfile(fnRs[ids])
dev.off()

#-------------------------------------------------------
# Filter reads based on QC
#-------------------------------------------------------
message ("#		Filtering reads based on QC")
# Make filenames for the filtered fastq files
filtFs <- paste0(reads, "/", sample.names, "-F-filt.fastq.gz")
filtRs <- paste0(reads, "/", sample.names, "-R-filt.fastq.gz")

# the length must be equal to or shorter than the read!!
# that means 187 and 178 for V4 with paired 2x220 with 8 mer barcodes
# that means 183 and 174 for V4 with paired 2x220 with 12 mer barcodes
# DO NOT trim from the 5' end since primers and barcodes already trimmed off
out<-filterAndTrim(fnFs, filtFs, fnRs, filtRs,
			truncLen=c(220,175),
			truncQ=2,
            maxN=0,
            maxEE=c(2,2),
        	compress=TRUE, verbose=TRUE, multithread=TRUE)

write.table(out, file="after_filter.txt", sep="\t", col.names=NA, quote=F)

#example parameters. For paired reads, used a vector (2,2)
	#truncQ=2, #truncate reads after a quality score of 2 or less
	#truncLen=130, #truncate after 130 bases
	#trimLeft=10, #remove 10 bases off the 5’ end of the sequence
	#maxN=0, #Don’t allow any Ns in sequence
	#maxEE=2, #A maximum number of expected errors
	#rm.phix=TRUE, #Remove lingering PhiX (control DNA used in sequencing) as it is likely there is some.
	# On Windows set multithread=FALSE

# filtered reads are output to demultiplex_reads

#-------------------------------------------------------
# Learn the error rates - SLOW !!
#-------------------------------------------------------
message ("#		Learning error rates - SLOW !!")
errF <- learnErrors(filtFs, multithread=TRUE, randomize=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE, randomize=TRUE)
#	randomize=TRUE #don't pick the first 1mil for the model, pick a random set

#Plot the error rates and CHECK THE FIT
# Do not proceed without a good fit
pdf("err.pdf")
plotErrors(errF, nominalQ=TRUE)
plotErrors(errR, nominalQ=TRUE)
dev.off()

save.image("dada2.RData") #Insurance in case your script dies. Delete this later

#-------------------------------------------------------
# Dereplication
#-------------------------------------------------------
message ("#		Dereplicating the reads")

# Dereplication combines all identical sequencing reads into into “unique sequences” with a corresponding “abundance”: the number of reads with that unique sequence
# Dereplication substantially reduces computation time by eliminating redundant comparisons.

derepFs <- derepFastq(filtFs, verbose=TRUE)
derepRs <- derepFastq(filtRs, verbose=TRUE)
# Name the derep-class objects by the sample names
names(derepFs) <- sample.names
names(derepRs) <- sample.names

save.image("dada2.RData")  #Insurance in case your script dies. Delete this later

#-------------------------------------------------------
# Sample inference, merge paired reads, remove chimeras
#-------------------------------------------------------
message ("#		Inferring the sequence variants in each sample - SLOW!!")
#Infer the sequence variants in each sample - SLOW!!

dadaFs <- dada(derepFs, err=errF, multithread=TRUE)
dadaRs <- dada(derepRs, err=errR, multithread=TRUE)

# overlap the ends of the forward and reverse reads
message ("#		merging the Fwd and Rev reads")
mergers <- mergePairs(dadaFs, derepFs, dadaRs, derepRs, verbose=TRUE)
#, justConcatenate=TRUE for V59

# make the sequence table, samples are by rows
seqtab <- makeSequenceTable(mergers)

# summarize the output by length
table(nchar(getSequences(seqtab)))

message ("#		remove chimeras and save in seqtab.nochim - SLOW!!!!")
#The new default "method=consensus" doesn't work - look into this
seqtab.nochim <- removeBimeraDenovo(seqtab, method="pooled", verbose=TRUE, multithread=TRUE)
dim(seqtab.nochim)

#let's write the table, just in case
#samples are rows
write.table(seqtab.nochim, file="temp_dada2_nochim.txt", sep="\t", col.names=NA, quote=F)
# Or save the Rsession save.image("dada2.RData")
#save.image("dada2.RData")  #Insurance in case your script dies. Delete this later

#-------------------------------------------------------
# Sanity check
#-------------------------------------------------------
message ("#		sanity check - how many reads made it")
# Check how many reads made it through the pipeline
# This is good to report in your methods/results
getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN), sapply(mergers, getN), rowSums(seqtab), rowSums(seqtab.nochim))
colnames(track) <- c("input", "filtered", "denoised", "merged", "tabled", "nonchim")
rownames(track) <- sample.names
write.table(track, file="readsout.txt", sep="\t", col.names=NA, quote=F)

#-------------------------------------------------------
# Assign taxonomy
#-------------------------------------------------------
message ("#		assigning approximated taxonomy")
# NOTE: This is an APPROXIMATE taxonomy and may not be the best method for your data
# There are many ways/databases to assign taxonomy, we are only using one.

taxa <- assignTaxonomy(seqtab.nochim, taxpath, multithread=TRUE)
colnames(taxa) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus")

#get the taxonomy string
#merge columns 1 to 6 to get the full taxonomy (to genus)
un.tax <- unname(taxa)
tax.vector <- apply(un.tax, 1, function(x){paste(x[1:6], collapse=":")})

#add taxonomy to the table
seqtab.nochim.tax<-rbind(seqtab.nochim, tax.vector)

#transpose the table so samples are columns
t.seqtab.nochim.tax<-t(seqtab.nochim.tax)

#remove the rownames (SV sequences) to a separate table and replace with arbitrary SV (sequence variants) numbers
# NOTE: in this case that SVs are not the traditional "97% identical" sequence units (OTUs) since dada2 only collapses at 100%
sv.seqs<-rownames(t.seqtab.nochim.tax)
sv.num<-paste("SV", seq(from = 0, to = nrow(t.seqtab.nochim.tax)-1), sep="_")

rownames(t.seqtab.nochim.tax)<-sv.num

#get the tables!
# These are what you will use for all your downtream analysis
write.table(t.seqtab.nochim.tax, file="dada2_nochim_tax.txt", sep="\t", col.names=NA, quote=F)
write.table(sv.seqs, file="sv_seqs.txt", sep="\t", row.names=sv.num, col.names=F,  quote=F)
