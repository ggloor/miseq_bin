#!/usr/bin/env perl -w
use strict;
#######
# This software is Copyright 2012 Greg Gloor and is distributed under the 
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

my %meta;
#add meta information
open (IN, "< $ARGV[0]") or die; #this is the samples.txt file
	while(my $l = <IN>){
		my @l = split/\t/, $l;
		my $rbc = reverse($l[1]);
		$rbc =~ tr/acgt/TGCA/;
		my $lbc = uc($l[0]);
		my $bc = $lbc . "-" . $rbc;
		#print "$bc\n";
		$meta{$bc} = $l[2];
		
	}
close IN;
#exit;
open (IN, "< $ARGV[1]") or die;	#this is the ISU or OTU table
	while(my $l = <IN>){
	my @l = split/\t/, $l;
		print "ID\t$l"  if $l =~ /^Ltag/;
		print "$meta{$l[0]}\t$l" if  $l !~ /^Ltag/;
	}
close IN;