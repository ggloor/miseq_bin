#-----------------------------------------------------------------------------------------
# Jean's version
# Updated: 12-Mar-2015
#---------------
# Directory structure:
#	reads = made by user. Put uncompressed reads and pandaseq overlap here
#	data_STUDY = output from workflow. Can be deleted once happy with analysis output
#	analysis_STUDY = output from workflow, contains OTU table
#	taxonomy_STUDY = output from workflow, contains taxonomy assignment and OTU table with tax (lineage) 
#---------------
# Running
# ./workflow.sh STUDY 0.97 V4EMB reads/overlapped.fastq clean
#	# STUDY MUST MATCH EXACTLY to the samples.txt Groups col
#-----------------------------------------------------------------------------------------
#### User must change the following if needed ####

# File paths to mothur, and the SILVA database (all pre-installed by user)
MOTHUR="/Volumes/longlunch/seq/annotationDB/mothur/mothur"
TEMPLATE="/Volumes/longlunch/seq/annotationDB/mothur/Silva.nr_v119/silva.nr_v119.align"
TAXONOMY="/Volumes/longlunch/seq/annotationDB/mothur/Silva.nr_v119/silva.nr_v119.tax"

# File path to the miseq_bin folder
BIN="/Volumes/longlunch/seq/LRGC/miseq_bin/"
# Path to pre-installed programs on cjelli
#usearch
BIN2="/Volumes/longlunch/seq/LRGC/bin/"

#### Do not alter any code byond this point ####

#-----------------------------------------------------------------------------------------
# Inputs for running the script
#-----------------------------------------------------------------------------------------

name=$1 #name to prepend to data and analysis directories
cluster=$2 #cluster percentage
primer=$3 #primer sequence, see bin/primer_seqs.txt for a list of primers
pandaseq_file=$4 #path to pandaseq file. This should be run before using the workflow
CLEAN=$5 #optional flag to empty directories and start again (will remove both the data and analysis dirs)

#check for proper inputs
echo ${1?Error \$1 is not defined. flag 1 should contain the experiment name from samples.txt}
echo ${2?Error \$2 is not defined. flag 2 should contain the clustering proportion: almost always 0.97}
echo ${3?Error \$3 is not defined. flag 3 should contain the primer name from bin/primer_seqs.txt. eg. V4EMB}
echo ${4?Error \$4 is not defined. flag 4 should contain the path to the pandaseq overlapped file}

#-----------------------------------------------------------------------------------------
# Check that the file paths are valid, that the panadaseq overlapped file exists,
#	and that the study NAME exists in samples.txt
#-----------------------------------------------------------------------------------------
if [[ ! -e $BIN ]] 
then
	echo "please provide a valid path to the bin folder in workflow.sh"
	exit
fi
if [[ ! -e $MOTHUR ]] 
then
	echo "please provide a valid path to the mothur executable in workflow.sh"
	exit
fi
if [[ ! -e $TEMPLATE ]] 
then
	echo "please provide a valid path to the SILVA template file in workflow.sh"
	exit
fi
if [[ ! -e $TAXONOMY ]] 
then
	echo "please provide a valid path to the SILVA taxonomy file in workflow.sh"
	exit
fi

# Ensure the pandaseq overlapped file is available
if [[ ! -s $pandaseq_file ]]; then
    echo "please overlap your reads. For V4 use pandaseq as follows:"
    echo "pandaseq -f forward.fastq -r reverse.fastq -g ps_log.txt -F -N -w reads/ps_overlapped.fastq  -T 2"
    exit
fi

# Check that the given study name exists in the samples.txt file
# Should be separated by tab, and at the end of the line
FILE=samples.txt
if grep -q "\t$name$" $FILE;
then
	echo "Study name found"
else
     echo -e "\tError: can't find your study name in samples.txt"
     echo -e "\tMake sure file is tab-delimited, UNIX linefeeds"
     exit

fi
COUNT=$(grep -c -U $'\012' $FILE )

if [ $COUNT -eq 0 ] ; then
	echo "WARNING: Your samples.txt file may not have UNIX end of lines"
elif [ $COUNT -gt 0 ] ; then
	echo "samples.txt looks OK"
fi

#MAC: '\015\'
#DOS: '\015\012'

#-----------------------------------------------------------------------------------------
# Setup variables for output file names
#-----------------------------------------------------------------------------------------

rekeyedtabbedfile=data_$name/rekeyed_tab_file.txt
groups_file=data_$name/groups.txt
reads_in_groups_file=data_$name/reads_in_groups.txt
groups_fa_file=data_$name/groups.fa
uc_out=data_$name/results.uc
mappedfile=data_$name/mapped_otu_isu_reads.txt

# Remove ALL output from a previous run
if [ $CLEAN = "clean" ]; then
	echo "cleaning up for a re-run"
	rm -R data_$name
	rm -R analysis_$name
	rm -R taxonomy_$name
fi

#-----------------------------------------------------------------------------------------
# Create output directories
#-----------------------------------------------------------------------------------------

if [ -d data_$name ]; then
	echo "data directory exists"
else 
	echo "data directory was created"
	mkdir data_$name
fi 

if [ -d analysis_$name ]; then
	echo "analysis directory exists"
else 
	echo "analysis directory was created"
	mkdir analysis_$name
fi 

if [ -d taxonomy_$name ]; then
	echo "taxonomy directory exists"
else 
	echo "taxonomy directory was created"
	mkdir taxonomy_$name
fi 
#-----------------------------------------------------------------------------------------
# Make the rekeyed-tab file from the overlapped fastq ps file
if [[ ! -e $rekeyedtabbedfile ]]; then
    echo "making $rekeyedtabbedfile"
    $BIN/process_miseq_reads.pl $BIN samples.txt $pandaseq_file $primer 8 0 $name T > $rekeyedtabbedfile
fi

# Making the ISU groups
if [[ -e $groups_fa_file ]]; then
	echo "final groups already made"
	echo "final dataset already made, data in: $uc_out, $mappedfile"
elif [ ! -e data_$name/groups.txt ]
	then
	echo "making ISU groups, data in: groups.txt, reads_in_groups.txt"
	$BIN/group_gt1.pl $rekeyedtabbedfile $name 
	echo "making fasta file. data in: groups.fa"
	awk '{print$1 "\n"  $2}' $groups_file > $groups_fa_file
	#####NEW
	echo "final groups made. data in: groups.txt, reads_in_groups.txt, groups.fa, moving on to next steps"
fi

if [[ -e $uc_out ]]; then
	echo "clustered already made, data in: $uc_out"
else
	echo "clustering into OTUs at $cluster % ID"
	
	awk '{sub(/\|num\|/,";size=")}; 1' $groups_fa_file > data_$name/groups_uclust.fa
	$BIN2/usearch7.0.1090_i86osx32 -cluster_otus data_$name/groups_uclust.fa -otu_radius_pct 3 -otus data_$name/clustered_otus_usearch.fa
	$BIN2/usearch7.0.1090_i86osx32 -usearch_global $groups_fa_file -db data_$name/clustered_otus_usearch.fa -strand plus -id 0.97 -uc $uc_out
	
	echo "clustering done data in: $uc_out, moving on to next steps"
fi

if [ ! -e $mappedfile ]; then
	echo "mapping ISU, OTU information back to reads"
	echo ""
	$BIN/map_otu_isu_read_us7.pl $uc_out $reads_in_groups_file $rekeyedtabbedfile > $mappedfile
	echo "final dataset made, data in: $mappedfile. Singleton reads not kept"
	echo ""
	echo "now cleaning up intermediate files"
	echo "removing:  groups.txt"
	echo "leaving: reads_in_groups.txt, groups.fa, $uc_out, $mappedfile $finaltabbedfile $overlapped_startfile"
	rm   $groups_file
fi

if [[ ! -e analysis_$name/OTU_seed_seqs.fa ]]; then
	#the program identifies the OTUs or ISUs that are present in any of the samples at over 1% abundance
	#these common OTUs are identified in the table
	CUTOFF=1
	echo ""
	echo "attaching read counts to sequence tag pairs with a $CUTOFF % abundance cutoff in any sample"
	$BIN/get_tag_pair_counts_ps.pl $mappedfile $CUTOFF $name
	echo "tag pair read counts in analysis_$name/ISU_tag_mapped.txt and analysis_$name/OTU_tag_mapped.txt"
	echo ""
	echo "to use a different cutoff run the following command:"
	echo "$BIN/get_tag_pair_counts.pl $mappedfile 1"
	echo "and change the 1 to your preferred abundance cutoff in percentage" 
	
	echo "getting the seed OTU sequences"
	$BIN/get_seed_otus_uc7.pl $uc_out $groups_fa_file analysis_$name/OTU_tag_mapped.txt > analysis_$name/OTU_seed_seqs.fa
	Rscript $BIN/OTU_to_QIIME.R analysis_$name

#-----------------------------------------------------------------------------------------
# Assign taxonomy using RDP seqmatch. Typically overcalls compared to SILVA (preferred method)
#-----------------------------------------------------------------------------------------

### this is for RDP seqmatch, which we know is not very good
#	RDP="/Volumes/MBQC/MBQC"
#	java -jar $RDP/RDPTools/SequenceMatch.jar seqmatch -k 50 greengenes/seqmatch99/ analysis_$name/OTU_seed_seqs.fa > analysis_$name/seqmatch_out.txt
#    $BIN/annotate_OTUs.pl $RDP/greengenes/gg_13_5_taxonomy.txt analysis_$name/seqmatch_out.txt > analysis_$name/parsed_GG.txt
#    
#    $BIN/add_taxonomy.pl analysis_$name parsed_GG.txt td_OTU_tag_mapped.txt > analysis_$name/td_OTU_tag_mapped_lineage.txt
#
#    java -jar $RDP/RDPTools/SequenceMatch.jar seqmatch -k 50 greengenes/seqmatch97/ analysis_$name/OTU_seed_seqs.fa > analysis_$name/seqmatch97_out.txt
#    $BIN/annotate_OTUs.pl $RDP/greengenes/gg_13_5_taxonomy.txt analysis_$name/seqmatch97_out.txt > analysis_$name/parsed97_GG.txt
#    $BIN/add_taxonomy.pl analysis_$name parsed97_GG.txt td_OTU_tag_mapped.txt > analysis_$name/td_OTU_tag_mapped_lineage97.txt
#
#	Rscript $BIN/OTU_to_QIIME.R analysis_$name
#    java -jar RDPTools/SequenceMatch.jar seqmatch -k 50 greengenes/v4_gg_13_5/ analysis_$name/OTU_seed_seqs.fa > analysis_$name/seqmatch_v4_97_out.txt
#    $BIN/annotate_OTUs.pl greengenes/gg_13_5_taxonomy.txt analysis_$name/seqmatch_v4_97_out.txt > analysis_$name/parsed_v4_97_GG.txt
#    $BIN/add_taxonomy.pl analysis_$name parsed_v4_97_GG.txt td_OTU_tag_mapped.txt > analysis_$name/td_OTU_tag_mapped_lineage_v4_97.txt


elif [[ -e  analysis_$name/OTU_seed_seqs.fa ]]; then
	echo "final analysis already done"
fi
#-----------------------------------------------------------------------------------------
# Assign taxonomy using mothur classify.seqs and the SILVA database
#-----------------------------------------------------------------------------------------

#if this file exists and is not empty, add taxonomy from SILVA
if [[ ! -s analysis_$name/td_OTU_tag_mapped_lineage.txt ]]; then
	echo "assigning taxonomy to $name"

# This uses the mothur classify.seqs script against the SILVA database
# The method=Wang is the SAME method as RDP
# For more information: http://www.mothur.org/wiki/Classify.seqs

	echo "adding silva taxonomy using mothur"
	echo "this can take some time if the database is not initialized so be patient"

	TAX_FILE=taxonomy_$name/*.taxonomy

	$MOTHUR "#classify.seqs(fasta=analysis_$name/OTU_seed_seqs.fa, template=$TEMPLATE, taxonomy=$TAXONOMY, cutoff=70, probs=T, outputdir=taxonomy_$name, processors=4)"
	$BIN/add_taxonomy_mothur.pl $TAX_FILE analysis_$name/td_OTU_tag_mapped.txt > taxonomy_$name/td_OTU_tag_mapped_lineage.txt

fi

echo "end of pipeline.sh"
exit 1

