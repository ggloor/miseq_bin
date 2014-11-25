#!/usr/bin/env perl -w
use strict;

#assign taxonomy to RDP seqmatch output of greengenes db v 13_5

#open taxonomy database ARGV[0]
my %taxon;
open (IN, "< $ARGV[0]") or die "$!\n";
	while(my $l = <IN>){
		chomp $l;
		my @l = split/[\t ]/, $l;
		$taxon{$l[0]} = join("\t", @l[1 .. 7]);
	}
close IN;

my %ggIDs; my %scores;
open (IN, "< $ARGV[1]") or die "$!\n";
	while(my $l = <IN>){
		chomp $l;
	if ($l !~ /^query/){
		my @l = split/\t/, $l;
		$ggIDs{$l[0]} .= "$l[1]\t";
		$scores{$l[0]} .= "$l[3]\t";
	}
	}
close IN;

my @k = keys(%ggIDs);

#convert each to an array and order by sab score from large to small
#this is to guard against a change in behaviour by seqmatch
# I could do this as hashes of arrays but ...
foreach(@k){
	my @data = split/\t/, $ggIDs{$_};
	my @scores = split/\t/, $scores{$_};
	#sort based 
	my @sorted_ids = @data[ sort { $scores[$b]<=>$scores[$a] } 0 .. $#scores ];
	
	my @tax = split/\t/, $taxon{$sorted_ids[0]}; #highest score
	my %k = my %p = my %c = my %o = my %f = my %g = my %s;
	for(my $i = 0; $i < @sorted_ids; $i++){
		#get the taxonomy for all max scores and ties
		if ($scores[0] == $scores[$i]){
			my @l = split/\t/, $taxon{$sorted_ids[$i]};
			$k{$l[0]}++; $p{$l[0]}++;$c{$l[0]}++;$o{$l[0]}++;$f{$l[0]}++;$g{$l[0]}++;$s{$l[0]}++;
		}
	}
	my $taxon = "";
	$taxon = "$sorted_ids[0];$tax[0]"; #kingdom is always assigned in gg_13_5

	$taxon .= "$tax[1]" if length(keys(%p)) == 1;
	$taxon .= "undefined;" if length(keys(%p)) > 1;

	$taxon .= "$tax[2]" if length(keys(%c)) == 1;
	$taxon .= "undefined;" if length(keys(%c)) > 1;
	
	$taxon .= "$tax[3]" if length(keys(%o)) == 1;
	$taxon .= "undefined;" if length(keys(%o)) > 1;

	$taxon .= "$tax[4]" if length(keys(%f)) == 1;
	$taxon .= "undefined;" if length(keys(%f)) > 1;

	$taxon .= "$tax[5]" if length(keys(%g)) == 1;
	$taxon .= "undefined;" if length(keys(%g)) > 1;

	$taxon .= "$tax[6]" if length(keys(%s)) == 1;
	$taxon .= "undefined;" if length(keys(%s)) > 1;

	print "$_\t$scores[0]\t$taxon\n";
}