#######
#
# Assumes the user is in the reads folder and that the reads are uncompressed fastq
#
# requires usearch 7 or 8
# overlaps the paired-end reads
# filters the overlapped reads by expected number of errors
# data written to overlap_filtered.fastq
#
#######

# change this with each install
# set for svlad currently
BIN=~/Documents/0_git/miseq_bin
VERSION="usearch8.0-2.1517_i86osx32"
# maximum number of expected errors
ee=1

# make four temporary folders
mkdir split1
mkdir split2
mkdir overlap_split
mkdir overlap_filtered

files=(./*)
echo "${files[1]}"
echo "${files[0]}"

# split the reads into 1 million read chunks for 32 bit usearch
split -l 4000000 "${files[1]}" split2/
split -l 4000000 "${files[0]}" split1/

for f in $( ls split1/ ); do
	echo "$f"
	# overlap the reads
	$BIN/$VERSION -fastq_mergepairs split1/$f -reverse split2/$f  -fastqout overlap_split/$f.fastq

	rm split1/$f
	rm split2/$f

	# filter by maximum expected error
	$BIN/$VERSION -fastq_filter overlap_split/$f.fastq -fastq_maxee $ee -fastqout overlap_filtered/$f.fastq

	rm overlap_split/$f.fastq

	# merge the files into the final
	cat overlap_filtered/$f.fastq >> overlap_filter.fastq
	rm overlap_filtered/$f.fastq
done

# clean up
rm -R split1
rm -R split2
rm -R overlap_split
rm -R overlap_filtered
