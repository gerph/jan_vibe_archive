#!/bin/bash
##
# Record all the BASIC programs in the directories

for bas in */*,fd1 ; do
    ./record-program.sh $bas
done
