# Gloor Lab dada2 pipeline for processing Illumina 16S reads

## Overview
This pipeline will take your paired fastq reads (from Illumina MiSeq or HiSeq) and generate an OTU counts table with an approximate taxonomy assignment. The reads have to have been generated using [Gloor Lab Illumina SOP](https://github.com/ggloor/miseq_bin/blob/dada2/Illumina_SOP.pdf) so that the reads are paired, overlapping, and contain the barcode and primer information (have not been demultiplexed or had primers or barcodes removed).

This is a replacement workflow for the old scripts `workflow.sh`. The overlapping and OTU generation is now completed by [dada2](https://github.com/benjjneb/dada2) (scroll down to see the readme) rather than pandaseq + USEARCH.

This pipeline was modified from the [dada2 tutorial for Illumina reads](http://benjjneb.github.io/dada2/tutorial.html). There are some examples on this page on how to interpret the QC plots and how to choose parameters.

### Getting your data from LRGC

- All Illumina MiSeq/NextSeq runs are posted to BaseSpace. You need an account to view your run (speak to David Carter)
- BaseSpace gives you a quality report on your run - you should have a look

If you are woking on cjelli (server), make sure you have an account and a working directory (see below)
 _* See Jean or Greg if you need an account and a working dir_

The file to download will be several Gb. Download to your machine and copy to cjelli (if you have enough bandwidth)
 or come into the Gloor lab to download directly to cjelli


### Setup your working directory
 All projects on cjelli are located on `/Volumes/longlunch/seq/LRGC/YourUserName`

1. Make a directory for your current study/run (usually named by your study name) - **THIS IS YOUR WORKING DIRECTORY**
  - Example working directory: `/Volumes/longlunch/seq/LRGC/jean/study1`
    >- _If you do not have a working dir on cjelli in /Groups/LRGC/ then ASK._
    >- _DO NOT use someone else's working directory, or put data in your home directory_
2. Make sure you have in your working directory:
  3. A copy of `dada2_workflow.R`
    - This will be the version you will modify for your own data
    - **IMPORTANT!** Make sure your code is clean and commented. This script is needed to write up your methods or to replicate your data analysis
  4. A `reads` directory containing your downloaded fastq reads (see below)
  5. A `samples.txt` file outlining your samples and barcodes you used for amplifications (see below for format)

##### Reads
 To unzip your Illumina reads file, use the command line:

		7z e filename.gz.tar
		#(if you have 7zip installed)
				or
		gzip -d filename.fastq.gz

		#If you download from the Robarts dataserver
		#move the .gz files into reads/
		gunzip *.gz

##### samples.txt
  - The format is tab-delimited, plain text, Unicode UTF-8. and UNIX line feeds (see the samples.txt in [example_files](https://github.com/ggloor/miseq_bin/blob/dada2/example_files/samples.txt))
 The headers will not change:

| BC\_L | BC\_R | sample | Lpri | Rpri | Group |
| :-----|:------|:--------|:------|:------|:-------|
| ccttggaa | ccaaggtt | sample_1 | V4L5 | V5R1 | vaginal_study |

- **BC\_L** - the barcode sequence of your left primer
- **BC\_R** - the barcode sequence of your right primer
- **sample** - the name of your sample (You must have unique sample names for every barcode set). **DO NOT USE DASHES IN YOUR SAMPLE NAMES**. Only lower/upper alphabet characters (`a to z`, and `A to Z`), numerics (`0 to 9`), or underscore `_`
- **Lpri** - the name of the left primer
- **Rpri** - the name of the right primer
- **Group** - which study the sample belongs to


### Setup your scripts and paths

##### On cjelli
If you are running this pipeline on cjelli, the programs are already installed and the scripts you need are already available in `/Volumes/data/longlunch/seq/LRGC/miseq_bin`
**DO NOT MAKE MORE COPIES**

##### On your own machine
If you are running on your own machine, you will need to download this entire github repository and ensure your paths in `dada2_workflow.R` point to the correct place to run the scripts. _Note: You will likely not be able to run this pipeline on a laptop due to memory/cpu requirements_

You will also need to install
- [dada2 for R](https://github.com/benjjneb/dada2)
- ShortRead for R

You will need to download
- The Silva non-redundant training set e.g. `silva_nr_v123_train_set.fa.gz`

>##### _Some things to keep in mind_
>- Do not make multiple copies of the scripts, your reads, etc. We have limited disk space and will delete as necessary
>- Do not rename original files (e.g. reads) because we won't be able to tell where they originated from


### Running the pipeline

##### Step 1: Demultiplex the samples (BASH shell)
- You need to be IN your working directory, your reads should be in `reads`, and your `samples.txt` should be in your working directory
- Make sure you use the correct name for the primer set you used e.g. `V4EMB`. See the list of available primers [here](https://github.com/ggloor/miseq_bin/blob/dada2/primer_sequences.txt)

````
$BIN=/Volumes/longlunch/seq/LRGC/miseq_bin

BIN/demultiplex_dada2.pl samples.txt reads/R1_001.fastq reads/R2_001.fastq V4EMB

#Change the names of R1_001.fastq and R2_001.fastq to match your file names - do not change your actual file names
````
###### Output:
You will have a forward and reverse fastq per sample/barcode in a directory called `demultiplex_reads`, and a file called key_file.txt. Sequence files will be named `sampleID-LBarcode-RBarcode-R1.fastq`

##### Step 2: Run the dada2 workflow (in R)
You should have have a working copy of `dada2_workflow.R` where you have made the necessary changes to match your data.

The first time you run the pipeline you may want to do so "line-by-line" (i.e. copy and paste each line to execute) to ensure each step completes before going to the next step.

>##### _A note about taxonomy assignment_
>The script includes a default method of taxonomy assignment (using the SILVA database) **BUT YOU SHOULD CONSIDER THIS ONLY AN APPROXIMATE OR "ROUGH ESTIMATE" OF TAXONOMY**. This may not be the ideal database to get the best taxonomy assignment for your data. You may want to re-assign your taxonomy at a different point.

See notes about assigning taxonomy with dada2 here:
https://benjjneb.github.io/dada2/assign.html

### Output
The main output you will use for downstream analysis are:
- OTU counts table with taxonomic assignments (e.g.)
- OTU sequence lookup table (e.g.)

### Cleanup
PLEASE cleanup files you don't need after running the workflow and completing your analysis. **IT WILL OTHERWISE BE REMOVED AT SOME LATER TIME POINT WITHOUT WARNING AND WE ARE NOT RESPONSIBLE FOR LOST DATA.** This is a shared server....we can't keep everything forever

---
#### Common problems
- All files (samples.txt, otu_table, etc.) must be UTF-8 with Unix newline characters. It should be tab-delimited
- Check that your paths are correct! If you don't understand relative and absolute paths...get help!
- Use only the following characters to name your samples, table headers, and directories:
	- a-z, A-Z, 0-9, and _ (underscore). **DO NOT USE DASHES IN YOUR SAMPLE NAMES**
	- Avoid brackets and spaces in naming

#### Questions to consider
- Do you know what primers you used? Which variable region(s) do they span?
- What is an OTU? What does your OTU seed sequence represent?
- What database should you use to assign taxonomy? What threshold? Do you trust it?
- What is your hypothesis? What are you trying to compare/ask/examine?
- Do you have enough samples to test your hypotheses? Do you trust your data?
	- Think about: how variable are my data? Does what I see make sense based on what I know about the biological system?

## Authors
- [**Greg Gloor**](https://github.com/ggloor) constructed the initial data2 workflow
- [**Jean Macklaim**](https://github.com/mmacklai) compiled the documentation and cleaned up the code

### Resources
dada2 tutorial:
http://benjjneb.github.io/dada2/tutorial.html

Taxonomy assignment and databases for dada2:
https://benjjneb.github.io/dada2/assign.html

Another tutorial by J. Bisanz
https://jbisanz.github.io/BMS270_BMI219/
