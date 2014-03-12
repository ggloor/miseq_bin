#!/usr/bin/env perl -w

#######
# This software is Copyright 2013 Greg Gloor and is distributed under the 
#    terms of the GNU General Public License.
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#    along with this program. It should be located in gnu_license.txt
#    If not, see <http://www.gnu.org/licenses/>.
########

use strict;
#find left and right side primers
#input and output are tabbed, output is from get_v9.pl or get_v6.pl

my $file = $ARGV[0]; my $Lpr = $ARGV[1]; my $Rpr = $ARGV[2];
my @vtag = split/\s+/, $ARGV[3]; #must come from the shell script

#need to automatically get left and right primer lengths
my $lplen = getpl($Lpr);
my $rplen = getpl($Rpr);
#print "$Lpr $lplen\n$Rpr $rplen\n"; exit;

sub getpl{
	my @l = split//, $_[0];
	my $redundant = 0;
	my $lastbr = "";
	foreach(@l){
		$lastbr = $_ if ($_ eq "[" || $_ eq "]");
		$redundant++ if ($lastbr eq "[");
	}
	return length($_[0]) - $redundant;
	
}

#populate tag hashes
my %vtag;
pop_tag(); 
#exit;
#generates a lookup table of correct paired end barcodes
sub pop_tag{

	for(my $i = 0; $i < @vtag; $i++){
		$vtag{$vtag[$i]} = "";
		#print "$ltag[$i]\n";
	}
}
sub revcomp{
	my $rval = reverse $_[0];
	$rval =~ tr/ACGT/TGCA/;
	return $rval;
}

#valid primers already found and in the file
open (IN, "< $file") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\t/, $l;
		my $ltag = $l[1];		
		my $rtag = $l[5];
		
		my $tag = "$ltag-$rtag";
		
		print "$l\n" if (exists $vtag{$tag});
	}
close IN;