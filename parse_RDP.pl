#!/usr/bin/env perl -w
use strict;
my $rdpout = $ARGV[0];
print "needs an RDP besthit output file as input" if !$ARGV[0];
exit if !$ARGV[0];
my %id;

my $minS_ab = 0.40;
my $TF = 0;			
my %species; #tf flag for named species or not
my %genus; my %phylum = my %class = my %order = my %family;
my $lastid;
my $bestguess;
my $bestscore = 0;

my @data = my @idx;

open (IN, "< $rdpout") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		$l =~ s/"//g;
		#print "---- $TF $l\n";
		$TF = 1 if $l =~ /^query/;
		if ($TF == 1 && $l !~ /^query/ && $l ne ""){
			my @l = split/\t/, $l;

				my @nm = split/\s+/, $l[6];
				my $nm = join(" ", $nm[0], $nm[1]);
				$nm[1] =~ s/;//;
				my $score = $l[4];
			
			#parse through the S_ab score and select those that are perfect
			if ($score > $minS_ab){
				#if we have a named genus or species
				if ($l[6] !~ /^[a-z]/ && $l[6] !~ /^bacterium/){
					if ($bestscore < $score){
					%genus = %species = %phylum = %class = %order = %family = (); 

					$bestscore = $score;
					$id{$l[0]} = $nm;
					#print "$l[0] $nm\n";
					$genus{$nm[0]}="";
					$species{$nm[1]}="" if ($nm[1] ne "sp." && $nm[1] ne "genomosp.");
				
					$lastid = $l[0];
					
					for(my $i = 0; $i < @l; $i++){
						$phylum{$l[$i +1]} ="" if $l[$i] eq "phylum"; 
						$class{$l[$i +1]} =""  if $l[$i] eq "class"; 
						$order{$l[$i +1]}  ="" if $l[$i] eq "order"; 
						$family{$l[$i +1]} =""  if $l[$i] eq "family"; 
					}
					}elsif ($bestscore == $score){
					$id{$l[0]} = $nm;
					#print "$l[0] $nm\n";
					$genus{$nm[0]}="";
					$species{$nm[1]}="" if ($nm[1] ne "sp." && $nm[1] ne "genomosp.");
				
					$lastid = $l[0];
					
					for(my $i = 0; $i < @l; $i++){
						$phylum{$l[$i +1]} ="" if $l[$i] eq "phylum"; 
						$class{$l[$i +1]} =""  if $l[$i] eq "class"; 
						$order{$l[$i +1]}  ="" if $l[$i] eq "order"; 
						$family{$l[$i +1]} =""  if $l[$i] eq "family"; 
					}
					}
				}else{
					if ($bestscore < $score){
						$lastid = $l[0];
						$bestguess = $l[-1];
						$bestscore = $score;
					}

				}
			}else{
				if ($bestscore < $score){
					$lastid = $l[0];
					$bestguess = $l[-1];
					$bestscore = $score;
				}
			}
			
		}elsif($l eq "" && $TF == 1){
			my @genus = keys(%genus);
			my @species = keys(%species);
			my @phylum = keys(%phylum);
			my @class = keys(%class);
			my @order = keys(%order);
			my @family = keys(%family);
			my $data;
			my $species = my $genus = my $family = my  $order = my $class = my $phylum = "unclassified";
			$species = $species[0] if scalar(@species) == 1;
			$genus = $genus[0] if scalar(@genus) == 1;
			$family = $family[0] if scalar(@family) == 1;
			$order = $order[0] if scalar(@order) == 1;
			$class = $class[0] if scalar(@class) == 1;
			$phylum = $phylum[0] if scalar(@phylum) == 1;
			$data = "$lastid\tS|$bestscore|p|$phylum|c|$class|o|$order|f|$family|g|$genus|s|$species\n" if @genus > 0;
			$data = "$lastid\tS|$bestscore|u|$bestguess\n" if @genus == 0;
			#print $data;
			
			push @data, $data;
			push @idx, $bestscore;
			
			%genus = %species = %phylum = %class = %order = %family = (); $lastid = $bestguess = ""; $bestscore = 0;
		}

	}
close IN;


my @sorted_array = @data[ sort { $idx[$b]<=>$idx[$a] } 0 .. $#idx ]; 

foreach(@sorted_array){
	print $_;
}
