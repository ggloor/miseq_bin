#!/bin/bash

#######
# This software is Copyright 2013 Greg Gloor and is distributed under the 
#    terms of the GNU General Public License.
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#    along with this program. It should be located in gnu_license.txt
#    If not, see <http://www.gnu.org/licenses/>.
########
#DON'T EVEN THINK OF TRYING TO RUN THIS WITHOUT READING THROUGH THIS INITIAL INFORMATION
#if the program fails, throw the newly created files in the data and analysis directory away
########
##Prior to running workflow.sh you must edit lines 56 and 60 to include your version of uclust/usearch and the location of the Illumina_bin folder

##I assume you will use usearch version 6 or greater, if not you will need to edit lines 200 and 202 as appropriate

#this is the final pipeline
#
# to run it
#
#./workflow.sh name cluster% variable_region
#eg
#./workflow.sh 16s 0.97 V4 overlapped_reads clean 
#
#variable regions are: V6, V4, 28S V9, V9b, V4, V4EMB
##it will print a log of messages to STDOUT

##### MULTIPLE REQUIREMENTS ############
# 1 #
#
#Requires 2 input files:
#data_name/primers.txt -- A file that contains the sequences of the left and right end PCR primers
#               written 5' to 3'
#               Degenerate positions are indicated thusly [ACG]
#				the left primer is on line 1
#				the right primer is on line 2
#
#data_name/samples.txt --A file that contains the meta information
#
# 2 #
#requires USEARCH 7 and pandaseq 
#3#
#BIN folder location change this to reflect your bin folder that contains the scripts
BIN="/Groups/LRGC/miseq_bin/"
#
#
###### RECOMMENDED DIRECTORY STRUCTURE
#
# IF YOU WANT A DIFFERENT STRUCTURE, YOU MUST EDIT THIS SCRIPT YOURSELF
#
#programs in BIN
#data in data
#analysis in analysis
#reads in reads
#
#### END REQUIREMENTS ########

#GOT TO HERE AND UNDERSTAND THE REQUIREMENTS? GO AHEAD AND RUN IT!

######THE SCRIPT STARTS HERE###########

#command line variables
name=$1 #name to prepend to data and analysis directories
cluster=$2 #cluster percentage
VARREG=$3 #variable region
OL_READS=$4 #overlapped reads including directory
CLEAN=$5 #re-run and delete existing files
#################### FIRST GET THE PRIMER AND SEQUENCE TAG INFORMATION
#DATA STORED IN THE FOLLOWING VARIABLES
#Lp, Rp, rRp, VALIDTAGS

# bash check if directory structure is correct
if [ -d $BIN ]; then
	echo "BIN directory exists"
else 
	echo "BIN directory does not exist"
	echo "please try and re-install the analysis pipeline"
fi 
# bash check if directory structure is correct
if [ -d data_$name ]; then
	echo "data directory exists"
else 
	echo "data directory was created"
	echo "you must put the primers and samples file, here before proceeding"
	mkdir data_$name
	exit 1
fi 

# bash check if directory structure is correct
if [ -d analysis_$name ]; then
	echo "analysis directory exists"
	echo ""
else 
	echo "analysis directory was created"
	echo ""
	mkdir analysis_$name
fi 


#file names for the required data files, many of these will be deleted ultimately
overlapped_startfile=data_$name/start_overlapped_tab.txt
finaltabbedfile=data_$name/overlapped_tab.txt
rekeyedtabbedfile=data_$name/rekeyed_tab.txt

groups_file=data_$name/groups.txt
reads_in_groups_file=data_$name/reads_in_groups.txt
groups_fa_file=data_$name/groups.fa
c95file=data_$name/results.uc
mappedfile=data_$name/mapped_otu_isu_reads.txt

#if temprimers file does not exist
#create it
if [[ ! -e data_$name/temprimers ]]; then
	
	#first get the primers and assign them to the
	#variables Lp, Rp and rRp
	#reverse the primers and save in a tempfile
	cat data_$name/primers.txt > data_$name/temprimers
	rev < data_$name/primers.txt > data_$name/revtemp
	
	#now get the complement and append to temprimers
	tr "ACGT[]" "TGCA][" < data_$name/revtemp >> data_$name/temprimers
	
	#remove the unnecessary temp file
	rm data_$name/revtemp 
		
	#Declare array 
	declare -a ARRAY
	
	#Open file for reading to array
	#exec attaches a filehandle to the filename
	exec 10<data_$name/temprimers
		let count=0
		
		while read LINE <&10; do
			#echo $LINE $count
			ARRAY[$count]=$LINE
			((count++))
		done
		
		#get the number of elements in the array
		#echo Number of elements: ${#ARRAY[@]}
		Lp=${ARRAY[0]}
		Rp=${ARRAY[1]}
		rRp=${ARRAY[3]}
		# echo array's content
		#echo ${ARRAY[@]}
	# close file 
	exec 10>&-
	
	#remove the unnecessary temp file
	rm data_$name/temprimers 
	
	#get the list of valid tags
	$BIN/make_valid_tags.pl data_$name/samples.txt >  data_$name/valid_pairs.txt
	
	declare -a VALIDTAG
	exec 10<data_$name/valid_pairs.txt
	let count=0
	while read LINE <&10; do
		VALIDTAG[$count]=$LINE
		((count++))
	done
	exec 10>&-
fi

VALIDTAGS=${VALIDTAG[@]}

echo primer 1 is............$Lp
echo primer 2 is............$Rp
echo revcom of primer 2 is..$rRp
echo valid tag pairs are....$VALIDTAGS

######################### DONE GETTING THE PRIMER AND SEQUENCE TAG INFORMATION
echo DONE GETTING THE PRIMER AND SEQUENCE TAG INFORMATION

##########
#Overlap
#We have 2x250 paired end runs
#16S is ~250 bp, 18S is ~230 -260 bp
#so length range is up to 340 or so, so 235 as our length that overlaps the 18S fine, and the 
#second iteration will do most of the 16S
#~/bin/XORRO/xorro_wrapper.pl -i1 Thorn-48-2_S1_L001_R1_001.fastq -i2 Thorn-48-2_S1_L001_R2_001.fastq -f T -s 235 &
#XORRO did not work on run 2 as the reads were low quality, so use pandaseq - ran quickly
# pandaseq -g log.txt -T 8 -f Gloor-Ruth-240_S1_L001_R1_001.fastq -r Gloor-Ruth-240_S1_L001_R2_001.fastq -o 30 -w ps_overlapped30.fastq -F & 
#run 1 is overlap 1, run2 is overlap2 run3 is overlap 3
#
##########
#

#exit 1
if [ $CLEAN = "clean" ]; then
	echo "cleaning up for a re-run"
	rm $overlapped_startfile
	rm $groups_fa_file 
	rm $finaltabbedfile 
	rm $c95file
	rm $mappedfile
	rm $rekeyedtabbedfile
fi


if [[ -e $rekeyedtabbedfile ]]
	then
	echo "$overlapped_startfile already made, moving on"
elif [ ! -e $overlapped_startfile ]
	then
	#echo "concatenating both overlap files"
	#cat reads_1/overlap.fastq reads_2/overlap.fastq > reads_all/overlap.fastq
	echo "making starting tabbed file"
	$BIN/fastq_to_tab_XOR.pl $OL_READS $VARREG > tmp.txt #this must be included for MiSeq barcodes
	$BIN/filter_barcodes.pl tmp.txt 8 > $overlapped_startfile
	#rm tmp.txt
fi

#exit 1
if [[ -e $rekeyedtabbedfile ]]
	then
	echo "final tabbed file, $rekeyedtabbedfile, already made"
elif [ ! -e $rekeyedtabbedfile ] 
	then
	echo "making $rekeyedtabbedfile"
	$BIN/get_validtags.pl $overlapped_startfile $Lp $rRp "$VALIDTAGS" > $finaltabbedfile

	##########
	#BREAK HERE for merging into one file
	#add the number 1 to the left barcode for run 1, 2 for run 2 etc
	#then merge run 1 and 2 into one file
	#proceed as below
	#hopefully this won't break anything!!!
	##########
	
	$BIN/rekey_miseq.pl data_$name/samples.txt $finaltabbedfile > $rekeyedtabbedfile
	
	#########
	#must be renamed manually to rekeyed_tab1.txt etc
	#then merged with other files before proceeding 
	#don't forget to do this!!!!
	#########

fi
#exit 1
#only one sample set so no need to combine samples
#####
# cat rekeyed_tab1.txt rekeyed_tab2.txt > rekeyed_tab.txt
#####

#exit 1
#making the ISU groups
if [[ -e $groups_fa_file ]] 
	then
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

if [[ -e $c95file ]] 
	then
	echo "clustered already made, data in: $c95file"
else
	echo "clustering into OTUs at $cluster % ID"
	
	awk '{sub(/\|num\|/,";size=")}; 1' $groups_fa_file > data_$name/groups_uclust.fa
	$BIN/usearch7.0.1090_i86osx32 -cluster_otus data_$name/groups_uclust.fa -otu_radius_pct 3 -otus data_$name/clustered_otus_usearch.fa
	$BIN/usearch7.0.1090_i86osx32 -usearch_global $groups_fa_file -db data_$name/clustered_otus_usearch.fa -strand plus -id 0.97 -uc $c95file
	
	echo "clustering done data in: $c95file, moving on to next steps"
fi

if [ ! -e $mappedfile ]
	then
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

if [[ -e $mappedfile ]]
then
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
	echo "and change the 1 to your preferred abundance cutoff" 
	
	echo "getting the seed OTU sequences"
	$BIN/get_seed_otus_uc7.pl $c95file $groups_fa_file analysis_$name/OTU_tag_mapped.txt > analysis_$name/OTU_seed_seqs.fa
	
	#echo "adding the meta information" 
	#$BIN/add_meta.pl data_$name/samples.txt analysis_$name/OTU_tag_mapped.txt > analysis_$name/meta1_OTU_tag_mapped.txt
	#awk -F "\t" ' {sub (/ /, "_")} {print $0}' analysis_$name/meta1_OTU_tag_mapped.txt > analysis_$name/meta_OTU_tag_mapped.txt
	#rm analysis_$name/meta1_OTU_tag_mapped.txt
fi

echo "end of pipeline.sh"
exit 1
#########
#the manual stuff
#########
#BIN="/Users/ggloor/Documents/Custom_microbiota/torrent/EnE/bin/"

R CMD BATCH $BIN/OTU_to_QIIME.R OTU_to_QIIME.out #OTU table

$BIN/parse_RDP.pl seqmatch_download.txt > parsed_RDP.txt
$BIN/RDP_lineage.pl parsed_RDP.txt td_OTU_tag_mapped.txt > td_OTU_tag_mapped_lineage.txt

#in R aggregate by name
#a.d <- aggregate(d[,1:(ncol(d) -1)], by=list(d$taxonomy), FUN=sum)
#write.table(a.d", file="aggregated_td_OTU.txt", row.names=F, sep="\t", quote=F)
#mkdir qiime
cd qiime
macqiime

convert_biom.py -i ../td_OTU_tag_mapped_lineage_1.txt -o td_OTU_lineage.biom --biom_table_type="otu table" --biom_type=dense --process_obs_metadata taxonomy


summarize_taxa.py -i td_OTU_lineage.biom 

alpha_diversity.py -i td_OTU_lineage.biom -m shannon -o shannon.txt


muscle -in ../OTU_seed_seqs.fa -out OTU_seqs_bad.mfa
awk '/^>/{gsub(/lcl\|[0-9]+\|num\|[0-9]+\|OTU\|/, "")}; 1' OTU_seqs_bad.mfa > OTU_seqs.mfa
rm OTU_seqs_bad.mfa

#fix headers
FastTree -nt OTU_seqs.mfa > OTU_seqs.tre

beta_diversity_through_plots.py -i td_OTU_lineage_dots.biom -m category.txt -o all -t OTU_seqs.tre -f
