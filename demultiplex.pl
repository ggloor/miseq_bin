#!/usr/bin/env perl -w
use strict;
#demultiplex a rekeyed tab.txt file

my %fastq;
my %samples;
open (IN, "< $ARGV[0]") or die;
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		(my $bc = $l[5]) =~ s/-//;
		my $id = "$l[1]_$bc";
		my $fastq = "$l[0]\n$l[3]\n+\n" . substr( $l[6],  (length($l[2]) + 12), length($l[3]) ) . "\n";
		$samples{$id}++;
		$fastq{$id} .= $fastq;
	}
close IN;

my @k =keys(%samples);
foreach(@k){
	my $file = "demultiplex/$_.fastq";
	open (OUT, "> $file") or die "$!\n";
		print OUT $fastq{$_};
	close OUT;
}