#!/usr/bin/env perl -w
use strict;

####
# open R1 and R2 files concurrently and check for 
# read id order
# assumes all read ids are : delimited
# then write out the concatenated fastq file with the
# reverse read as reverse complement
# no read error checking
####
my $length1 = 225;
my $length2 = 125;
my $counter = 0;
my $read;
open (IN1, "< $ARGV[0]") or die "$!\n";
open (IN2, "< $ARGV[1]") or die "$!\n";
	while(my $l1 = <IN1>){
		my $l2 = <IN2>;
		if ($counter % 4 == 0){
			my @l1 = split/[ :]/, $l1;
			my @l2 = split/[ :]/, $l2;
			my $test1 = join("", @l1[0 .. 6]);
			my $test2 = join("", @l2[0 .. 6]);
			
			if ($test1 eq $test2){
				print $read if $counter > 2;				
			#exit with message if test fails
			}
			elsif ($test1 ne $test2 ){
				warn "$ARGV[0] differs from $ARGV[1] at line $counter\n";
				close IN1; close IN2;
				exit;
			}
			$read  = $l1;
		}elsif ($counter % 4 == 1){
			chomp $l1;
			chomp $l2;
			
			my $s1 = substr($l1, 0, $length1);
			my $s2 = substr($l2, 0, $length2);
			#rev complement
			my $rev = reverse($s2); $rev =~ tr /ACGT/TGCA/;
			$read .= $s1 . $rev . "\n";
				
		}elsif ($counter % 4 == 2){
			$read .= "+\n";
		}elsif($counter % 4 == 3){
			chomp $l1; chomp $l2;
			my $s1 = substr($l1, 0, $length1);
			my $s2 = substr($l2, 0, $length2);
			my $rev = reverse($s2);
			$read .= $s1 . $rev . "\n";
		}
		$counter++;
	}
close IN1;
close IN2;


