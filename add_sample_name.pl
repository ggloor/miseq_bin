#!/usr/bin/perl -w
use strict;
#add laboratory IDs to each unique sample ID
#hard coded everything
my @names = qw(td_OTU_tag_mapped_lineage.txt td_OTU_tag_mapped_lineage97.txt OTU_seed_seqs.fa);
my @sample = split/_/, $ARGV[0];

open (OUT, "> $ARGV[0]/id_$names[2]") or die "$!\n";
open (IN, "< $ARGV[0]/$names[2]") or die "$!\n";
	while(my $l = <IN>){
		if ($l =~ /^>/){
			my @l = split/\|/, $l;
			print OUT ">$sample[1].$l[5]";
		}else{
			print OUT $l;
		}
	}
close IN;
close OUT;

open (OUT, "> $ARGV[0]/id_$names[0]") or die "$!\n";
open (IN, "< $ARGV[0]/$names[0]") or die "$!\n";
	while(my $l = <IN>){
		if ($l =~ /^#OTU/){
			chomp $l;
			my @l = split/\t/, $l;
			for(my $i = 1; $i < @l; $i++){
				$l[$i] = "$sample[1].$l[$i]";
			}
			my $out = join("\t", @l);
			print OUT "$out\n";
		}elsif($l =~ /^\d+/){
			$l = "$sample[1].$l";
			print OUT $l;
		}else{
			print OUT $l;
		}
	}
close IN;
close OUT;

open (OUT, "> $ARGV[0]/id_$names[1]") or die "$!\n";
open (IN, "< $ARGV[0]/$names[1]") or die "$!\n";
	while(my $l = <IN>){
		if ($l =~ /^#OTU/){
			chomp $l;
			my @l = split/\t/, $l;
			for(my $i = 1; $i < @l; $i++){
				$l[$i] = "$sample[1].$l[$i]";
			}
			my $out = join("\t", @l);
			print OUT "$out\n";
		}elsif($l =~ /^\d+/){
			$l = "$sample[1].$l";
			print OUT $l;
		}else{
			print OUT $l;
		}
	}
close IN;
close OUT;

