# Updated: 18-Oct-2017
# This script is modified by JM from GG's original based on the dada2 tutorial found here:
#http://benjjneb.github.io/dada2/tutorial.html

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

### Old method
# Sort ensures forward/reverse reads are in same order
#fnFs1 <- sort(list.files(reads, pattern="-R1.fastq"))
#fnRs2 <- sort(list.files(reads, pattern="-R2.fastq"))
# Extract sample names, assuming filenames have format: SAMPLENAME-XXX.fastq
#sample.names <- sapply(strsplit(fnFs1, "-"), `[`, 1)
# Specify the full path to the fnFs and fnRs
#fnFs <- file.path(reads, fnFs1)
#fnRs <- file.path(reads, fnRs2)

#-------------------------------------------------------
# Test QC
#-------------------------------------------------------

# test QC see, dada2 tutorial
# Should change this to check other reads
pdf("qualprofiles.pdf")
plotQualityProfile(fnFs[[1]])
plotQualityProfile(fnRs[[1]])
dev.off()

#-------------------------------------------------------
# Filter reads based on QC
#-------------------------------------------------------
# Make filenames for the filtered fastq files
filtFs <- paste0(reads, "/", sample.names, "-F-filt.fastq.gz")
filtRs <- paste0(reads, "/", sample.names, "-R-filt.fastq.gz")

# the length must be equal to or shorter than the read!!
# that means 187 and 178 for V4 with paired 2x220 with 8 mer barcodes
# that means 183 and 174 for V4 with paired 2x220 with 12 mer barcodes
# DO NOT trim from the 5' end since primers and barcodes already trimmed off
for(i in seq_along(fnFs)) {
  filterAndTrim(c(fnFs[i], fnRs[i]), c(filtFs[i], filtRs[i]),
            truncLen=c(183,174),
            maxN=0,
            maxEE=(2,2),
            compress=TRUE, verbose=TRUE, multithread=TRUE)
}

#example parameters. For paired reads, used a vector (2,2)
	#truncQ=2, #truncate reads after a quality score of 2 or less
	#truncLen=130, #truncate after 130 bases
	#trimLeft=10, #remove 10 bases off the 5’ end of the sequence
	#maxN=0, #Don’t allow any Ns in sequence
	#maxEE=2, #A maximum number of expected errors
	#rm.phix=TRUE, #Remove lingering PhiX (control DNA used in sequencing) as it is likely there is some.
	# On Windows set multithread=FALSE

# filtered reads are output to demultiplex_reads

#----------------------------------------------------------------
# IF YOUR PROGRAM CRASHES YOU CAN USE THIS AS A CONTINUE POINT
# SKIP THIS otherwise and go straight to the next step
# as long as your filtered reads were output
# Use the commands below to lead the data, then go to the dereplication step
#---------------------------------------------------------------------------
###Load needed libraries and paths
#library(dada2)
#
#taxpath<-"/Volumes/longlunch/seq/annotationDB/dada2silva_nr_v123_train_set.fa.gz"
#reads<-"demultiplex_reads"
#
##get the filenames with relative path
##sort to ensure same order
#filtFs <- sort(list.files(reads, pattern="-F-filt.fastq.gz", full.names=TRUE))
#filtRs <- sort(list.files(reads, pattern="-R-filt.fastq.gz", full.names=TRUE))
##get sample names only (remove path, and everything after the first "-")
#sample.names <- sapply(strsplit(basename(filtFs), "-"), `[`, 1)
#-------------------------------------------------------
#-------------------------------------------------------
# Learn the error rates - SLOW !!
#-------------------------------------------------------
errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)

pdf("errF.pdf")
plotErrors(errF, nominalQ=TRUE)
dev.off()

#-------------------------------------------------------
# Dereplication
#-------------------------------------------------------
# Dereplication combines all identical sequencing reads into into “unique sequences” with a corresponding “abundance”: the number of reads with that unique sequence
# Dereplication substantially reduces computation time by eliminating redundant comparisons.

derepFs <- derepFastq(filtFs, verbose=TRUE)
derepRs <- derepFastq(filtRs, verbose=TRUE)
# Name the derep-class objects by the sample names
names(derepFs) <- sample.names
names(derepRs) <- sample.names

#-------------------------------------------------------
# Sample inference and merge paired reads
#-------------------------------------------------------
#Infer the sequence variants in each sample:

dadaFs <- dada(derepFs, err=errF, multithread=TRUE)
dadaRs <- dada(derepRs, err=errR, multithread=TRUE)

# overlap the ends of the forward and reverse reads
mergers <- mergePairs(dadaFs, derepFs, dadaRs, derepRs, verbose=TRUE)

# make the sequence table, samples are by rows
seqtab <- makeSequenceTable(mergers[names(mergers) != "Mock"])

# summarize the output by length
table(nchar(colnames(seqtab)))

# remove chimeras and save in seqtab.nochim
seqtab.nochim <- removeBimeraDenovo(seqtab, verbose=TRUE)

#let's write the table, just in case
#samples are rows
write.table(seqtab.nochim, file="dada2_nochim.txt", sep="\t", col.names=NA, quote=F)

# Check how many reads made it through the pipeline
getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN), sapply(mergers, getN), rowSums(seqtab), rowSums(seqtab.nochim))
colnames(track) <- c("input", "filtered", "denoised", "merged", "tabled", "nonchim")
rownames(track) <- sample.names
write.table(track, file="track.txt", sep="\t", col.names=NA, quote=F)

#-------------------------------------------------------
# Assign taxonomy
#-------------------------------------------------------
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

#remove the rownames (OTU sequences) to a separate table and replace with arbitrary OTU numbers
# NOTE: in this case that OTUs are not the traditional "97% identical" sequence units since dada2 only collapses at 100%
otu.seqs<-rownames(t.seqtab.nochim.tax)
otu.num<-paste("OTU", seq(from = 0, to = nrow(t.seqtab.nochim.tax)-1), sep="_")

rownames(t.seqtab.nochim.tax)<-otu.num

#get the tables!
# These are what you will use for all your downtream analysis
write.table(t.seqtab.nochim.tax, file="dada2_nochim_tax.txt", sep="\t", col.names=NA, quote=F)
write.table(otu.seqs, file="otu_seqs.txt", sep="\t", row.names=otu.num, col.names=F,  quote=F)
