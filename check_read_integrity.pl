#!/usr/bin/env perl -w
use strict;

####
# open R1 and R2 files concurrently and check for 
# read id order and read length
# assumes all read ids are : delimited
####

my $counter = 0;
my $minlen1 = my $minlen2= 1000;
my $maxlen1 = my $maxlen2 =0;
open (IN1, "< $ARGV[0]") or die "$!\n";
open (IN2, "< $ARGV[1]") or die "$!\n";
	while(my $l1 = <IN1>){
		my $l2 = <IN2>;
		if ($counter % 4 == 0){
			my @l1 = split/[ :]/, $l1;
			my @l2 = split/[ :]/, $l2;
			my $test1 = join("", @l1[0 .. 6]);
			my $test2 = join("", @l2[0 .. 6]);
			
			#exit with message if test fails
			if ($test1 ne $test2 ){
				print "$ARGV[0] differs from $ARGV[1] at line $counter\n";
				close IN1; close IN2;
				exit;
			}
		}elsif ($counter %4 == 1){
			my $len1 = length($l1); 
			my $len2 = length($l2);
			$minlen1 = $len1 if $len1 < $minlen1; 
			$minlen2 = $len2 if $len2 < $minlen2; 

			$maxlen1 = $len1 if $len1 > $maxlen1; 
			$maxlen2 = $len2 if $len2 > $maxlen2; 
		}
		$counter++;
	}
close IN1;
close IN2;

print "$ARGV[0]\tlines:$counter\trange1: $minlen1 to $maxlen1\trange2: $minlen2 to $maxlen2\n";

