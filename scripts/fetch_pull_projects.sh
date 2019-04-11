#!/usr/bin/env bash

##################################################################################################
# Setup
##################################################################################################

# path to project directory
project_path=/home/miro/workspace/projects/
# Current directory
curr_dir=`pwd`

# use an argument to set project path
if [ ! $1 = "" ]; then
    project_path=$1
fi



###################################################################################################
# Update project
###################################################################################################

echo -e "\n\033[91mUpdating all repositories\033[0m"

for d in */; do
    echo -e "\n\033[91m... $d\033[0m"    
    cd $d
    git fetch 
    git pull
    cd -    
done

echo -e "\n\033[91m... Done\033[0m"
