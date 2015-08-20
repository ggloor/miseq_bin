/********************************************************************************
 * main.c
 *
 * To be used as: group_gt1.c
 * Version 1.5
 *
 * Author: Jia Rong Wu
 * jwu424@uwo.ca
 *
 * This software is Copyright 2014 Jia Rong Wu and is distrubuted under the terms
 * of the GNU General Public License.
 *
 * main.c takes input from a tabbed file and sorts sequences
 * writes a file with the output of sorted sequences by "k" frequency
 *******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include "bsTree.h"
#include <time.h>   // Double check the runtime of the function

int main(int argc, const char * argv[]) {
    
    FILE* fp;
    char* dir = malloc(MAX_SEQ_LENGTH*sizeof(char));
    char* directoryIn = (char*) argv[1];
    char* directoryOut = (char*) argv[2];
    
    // Handle arguments to program
    source* parameters = params_init(directoryIn, directoryOut);
    
    DIR* dIn; // Source Directory
    dIn = opendir(parameters->dirIn);
    if (dIn == NULL)
    {
        fp = fopen(parameters->fileIn, "r");
    }
    else
    {
        getcwd(dir,MAX_SEQ_LENGTH);
        chdir(parameters->dirIn); // Change directory to directory with file
        fp = fopen(parameters->fileIn, "r");
    }
    
    chdir(dir); // Go back to working directory


    int inputs = 0; // Count total inputs
    int count = 0;  // Count unique inputs
    char buffer[MAX_BUFFER_LEN];
    
    bsTree seq;    // Data structure to store sequences
    seq = bsTree_init();
    
    if (fp == NULL)
    {
        perror("ERROR: Could not read from file");
        exit(EXIT_FAILURE);
    }
    else
    {
        char id[MAX_ID_LENGTH]="";          // Sequence identifier
        char misc[MAX_ID_LENGTH]="";
        char primer[MAX_ID_LENGTH]="";
        char id_sequence[MAX_SEQ_LENGTH]=""; // Sequence l[3]
        char flag = 's';
        
        bsNode* insert = malloc (sizeof(bsNode));
        // Read file into buffer for parsing individual lines
        while ((fgets(buffer,MAX_BUFFER_LEN, fp)) != NULL) // LOOP THROUGH FILE
        {

            // Parse individual lines from file
            // Accepts whitespace-separated lines or tabbed lines
            while (sscanf(buffer, " %s %s %s %s %s %s ", id,misc,primer,id_sequence,primer,misc) == 6)
            {
                bsTree_insert(seq, id, id_sequence,flag);
                inputs++;
                break;
            }
        }
        
        count =  totalNodes(seq); // Count = number of UNIQUE entries
        printf("Number of entries: %d\n",inputs); // DEBUG REMOVE LATER
        printf("Number of unique entries: %d\n", count); // DEBUG REMOVE LATER
        free(insert);
    }
    fclose(fp);
    
    int* index = malloc(sizeof(int)); // Used to set array indices
    
    // Malloc guard
    if (index == NULL)
    {
        perror("Out of memory: ");
        exit (EXIT_FAILURE);
    }
    
    *index = 0;
    bsNode* arr[count];    // Create array of pointers to nodes
    populateArray(seq, arr, index);
    
    qsort((void*)&arr, count, sizeof(void*), &comparator); // Sort on gcount
    arrWrite(arr, count, parameters); // output 2 files in this function
//    arrWrite2(arr,count);
    free(dir);
    free(parameters);
    free(index);
    printf("Executed Successfully.\n");
    exit(EXIT_SUCCESS);
}
