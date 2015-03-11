name=$1 #name to prepend to data and analysis directories
cluster=$2 #cluster percentage
primer=$3 #primer sequence, see bin/primer_seqs.txt for a list of primers
CLEAN=$4 #optional flag to empty directories and start again

#check for proper inputs
echo ${1?Error \$1 is not defined. flag 1 should contain the experiment name from samples.txt}
echo ${2?Error \$2 is not defined. flag 2 should contain the clustering proportion: almost always 0.97}
echo ${3?Error \$3 is not defined. flag 3 should contain the primer name from bin/primer_seqs.txt. eg. V4EMB}

#
# overlap the fastq files
# pandaseq -f Gloor1-3_S1_L001_R1_001.fastq -r Gloor1-3_S1_L001_R2_001.fastq -g ps_log.junk.txt -F -N -w reads/overlapped.fastq  -T 2

# where is the bin folder?
BIN="/Users/ggloor/git/miseq_bin/"
if [[ ! -e $BIN ]]; then
	echo "please provide a valid path to the bin folder"
fi

rekeyedtabbedfile=data_$name/rekeyed_tab_file.txt
groups_file=data_$name/groups.txt
reads_in_groups_file=data_$name/reads_in_groups.txt
groups_fa_file=data_$name/groups.fa
c95file=data_$name/results.uc
mappedfile=data_$name/mapped_otu_isu_reads.txt

### these are the mothur and silva locations
MOTHUR="/Users/ggloor/Documents/Custom_microbiota/mothur/mothur"
TEMPLATE="/Users/ggloor/Documents/Custom_microbiota/mothur/Silva.nr_v119/silva.nr_v119.align"
TAXONOMY="/Users/ggloor/Documents/Custom_microbiota/mothur/Silva.nr_v119/silva.nr_v119.tax"

if [[ ! -e $MOTHUR ]]; then
	echo "please provide a valid path to the mothur executable"
elif [[ ! -e $TEMPLATE ]]; then
	echo "please provide a valid path to the silva database"
fi

if [ $CLEAN = "clean" ]; then
	echo "cleaning up for a re-run"
	rm -R data_name
	rm -R analysis_name
fi

if [ -d data_$name ]; then
	echo "data directory exists"
else 
	echo "data directory was created"
	mkdir data_$name
fi 

# bash check if directory structure is correct
if [ -d analysis_$name ]; then
	echo "analysis directory exists"
else 
	echo "analysis directory was created"
	mkdir analysis_$name
fi 

# ensure the overlapped.fastq ps exists
if [[ ! -e reads/overlapped.fastq ]]; then
    echo "please overlap your reads. For V4 use pandaseq as follows:"
    echo "pandaseq -f forward.fastq -r reverse.fastq -g ps_log.junk.txt -F -N -w reads/overlapped.fastq  -T 2"
fi

# make the rekeyed-tab file from the overlapped fastq ps file
if [[ ! -e $rekeyedtabbedfile ]]; then
    echo "making $rekeyedtabbedfile"
    $BIN/process_miseq_reads.pl $BIN samples.txt reads/overlapped.fastq $primer 8 0 $name T > $rekeyedtabbedfile
fi

#making the ISU groups
if [[ -e $groups_fa_file ]]; then
	echo "final groups already made"
	echo "final dataset already made, data in: $c95file, $mappedfile"
elif [ ! -e data_$name/groups.txt ]
	then
	echo "making ISU groups, data in: groups.txt, reads_in_groups.txt"
	$BIN/group_gt1.pl $rekeyedtabbedfile $name 
	echo "making fasta file. data in: groups.fa"
	awk '{print$1 "\n"  $2}' $groups_file > $groups_fa_file
	#####NEW
	echo "final groups made. data in: groups.txt, reads_in_groups.txt, groups.fa, moving on to next steps"
fi

if [[ -e $c95file ]]; then
	echo "clustered already made, data in: $c95file"
else
	echo "clustering into OTUs at $cluster % ID"
	
	awk '{sub(/\|num\|/,";size=")}; 1' $groups_fa_file > data_$name/groups_uclust.fa
	$BIN/usearch7.0.1090_i86osx32 -cluster_otus data_$name/groups_uclust.fa -otu_radius_pct 3 -otus data_$name/clustered_otus_usearch.fa
	$BIN/usearch7.0.1090_i86osx32 -usearch_global $groups_fa_file -db data_$name/clustered_otus_usearch.fa -strand plus -id 0.97 -uc $c95file
	
	echo "clustering done data in: $c95file, moving on to next steps"
fi

if [ ! -e $mappedfile ]; then
	echo "mapping ISU, OTU information back to reads"
	echo ""
	$BIN/map_otu_isu_read_us7.pl $c95file $reads_in_groups_file $rekeyedtabbedfile > $mappedfile
	echo "final dataset made, data in: $mappedfile. Singleton reads not kept"
	echo ""
	echo "now cleaning up intermediate files"
	echo "removing:  groups.txt"
	echo "leaving: reads_in_groups.txt, groups.fa, $c95file, $mappedfile $finaltabbedfile $overlapped_startfile"
	rm   $groups_file
fi

if [[ ! -e analysis_$name/OTU_seed_seqs.fa ]]; then
	#the program identifies the OTUs or ISUs that are present in any of the samples at over 1% abundance
	#these common OTUs are identified in the table
	CUTOFF=0.1
	echo ""
	echo "attaching read counts to sequence tag pairs with a $CUTOFF % abundance cutoff in any sample"
	$BIN/get_tag_pair_counts_ps.pl $mappedfile $CUTOFF $name
	echo "tag pair read counts in analysis_$name/ISU_tag_mapped.txt and analysis_$name/OTU_tag_mapped.txt"
	echo ""
	echo "to use a different cutoff run the following command:"
	echo "$BIN/get_tag_pair_counts.pl $mappedfile 1"
	echo "and change the 1 to your preferred abundance cutoff in percentage" 
	
	echo "getting the seed OTU sequences"
	$BIN/get_seed_otus_uc7.pl $c95file $groups_fa_file analysis_$name/OTU_tag_mapped.txt > analysis_$name/OTU_seed_seqs.fa
	Rscript $BIN/OTU_to_QIIME.R analysis_$name
	echo "assigning taxonomy to $name"

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

### this is for mothur classify.seqs and the silva database, which is much better
	echo "adding silva taxonomy using mothur"
	echo "this can take some time if the database is not initialized so be patient"

	TAX_FILE=*.taxonomy

	$MOTHUR "#classify.seqs(fasta=analysis_$name/OTU_seed_seqs.fa, template=$TEMPLATE, taxonomy=$TAXONOMY, cutoff=70, probs=T, outputdir=analysis_$name, processors=4)"
	$BIN/add_taxonomy_mothur.pl $TAX_FILE analysis_$name/td_OTU_tag_mapped.txt > analysis_$name/td_OTU_tag_mapped_lineage.txt

elif [[ -e  analysis_$name/OTU_seed_seqs.fa ]]; then
	echo "final analysis already done"
fi

echo "end of pipeline.sh"
exit 1

