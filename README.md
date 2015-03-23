	Mar 2015
	Working doc by Jean Macklaim
	This is a working document. There are no guarantees that the instructions will be accurate
	or current, but efforts are made to do so

**Important note**

ALWAYS ALWAYS ALWAYS look at your data - does it make sense?

# Where do I get the scripts I need?

1) If running from your own computer, get the current workflow and projects from GitHub
	
	https://github.com/ggloor/miseq_bin
	
_**There are multiple BRANCHES (versions) of the script. This document corresponds to
		the "Jean" branch**_
	
	https://github.com/ggloor/miseq_bin/tree/Jean

2) If you are running on the Gloor lab server (cjelli), the scripts are located in:
	
	/Volumes/longlunch/seq/LRGC/miseq_bin
	
To use this document, download workflow.sh from the Jean branch (miseq_bin is already on cjelli)

 This document will describe the process for working on cjelli

# Getting your data from LRGC

 All MiSeq runs are posted to BaseSpace. You need an account to view your run - speak to David Carter
 BaseSpace gives you a quality report on your run - you should have a look
 All runs should be shared via BaseSpace with Dr. G. Gloor - (especially if you want his help)

 If you are woking on cjelli (server), make sure you have an account and a working directory (see below)
		* See Jean or Greg if you need an account and a working dir

 The file to download will be several Gb. Download to your machine and copy to cjelli (if you have enough bandwidth)
	or come into the Gloor lab to download directly to cjelli

# Setup your directory
 All projects are located on /Volumes/longlunch/seq/LRGC/YourUserName
 2) Make a directory for your current study/run (usually named by your study name) - THIS IS YOUR WORKING DIRECTORY
 3) Make a copy of workflow.sh in your working directory (from miseq_bin on the Jean GitHub branch)


_**If you do not have a working dir on cjelli in /Groups/LRGC/ then ASK.
DO NOT use someone else's working directory, or put data in your home directory**_

Example working directory:

	/Volumes/longlunch/seq/LRGC/jean/study1

 Make a "reads" directory in your working dir and dump your compressed FASTQ file(s) from the MiSeq
 To unzip your Illumina reads file, use the command line:

	7z e filename.gz.tar
	(if you have 7zip installed)
			or
	gzip -d filename.fastq.gz


Make samples.txt file
You need a samples.txt file in your working directory outlining the samples and primers/barcodes on the run.
 The format is tab-delimited, plain text, Unicode UTF-8. and UNIX line feeds
(see the samples.txt in example_files)
 The headers will not change:

| BC\_L | BC\_R | sample | Lpri | RPri | Group |
| :-----|:------|:--------|:------|:------|:-------|
| ccttggaa | ccaaggtt | sample1 | V4L5 | V5R1 | vaginal_study1 |

+ BC\_L = the barcode sequence of your left primer
+ BC\_R = the barcode sequence of your right primer
+ sample = the name of your sample
+ Lpri = the name of the left primer
+ Rpri = the name of the right primer
+ Group = which study the sample belongs to (*note: you will get separate output for each study under Group)

Ensure the primers you've used are in the miseq\_bin/primers.txt file **_Most experiments use the V4EMB primer set_**

# Define your paths and install dependent programs

 Open your copy of workflow.sh and look for the defined paths at the top of the script
 Ensure these paths are correct before you start. If you are on cjelli, the paths are already set

 If you are on cjelli, all needed programs are installed. If you are using your own
	computer, you need to install

panadaseq: https://github.com/neufeld/pandaseq

Usearch7: http://www.drive5.com/usearch/download.html

mothur: http://www.mothur.org/

 And you will need to download the SILVA database (formatted for mothur)
	http://www.mothur.org/wiki/Taxonomy_outline

# Overlap your paired reads
_For V6 reads you need to use Xorro, otherwise the current protocol uses Panadaseq_

##Pandaseq
 Do this in your reads directory where the read files are

	pandaseq -g pandaseq_log.txt -T 8 -f Burton3_S1_L001_R1_001.fastq -r Burton3_S1_L001_R2_001.fastq -o 30 -w ps_overlapped30.fastq -F &

 Output: **ps_overlapped30.fastq** is the output FASTQ with your overlapped reads. This will be used for all downstream processes
 We are using a minimum overlap of 30nt (this is appropriate for a typical V4 run)

#Run workflow.sh
This is the main script to cluster your OTUs and generate the OTU table
###to run:
	./workflow.sh <name> <percent ID to cluster in decimal> <primer> <path to overlapped reads> clean

e.g.
	`./workflow.sh MyStudyName 0.97 V4EMB path_to/ps_overlapped30.fastq clean`

_Note that you must do this from your working directory_

+ name must match the study name used in the samples.txt file under Group
+ Variable regions/primer options available: V6, V4, 28S V9, V9b, V4, V4EMB
+ MOST of the time you will be using V4EMB (ask if unsure)
+ "clean" will delete ALL output directories from a previous run of workflow.sh

##Output from workflow.sh
Three output directories will be created:

	analysis_STUDYNAME
	data_STUDYNAME
	taxonomy_STUDYNAME

 *Asterisked files are used in downstream analysis. These are the files you should look at

_Most files are TOO LARGE to try to open. Use head, tail, more on command line. Your OTU tables can be opened in a text processor (TextWrangler, Sublime, Notepad++) or in Excel_

#####analysis_STUDYNAME
- ISU\_tag\_mapped.txt	-	Table of identical sequence units (clusters at 100% ID, rows) demultiplexed and assigned per sample (column)
- *OTU\_seed\_seqs.fa	-	Your representative seed sequence per OTU cluster
- OTU\_tag\_mapped.txt	-	Your initial OTU table. Samples are column headers, OTU numbers (arbitrary) are rows. Ordered from most abundant OTU to least across all samples
- OTU\_to\_QIIME.out	- 	Output from R transposition of OTU table (errors will be here)
- *td\_OTU\_tag_mapped.txt	Your QIIME-formatted OTU table before adding taxonomy

#####data_STUDYNAME
_*This directory can be deleted after analysis is complete_

- clustered\_otus\_usearch.fa	- Uclust output
- groups.fa					- Uclust output
- groups\_uclust.fa			- Uclust output
- mapped\_otu\_isu_reads.txt		- 
- reads\_in\_groups.txt			
- !rekeyed\_tab\_file.txt		- tab-delimited file of your demultiplexed reads. Used for combining samples from different MiSeq runs
- results.uc				- Uclust output

_!rekeyed\_tab\_file.txt - these files are concatenated if you are combining more than one run for a study_

#####taxonomy_STUDYNAME
- OTU\_seed\_seqs.nr\_v119.wang.flip.accnos
- OTU\_seed\_seqs.nr\_v119.wang.tax.summary
- OTU\_seed\_seqs.nr\_v119.wang.taxonomy	- The taxonomy assigned with the bootstrap confidence listed
- mothur.1426205752.logfile
- *td\_OTU\_tag\_mapped\_lineage.txt		- Your OTU table with the added taxonomy (lineage)

**_A note on taxonomy_**
The pipeline automates ONE type of taxonomic assignment. There are many options for annotation and you should consider carefully which database and which method to use
 You are assigning taxonomy to your OTU seed sequences - NOT all the sequences in that OTU cluster


 This uses the mothur classify.seqs script against the SILVA database
 The method=Wang is the SAME method as RDP. We are using a 70% bootstrapping cutoff
 For more information: http://www.mothur.org/wiki/Classify.seqs


# Now what?
QIIME and R can be used for exploratory analysis. ALDEx2 can be used for differential analysis

See the qiime\_and\_plotting directory for example workflows


# Common problems
- All files (samples.txt, otu_table, etc.) must be UTF-8 with Unix newline characters. It should be tab-delimited
- Check that your paths are correct! If you don't understand relative and absolute paths get help!
- Use only the following characters to name your samples, table headers, and directories:
	- a-z, A-Z, 0-9, and _ (underscore)
	- Avoid brackets and spaces in naming

# Questions to consider
- Do you know what primers you used? Which variable region(s) do they span?
- What is an OTU? What does your OTU seed sequence represent?
- What database should you use to assign annotations? What threshold? Do you trust it?
- What is your hypothesis? What are you trying to compare/ask/examine?
- Do you have enough samples to test your hypotheses? Do you trust your data?
	- Think about: how variable are my data? Does what I see make sense based on what I know about the biological system?
