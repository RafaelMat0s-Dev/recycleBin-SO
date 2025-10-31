#!/bin/bash

#################################################
# Script Header Comment
# Author: João Miguel Padrão Neves
# Date: 2025-10-18
# Description: Function to present the features 
# Version: 1.0
#################################################

#################################################
# Function: display_help()
# Description: Provide informations about how to use the Recycle Bin (~)
# Parameters: None
# Returns: It doesn't return any vallue
#################################################

display_help() {
    echo -e "Use: ./recycle_bin [option] [Flags] [File/id]\n"
    echo -e "Recycle Bin Commands:\n"
    echo -e "Options:\n"
    echo -e "   'delete' -> Moves a file(s) to the recycle but do not delete it permanently. Acept as argument a file or a path\n"
    echo -e "       Examples:\n
                            ->./recycle_bin.sh delete myfile.txt\n
                            ->./recycle_bin.sh delete file1.txt file2.txt directory/\n"
    echo -e "   'list' -> Shows all the files in the recycle bin\n"
    echo -e "       -> To see in detail mode use the flag '--detail'\n" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh list\n
                            ->./recycle_bin.sh list --detailed\n"
    echo -e "   'restore' -> Moves the file in recycle to the original path, where it was before being move. Acept as argument a file or a ID of a file\n" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh restore 1696234567_abc123\n
                            ->./recycle_bin.sh restore myfile.txt\n"
    echo -e "   'search' -> Confirm if the file is in the recycle. Acept as argument a file or a pattern\n"
    echo -e "       Examples:\n
                            ->./recycle_bin.sh search \"report\"\n
                            ->./recycle_bin.sh search \"\*.pdf\"\n"
    echo -e "   'empty' -> Delete permanently a file or all de recycle\n"
    echo -e "       -> It will ask for permission.To skip that use the flag '--force'\n" 
    echo -e "       -> You can use 'all' or write nothing to delete all the file in the recycle" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh empty\n
                            ->./recycle_bin.sh empty 1696234567_abc123\n
                            ->./recycle_bin.sh empty --force\n"
    echo -e "   'status' -> Shows information about the recycle bin:\n"
    echo -e "       ->" 
    echo -e "       Examples:\n
                            ->./recycle_bin.sh status"    
    return 0
}