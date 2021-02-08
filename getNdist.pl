#!/usr/bin/env perl -w

# very simple script to get the N distribution by position in the read
# outputs a simple table for import into R
# base 1 counting

use strict;

my $c = 0;

my @A = my @C = my @G = my @T = my @N;

open (IN1, "< $ARGV[1]") or die "$!]n";
	while(my $l = <IN1>){
        if ($c % 4 eq 1){ # if it is a sequence line
            chomp $l;
            my @l = split(//, $l);
            for(my $i = 0; $i < scalar(@l); $i++){
                if($l[$i] eq "A"){
                    $A[$i]++;
                }elsif($l[$i] eq "C"){
                    $C[$i]++;
                }elsif($l[$i] eq "G"){
                    $G[$i]++;
                }elsif($l[$i] eq "T"){
                    $T[$i]++;
                }elsif($l[$i] eq "N"){
                    $N[$i]++;
                }
            }
        }
        $c++;
 #       if($c > 100000){close IN1;}
    }
close IN1;

print "pos\tA\tC\tG\tT\tN\n";
for(my $i = 0; $i < scalar(@A); $i++){
    my $a = 0; $a = $A[$i] if $A[$i];
    my $c = 0; $c = $C[$i] if $C[$i];
    my $g = 0; $g = $G[$i] if $G[$i];
    my $t = 0; $t = $T[$i] if $T[$i];
    my $n = 0; $n = $N[$i] if $N[$i];

    print "$i\t$a\t$c\t$g\t$t\t$n\n";
}
