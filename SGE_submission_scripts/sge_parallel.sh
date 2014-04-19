#!/bin/bash

#$ -cwd
#$ -S /bin/bash
#$ -N bt2pe
#$ -o bt2peout
#$ -e bt2peerr
#$ -l mem_free=10G
#$ -V
# #$ -h
#$ -t 1-3:1

index=$(expr $SGE_TASK_ID - 1)


echo $index
