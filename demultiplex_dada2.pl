#!/usr/bin/env perl -w
use strict;

# extract barcoded fastq format into mothur-compatible file lists
# need forward fastq, reverse fastq and samples file as input
# output is to a directory called demultiplex_group
# contains the forward and reverse fastq per barcode and a file called key_file.txt
#
# barcodes and primers are stripped
#
# argument list is:
# 0 samples.txt
# 1 forward fastq
# 2 reverse fastq
# 3 primer names, one of V4EMB, V6, etc

my @lprimerlen = (19, 20, 19, 18, 16);
my @rprimerlen = (20, 31, 18, 17, 20);

my  $primer = 1;
if ( defined $ARGV[3]){
	$primer = 3 if $ARGV[3] eq "SOSP";
	$primer = 3 if $ARGV[3] eq "MCHII_SOSP";
	$primer = 2 if $ARGV[3] eq "V6";
	$primer = 0 if $ARGV[3] eq "ITS6";
	$primer = 1 if $ARGV[3] eq "Kcnq1ot1";
	$primer = 1 if $ARGV[3] eq "V4EMB";
}
my %samples;
my $bclen = 12; #Golay are 12-mers
$bclen = 8 if $ARGV[3] eq "MCHII_SOSP";
$bclen = 8 if $ARGV[3] eq "SOSP";

my $group ="reads";

# open samples.txt file and make a hash of forwardbc-reversebc  with value sampleID
# also get the barcode length
open (IN, "< $ARGV[0]") or die "$!\n";
	while(my $l = <IN>){
		chomp $l;
		my @l = split/\t/, $l;
		my $bc = join("-", uc($l[0]), uc($l[1]));
        if ($bc =~ /^[ACGT]/){
    		$bclen = length($l[0]);
		    $samples{$bc} = $l[2];
#		    $group = $l[5] if ($group eq "NULL" or $group eq "reads");
		}
	}
close IN;

#foreach(keys(%samples)){print "$_ $samples{$_}\n";}
#for (my $i = 0; $i < 10; $i++){
#	my $mod = $i % 4;
#	print "$i $mod\n";
#}
#exit;

my $c = 0; my $dataL = my $dataR; my $keep = "F";
my %outputL = my %outputR; my $id;
#open forward fastq and reverse fastq
open (IN1, "< $ARGV[1]") or die "$!]n";
open (IN2, "< $ARGV[2]") or die "$!\n";
	while(my $l1 = <IN1>){
		my $l2 = <IN2>;
		chomp $l1; chomp $l2;
		if ($c % 4 == 0 ) { #def line
			if ($keep ne "F"){
				$outputL{$keep} .= $dataL;
				$outputR{$keep}  .= $dataR;
				#my $mod = $c % 4; print "$c $mod\n$keep\n$dataL\n$dataR\n";
			}
			#empty the variables
			$keep = "F"; $id = "";
			$dataL = "$l1\n";
			$dataR = "$l2\n";
			#added check for line length gg, march 3, 2015
		}elsif($c % 4 == 1 && length($l2) > (($bclen + 4) + $rprimerlen[$primer]) ){ #seq line

			my $bc = join( "-", substr($l1, 4,$bclen), substr($l2, 4,$bclen) );
			#print "$c $bc \n$l1\n$l2\n";
			if (exists $samples{$bc}){
				$keep = $bc ;
				$dataL .= substr($l1, (($bclen + 4) + $lprimerlen[$primer]) ) . "\n";
				$dataR .= substr($l2, (($bclen + 4) + $rprimerlen[$primer]) ) . "\n";
			}
		}elsif($c % 4 == 2 ){ #second def line
			$dataL .= "+\n";
			$dataR .= "+\n";
		}elsif($c % 4 == 3 && $keep ne "F") { #qscore
			$dataL .= substr($l1, (($bclen + 4) + $lprimerlen[$primer]) ) . "\n";
			$dataR .= substr($l2, (($bclen + 4) + $rprimerlen[$primer]) ) . "\n";
		}
		$c++;

#	if ($c > 100000){
#		last;
#		close IN1; close IN2;
#	}
	}
close IN1; close IN2;
#exit;
my @bc = keys(%samples);
system(`mkdir "demultiplex_$group"`);
for(my $i = 0; $i < @bc; $i++){
#	my $fileL = $samples{$bc[$i]} . "-" . $bc[$i] . "-R1.fastq";
#	my $fileR = $samples{$bc[$i]} . "-" . $bc[$i] . "-R2.fastq";
	my $fileL = $samples{$bc[$i]} . "-R1.fastq";
	my $fileR = $samples{$bc[$i]} . "-R2.fastq";

	open (OUT, "> demultiplex_$group/$fileL") or die "$fileL unwritable $!\n";
		print OUT $outputL{$bc[$i]} if $outputL{$bc[$i]};
	close OUT;
	open (OUT, "> demultiplex_$group/$fileR") or die "$fileR unwritable $!\n";
		print OUT $outputR{$bc[$i]} if $outputR{$bc[$i]};
	close OUT;
}
