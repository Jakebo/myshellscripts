#!/bin/bash

declare -r -A partitionMap=(["emmc_appsboot.mbn"]="aboot" ["boot.img"]="boot" ["system.img"]="system" ["userdata.img"]="userdata" ["persist.img"]="persist" ["recovery.img"]="recovery" ["cache.img"]="cache" ["IPSM.img"]="IPSM" ["splash.img"]="splash")

updateFile=$@
if [ ${#updateFile} -eq 0 ]; then
    updateFile=${!partitionMap[@]}
fi

check_file()
{
    files=$@
    
    for f in $files; do
        if [ ! -f $f ]; then
            echo "ERROR: $f is not exist"
            return 1
        fi
    done

    return 0
}

update_file()
{
    files=$@
    
    for f in $files; do
        echo "sudo fastboot flash ${partitionMap[$f]} $f"
        sudo fastboot flash ${partitionMap[$f]} $f
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to update $f"
            return 1
        fi
    done

    return 0
}

check_file $updateFile
if [ $? -eq 1 ]; then
    echo "Exit without updating"
    exit 1
fi

update_file $updateFile
if [ $? -eq 1 ]; then
    echo "Exit while update $updateFile"
    exit 1
fi

exit 0
