#!/usr/bin/perl -w
use strict;

# need a count table
# make a hash of hashes
# key holds sample
# array indexed by sample name, then OTU number
# will do filtering by abundance across samples in R
my %counts; # count table hash
my %OTUS; # keep a master list of OTUs

open(IN, "< $ARGV[0]") or die "$!\n";
 	while (my $l = <IN>){
 		chomp $l;
		my @l = split/\t/, $l;
		# must start with a word character
		# must map properly and uniquely
 		if ($l =~ /^[a-zA-Z0-9]/ && defined($l[1]) && $l[1] == 0 && $l[11] =~ /^AS/){
			my @id = split/\|/, $l[0]; # sampleID is first field
			my @OTU = split/\|/, $l[2]; # OTU_number is last field

			my @AS = split/:/, $l[11];
			my @XS = split/:/, $l[12];

			if ($AS[-1] - $XS[-1] > 10){
				$counts{$id[0]}{$OTU[-1]}++; # increment the OTU in the sample by 1
				$OTUS{$OTU[-1]}= ""; # just make a blank OTU each time
			}
 		}
 	}
close IN;

my @OTU = sort {$a <=> $b} keys(%OTUS);
my @ids = sort(keys(%counts));

# Now print the sucker!!
my $header = "Sample";
for (my $j = 0; $j < @OTU; $j++){ $header .= "\tOTU_$OTU[$j]";}
print "$header\n";

for(my $i = 0; $i <@ids; $i++){
	my $data = "$ids[$i]";
	for (my $j = 0; $j < @OTU; $j++){
		my $count = 0;
		$count = $counts{$ids[$i]}{$OTU[$j]} if exists $counts{$ids[$i]}{$OTU[$j]};
		$data .= "\t$count";
	}
	print "$data\n";
}
