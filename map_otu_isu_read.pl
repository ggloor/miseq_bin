#!/usr/bin/env perl -w
#######
# This software is Copyright 2010 Greg Gloor and is distributed under the 
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
#add group and cluster info to each read

#cluster information is in format from uclust:
#	id	L	pid	strand	qstart	tstart	align	isu_id
#S	5	97	*	*	*	*	*	lcl|97114|num|1	
#H	3	97	96.9	+	0	0	I97M	lcl|141259|num|1	
#first number in the list after | is cluster id, all subsequent numbers are
# in the same cluster. The cluster id is seeded by the longest 
# individual read in the cluster

#group information is in the format: 79671@100127_VVVVPPVV:4:83:1161:828:0:|ol|32
# first number is the cluster id, all subsequent id's separated by @ are read ids identical
# to the read ids in overlapped_tab.txt

=com
	What has to happen is to back track and add cluster information to group ids, and then cluster
	and group information into the reads
	
	will have to iterate over the files to get all the information in.
	Add information to overlapped_tab.txt as follows
	79671@100127_VVVVPPVV:4:83:1161:828:0:|ol|32|isu|num|c95|num|
	
	#where c95 refers to clustering by percent identity uclust. 
=cut

my $cluster_file = $ARGV[0];
my $group_file = $ARGV[1];
my $read_file = $ARGV[2];

my %otu; #hash to hold cluster information, key is isu, value is otu
my %isu; #hash to hold read information, key is read_id, value is isu

#this works without error:
#my @nm = split/[_\.]/, $cluster_file;
#my $nm = "o" . join("_", $nm[1], $nm[2]);
my $nm = "c95";

#this broke between versions of uclust
#because counting backwords does not work
#the isu is at location l[9], the OTU is at location l[1] for all rows
open (IN, "< $cluster_file") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		if ($l !~ /^#/){
			my @l = split/[\t\|]/, $l;
			$otu{$l[9]} = $l[1]; #key is isu, value is otu
			#print "$l[-3] $l[1]\n"; close IN; exit;
		}
	}
close IN;
#print "0:$otu{0}, 4:$otu{4}, 8:$otu{8} 137157:$otu{137157} 79671:$otu{79671} \n";
#exit;

open (IN, "< $group_file") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/\@/, $l;
		my $isu = $l[0];
		my $otu = "nd";
		$otu = $otu{$l[0]} if exists $otu{$l[0]};
		for(my $i = 1; $i < @l; $i++){
			#print "\@$l[$i]|isu|$isu|$nm|$otu\n"; close IN; exit;
			$isu{$l[$i]} = "|isu|$isu|$nm|$otu";
		}
	}
close IN;


open (IN, "< $read_file") or die;
	while(defined(my $l = <IN>)){
		chomp $l;
		my @l = split/[\@\t]/, $l;
		my $d1 = "";
		$d1 = "$l[1]$isu{$l[1]}";
		#print "$l[1] \n "; 
		@l = split/\t/, $l;
		my $l = @l -1;
		my $d2 = join("\t", $d1, @l[1 .. $l] );
		print '@' . "$d2 \n";
		#close IN; exit;
	}

close IN;

