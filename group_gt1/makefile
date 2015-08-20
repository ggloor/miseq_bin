#Makefile for group_gt1
#Copyright (c) 2014 Jia Rong Wu. All Rights Reserved.
#Usage under the GNU license
all: group_gt1
group_gt1: main.o bsTree.o
	gcc -Wall -o group_gt1 main.o bsTree.o
main.o: main.c bsTree.c bsTree.h
	gcc -Wall -c main.c 
bsTree.o: bsTree.c bsTree.h
	gcc -Wall -c bsTree.c bsTree.h
clean:
	rm -f sample *.o core *.gch
