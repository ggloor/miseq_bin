Jul 24 2017
Documentation for running the dada2 pipeline
- Greg Gloor constructed the initial data2 workflow
- Jean Macklaim compiled the documentation and cleaned up the code

### Overview
This pipeline will take your paired fastq reads (from Illumina MiSeq or HiSeq) and generate an OTU counts table with an approximate taxonomy assignment. The reads have to have been generated using Gloor Lab SOP to that the reads are paired, overlapping, and contain the barcode and primer information (have not been demultiplexed or had primers or barcodes removed).

This is a replacement workflow for the old scripts `workflow.sh`. The overlapping and OTU generation is now completed by [dada2](https://github.com/benjjneb/dada2) (scroll down to see the readme) rather than pandaseq + USEARCH.

This pipeline was modified from the [dada2 tutorial for Illumina reads](http://benjjneb.github.io/dada2/tutorial.html). There are some examples on this page on how to interpret the QC plots and how to choose parameters.

### Setup

**On cjelli**
If you are running this pipeline on cjelli, the programs are already installed and the scripts you need are already available in `/Volumes/data/longlunch/seq/LRGC/miseq_bin`

- You should have a working directory in `/Volumes/longlunch/seq/LRGC/your_working_dir`.
  - This is typically your sequencing run name or project name. If your working directory is your username, then add a new working directory inside for each run/project
  - **PLEASE ASK** if you need a working directory or need to download your data for the first time...Jean will get angry if you don't.
- Your fastq reads should be in a directory called `reads` inside your working directory
- You should have a working copy of `dada2_workflow.R` in your working directory (You will be running this script and modifying as needed)
  - **IMPORTANT!** Make sure your code is clean and commented. This script is needed to write up your methods or to replicate your data analysis
- You need a `samples.txt` table in your working directory. See [here]() for the format

**On your own machine**
If you are running on your own machine, you will need to download this entire github repository and ensure your paths in `dada2_workflow.sh` point to the correct place to run the scripts

You will also need to download or install
- 1
- 2
- 3
- The silva non-redundant training set e.g. `silva_nr_v123_train_set.fa.gz`

Note: You will likely not be able to run this pipeline on a laptop due to memory/cpu requirements

### Some things to keep in mind
- Do not make multiple copies of the scripts, your reads, etc. We have limited disk space and will delete as necessary
- Do not rename original files (e.g. reads) because we won't be able to tell where they originated from

### Running the pipeline

##### Step 1: Demultiplex the samples (BASH shell)
- You need to be IN your working directory, your reads should be in `reads`, and your `samples.txt` should be in your working directory
- Change the names of "R1_001" and "R2_001" to match your file names
  - DO NOT CHANGE THE NAMES OF THE FILES THEMSELVES
- Use the correct name for the primer set you used e.g. `V4EMB`

````
$BIN=/Volumes/longlunch/seq/LRGC/miseq_bin

BIN/demultiplex_dada2.pl samples.txt reads/R1_001.fastq reads/R2_001.fastq V4EMB
````
Output:

##### Step 2: Run the dada2 workflow (in R)
You should have have a working copy of `dada2_workflow.R` where you have made the necessary changes to match your data.

The first time you run the pipeline you may want to do so "line-by-line" (i.e. copy and paste each line to execute) to ensure each step completes before going to the next step.

##### A note about taxonomy assignment
The script includes a default method of taxonomy assingnment (using the SILVA database) **BUT YOU SHOULD CONSIDER THIS ONLY AN APPROXIMATE OR "ROUGH ESTIMATE" OF TAXONOMY**. This may not be the ideal database to get the best taxonomy assignment for your data. You may want to re-assign your taxonomy at a different point.

### Output
The main output you will use for downstream analysis are:
- OTU counts table with taxonomic assignments (e.g.)
- OTU sequence lookup table (e.g.)
-

### Cleanup
PLEASE cleanup files you don't need after running the workflow and completing your analysis. **IT WILL OTHERWISE BE REMOVED AT SOME LATER TIME POINT WITHOUT WARNING AND WE ARE NOT RESPONSIBLE FOR LOST DATA.** This is a shared server....we can't keep everything forever
