#!/bin/bash

###  Set slurm fairshare according to lab's total GPFS storage allocations
###  Run with slurm admin account or sudo on machine with access to slurm
###  Usage: sudo ./UpdateSlurmFairshare.sh

export GPFSLabs=/tmp/GPFS_labs  #Temporary file
export SlurmLabs=/tmp/slurm_labs  #Temporary file

#Parse GPFS collection logs. Parse down to lab name and lab's total lease amount in TiB * 100.
ParseGPFS="$(awk '$3=="total_fileset" && $2!="root"' /gpfs/gpfsusagelog.latest | 
                awk '{print $2, ($5/10737418.24)}' | 
                awk 'BEGIN{FS="_"} {print $1,$NF}' | 
                awk '{print $1,$3}' | 
                awk '{a[$1]+=($2)}END{for(x in a)print x, a[x]}' |
                sort
           )"

echo "$ParseGPFS" > $GPFSLabs

#convert non-matching GPFS fileset names to valid slurm account names
sed -e 's/abclab/abc_lab/g' \
        -e 's/xyz/xyzusers/g' \
        -e 's/admin/slurm_admins/g' $GPFSLabs  > $SlurmLabs


while read LabName PriorityShares
do

        echo "Setting fairshare of $LabName to $PriorityShares" &&
        sacctmgr -i modify account account="$LabName" set fairshare="$PriorityShares" &&
        echo

done < $SlurmLabs

rm $SlurmLabs $GPFSLabs
