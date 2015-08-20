/********************************************************************************
 * bsTree.c
 *
 * To be used as the data structure for group_gt1
 * Version 1.5
 *
 * Author: Jia Rong Wu
 * jwu424@uwo.ca
 *
 * This software is Copyright 2014 Jia Rong Wu and is distrubuted under the terms
 * of the GNU General Public License.
 *
 * bsTree.c represents a tree data structure
 * Can be used for efficient sorting or storage of any STRING/INT values
 *******************************************************************************/

#include <stdlib.h>
#include <string.h>
#include "bsTree.h"

// Function Prototypes (private functions)
int intComparator(bsNode*, bsNode*);
void traverseWrite(bsTree sorted, FILE *fp);

/**
 * bsTree_init allocates necessary memory for a pointer to the first element in a tree
 * @return pointer to pointer of first node in tree
 */
bsTree bsTree_init(void)
{
    bsTree tree;
    tree = (bsTree) malloc(sizeof(bsNode));
    *tree = NULL;
    return tree;
}

/*
 * params_init initializes a pointer to group_gt1's arguments
 * @arg1 is the input directory + filename
 * @arg2 is the output directory + filename
 * @return pointer with in/out directory and in/out filename
 */
source* params_init(char* arg1, char* arg2)
{
    if (arg1 == NULL) // No input argument
    {
        printf("ERROR: No source directory specified.\n");
        printf("Usage: ./group_gt1 'source_dir/filename.txt' 'destination_dir'\n");
        exit(EXIT_FAILURE);
    }
    if (arg2 == NULL) // No output argument
    {
        printf("ERROR: No destination directory specified.\n");
        printf("USAGE: ./group_gt1 'source_dir/filename.txt' 'destination_dir'\n");
        exit (EXIT_FAILURE);
    }
    source* params = malloc(sizeof(source));
    int count;
    
    char argument1[strlen(arg1)]; // Hold copy- strtok consumes original
    char argument2[strlen(arg2)]; // Hold copy- strtok consumes original

    memcpy(argument1, arg1, strlen(arg1));
    memcpy(argument2, arg2, strlen(arg2));
    
    count = (int)strlen(arg1);

    char* x = strtok(arg1,"/"); // Separate on "/"
    while (x != NULL)
    {
        params->fileIn = x;
        x = strtok(NULL,"/");
    }
    count = count - (int)strlen(params->fileIn);
    params->dirIn = malloc(count*sizeof(char));
    memcpy(params->dirIn, argument1, count);
    count = (int)strlen(arg2);

    char* y = strtok(arg2,"/");
    while (y != NULL)
    {
        params->fileOut = y;
        y = strtok(NULL,"/"); // Split string on "/"
    }
    count = count - (int)strlen(params->fileOut);
    params->dirOut = malloc(count*sizeof(char));
    memcpy(params->dirOut, argument2, count); // Save output directory
    
    return params;
}


/*
 * free_params frees allocated memory for arguments for group_gt1
 * @p is the pointer to the parameters
 */
void free_params(source* p)
{
    free (p->dirIn);
    free (p->dirOut);
    free(p);
}


/**
 * bsTree_insert takes a sequence and identifier, and inserts it into a tree
 * @s represents the sequence to be inserted
 * @id represents the identifier of the sequence
 * @return a pointer to the node that it was stored at
 */
bsNode* bsTree_insert(bsNode** node, char *identifier, char* sequence, char flag)
{
    if (*node == NULL)
    {
        (*node) = malloc(sizeof(bsNode));
        
        if (node == NULL)
        {
            perror("Out of memory: ");
            exit (EXIT_FAILURE);
        }
        
        // Memcpys are used to allocate memory as per-needed basis
        // File sequences saved IFF they are unique
        
        (*node)->gcount = 1;
        (*node)->identifier = malloc(strlen(identifier)+1);
        memcpy((*node)->identifier,identifier,strlen(identifier));
        
        (*node)->seq = malloc(strlen(sequence)+1);
        memcpy((*node)->seq, sequence, strlen(sequence));
        
        (*node)->nId = setFirst((*node)->identifier);
        
        // Malloc guard
        if((*node)->identifier == NULL || (*node)->seq == NULL)
        {
            perror("Out of Memory: ");
            exit (EXIT_FAILURE);
        }
    }
    else
    {
        int comparator = 0;

        // Check value of inserting sequence to old string
        comparator = strcmp((*node)->seq,sequence);
        
        if (comparator < 0)
        {
            bsTree_insert(&(*node)->right_child,identifier, sequence, flag);
            (*node)->right_child->parent = *node;
        }
        else if (comparator > 0)
        {
            bsTree_insert(&(*node)->left_child, identifier, sequence, flag);
            (*node)->left_child->parent = *node;
        }
        else // Sequence Already Exists
        {
            (*node)->gcount ++; // Increment occurence of sequence
            (*node)->nId = setNext(identifier, (*node)->nId); // Append identifier
        }
        return (*node);
    }
    return (*node);
}


/**
 * inOrder_traversal walks the tree from smallest to largest element
 * CAN APPEND CODE INSIDE TO CHANGE FUNCTIONALITY OF FUNCTION
 * takes O(n) runtime, n being the number of elements in the tree
 * @tree is the tree being traversed
 */
void inOrder_traversal(bsTree tree)
{
    if (*tree != NULL)
    {
        inOrder_traversal( &(*tree)->left_child );
        printf("Seq: %s\n", (*tree)->seq);          // DEBUG, REMOVE LATER
        printf("gcount: %d\n\n", (*tree)->gcount);    // DEBUG, REMOVE LATER
        inOrder_traversal( &(*tree)->right_child );
    }
}


/*
 * populateArary in-order traverses a tree and sets array indices accordingly
 * @sorted is the tree containing sequences with calculated frequencies
 * @arr is the array to be written to
 * @index is the current index of the array
 */
int populateArray(bsTree sorted, bsNode* arr[], int* index)
{
    
    if ( (*sorted) != NULL)
    {
        populateArray (&(*sorted)->left_child, arr, index);
        arr[*index] = (*sorted);
        (*index)++;
        populateArray (&(*sorted)->right_child, arr, index);
        
        return 1;
    }
    return 0;
}


/*
 * comparator is the comparator function for qsort
 * Follows the ordering and logic of the original 'group_gt1.pl'
 * @one is the pointer to element 1 being sorted
 * @two is the pointer to element 2 being sorted
 * @return greatest to smallest order
 */
int comparator(const void* one, const void* two)
{
    bsTree x = (bsNode**)one;
    bsTree y = (bsNode**)two;
    
    int x1 = (*x)->gcount;
    int x2 = (*y)->gcount;
    
    if (x1 > x2)
    {
        return -1;
    }
    else if (x1 < x2)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

/*
 * arrWrite takes an array of pointers to nodes, and writes its
 * contents to a file
 * @arr[] is the array being read from
 * @count is the number of elements in the array
 */
void arrWrite(bsNode* arr[], int count, source* parameters)
{
    FILE* fp;
    DIR* dOut; // Directory to write out
    dOut = opendir(parameters->dirOut);
    if (dOut == NULL)
    {
        fp = fopen(parameters->fileOut, "w");
    }
    else
    {
        chdir(parameters->dirOut); // FIX LATEr, NOT WORKING
        fp = fopen(parameters->fileOut, "w");
    }
    
    if (fp == NULL)
    {
        perror("ERROR: Unable to write to file");
        exit(EXIT_FAILURE);
    }
    else
    {
        iterateWrite(arr,fp, count); // Iteratively write elements to file
    }
    fclose(fp); // Close file
}

/*
 * iterateWrite iteratively steps through an array
 * It handles freeing of allocated memory and writing to the file
 * @arr[] is the array being traversed
 * @fp is the pointer to the file being written into
 * @count is the count of the file
 */
void iterateWrite(bsNode* arr[], FILE *fp, int count)
{
    FILE* fwp = fopen("reads_in_groups.txt", "w");

    int index; // Index of the array
    for (index = 0; index < count; index ++) // Iterate through all seq's
    {
        if ((*(arr[index])).gcount > K) // Add selection here for number
        {
            /*groups.txt*/
            fprintf(fp, ">lcl|%d|num|%d|\t", index, (*(arr[index])).gcount);
            fprintf(fp, "%s\n", (*(arr[index])).seq);
            /*groups.txt*/
            
            /*reads_in_groups.txt*/
            fprintf(fwp, "%d",index); // Represents $groups{$k}
            while ((*arr[index]).nId != NULL)
            {
                fprintf(fwp,"%s",(*arr[index]).nId->identifier); // $gname{k}
                (*arr[index]).nId = (*arr[index]).nId->next;
            }
            fprintf(fwp, "\n");
            /*reads_in_groups.txt*/
        }
        free((arr[index])); // Free the data pointed to in array
    }
    fclose(fwp);
}


/*
 * totalNodes recursively counts the number of nodes in a specified tree
 * @tree is the tree that's being counted
 * @return number of nodes in the tree (NOT INCLUDING LEAFS)
 */
int totalNodes(bsTree tree)
{
    int l = 0;
    int r = 0;
    
    if (*tree != NULL)
    {
        l = totalNodes( &(*tree)->left_child);
        r = totalNodes( &(*tree)->right_child);
        return (l + r + 1);
    }
    return 0;
}

/**
 * resetRoot resets the pointer to the root node after rebalance
 * @t is the tree being reset
 */
void resetRoot (bsTree t)
{
    if (t == NULL)
    {
        //   break;
    }
    else if ( (*t)-> parent == NULL)
    {
        // Do nothing, root is correct
    }
    else
    {
        while ( (*t)->parent != NULL) // Iterate up till the root
        {
            (*t) = (*t)->parent;
        }
    }
}

/**
 * intComparator takes 2 numbers, compares them
 * @num1 is first number to be compared
 * @num2 is 2nd number to be compared
 * returns >0 if 1 > 2, <0 if 1 < 2, or 0 if equal
 */
int intComparator(bsNode* one, bsNode* two)
{
    if (one->gcount > two->gcount)
    {
        return 1;
    }
    else if (one->gcount < two->gcount)
    {
        return -1;
    }
    else
    {
        return 1; // Fix this because inserting is O(n) at some points
    }
}


/*
 * setNext adds and identifier to the head of the "pseudo-linked-list"
 * Will create list in "reverse" order, reverse relative to original program
 * @identifier is the ID being added for a sequence
 * @head is the CURRENT head of the linked list
 * @return the head of the list
 */
nextId* setNext(char* identifier, nextId* head)
{
    nextId* next = malloc(sizeof(nextId)); // Create new node
    next->identifier = identifier; // Shouldn't need to malloc because just pointing to locations allocated by sequences**
    next->next = head;
    return next;
}


/*
 * setFirst will set the first identifier for a unique sequence
 * @identifier is the first identifier
 * @return a pointer to the first identifier
 */
nextId* setFirst(char* identifier)
{
    nextId* first = malloc(sizeof(nextId));
    first->identifier= identifier;
    first->next = malloc(sizeof(NULL));
    first->next = NULL;
    
    return first;
}