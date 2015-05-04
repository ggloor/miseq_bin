This contains all the script files required to extract 16S rRNA gene sequencing reads from inline-barcoded primer sets. See the Illumina_SOP.pdf for amplification instructions and a short description of the software.


How to run these scripts

you need the following:
    - paired-end MiSeq run using a variable region primer set that overlaps
    - a samples.txt file that contains the following tab-delimeted. The last entry is the experiment name
    BC_L	BC_R	sample	Lpri	Rpri	Group
    ccaaggtt	ccaaggtt	Plate1_Extraction_Control	V4L1	V5R1	control

	- a directory for your analysis, this should contain your reads in a directory called reads
	- mothur installed
	- USEARCH v7 or later
	- maqiime installed
	- silva databases installed for OTU annotation
	- the bin folder
	
1) overlap your read files with pandaseq, and place them in a directory called reads.
    pandaseq -f forward.fastq -r reverse.fastq -g ps_log.junk.txt -F -N -w reads/overlapped.fastq  -T 2

2) The workflow.sh script calls the scripts and programs that that will take your overlapped reads and output a table of counts that can be put into qiime or mothur. Please read the Illumina_SOP.pdf file for what is happening.