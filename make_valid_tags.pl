#!/usr/bin/env perl -w
use strict;
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

#make valid tag file from samples.txt file
#left primer must be in column 0, right primer in column 1

my @vtag;
open (IN, "< $ARGV[0]") or die;
	while(my $l = <IN>){
		chomp $l;
		
		my @l = split/\t/, $l;

		if( $l =~ /^BC/){ 
			push @vtag, "$l[0]-$l[1]";	
		}else{
			my $lp = uc($l[0]);
			my $rp = uc(reverse($l[1])); $rp =~ tr/ACGT/TGCA/;
			push @vtag, "$lp-$rp";
 		}
	}
close IN;

my $vtag = join("\n", @vtag);

print "$vtag\n\n";