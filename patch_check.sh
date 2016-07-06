#!/bin/bash

patch_dir=$1 # Root directory of patches
success_list="success_list.log" # File to store patches of applying
fail_list="fail_list.log" # File to store patches of applying failed
compile_log="compile.log" # File to store compile log
filtered_list="filtered.log" # File to store filter log

if [ -f filter.txt ]; then
    filter_list=`cat filter.txt` # The filters stored in filter.txt
else
    filter_list=
fi
if [ -f filter_patch.txt ]; then
    filter_patch_list=`cat filter_patch.txt` # The patch filter sotred in filter.txt
else
    filter_patch_list=
fi

echo "" > log.txt

success_count=0
fail_count=0
compile_ok_count=0
compile_failed_count=0

echo "Patches applied successful" > $success_list
echo "===========================================================" >> $success_list
echo "Patches applied failed" > $fail_list
echo "===========================================================" >> $fail_list
echo "Compile log" > $compile_log
echo "===========================================================" >> $compile_log

#
# Is a patch file?
# $1: the specified file
#
is_patch()
{
    file=$1
    
    #
    # $file is a patch file, in normal case, the patch name with
    # ".patch" or ".diff" as suffix
    #
    if [ -f $file ]; then
        suffix=${file##*.}
        if [ "$suffix" = "patch" ] ||
               [ "$suffix" = "diff" ]; then
            echo "[patch ] $file"
            return 0
        fi
    fi

    return 1
}

#
# Use filter list to check directory name, if this name in filter list
# return 1, otherwise return 0
# $1: the specified directory name
#
filter_directory_name()
{
    dir_name=$1

    for filter in $filter_list; do
        if [[ $dir_name = $filter* ]]; then
            return 1
        fi
    done

    return 0
}

#
# Use patch filter list to check patch name, if this name in filter list
# return 1, otherwise return 0
# $1: the specifyed patch name
#
filter_patch_name()
{
    patch_name=$1

    for filter in $filter_patch_list; do
        if [[ $patch_name = $filter ]]; then
            return 1
        fi
    done

    return 0
}

#
# Traverse the files in $1 directory
# $1: the directory would be traversed
#
traverse_regular_files()
{
    local dir=$1

    for file in $dir/*; do
        #
        # $file is a directory, we will do the below checking
        # 1. is a directory, but is not for an android platform specified
        # 2. is a directory for an android platform specified, but is not
        #    for android 4.4, skip
        # 3. is a directory for android 4.4, same as the first point.
        #
        if [ -d $file ]; then
            echo "[dir   ] $file"
            
            #
            # Check the directory name if it is for android 4.4,
            # and there are some MACOSX directories for MACOS in
            # some patches, it should also be skiped
            #
            dir_name=${file##*/} # Get the current directory name from path
            #if [[ ! $dir_name = *4.4* ]] || [[ $dir_name = *4.4-4.4.2* ]] || [[ $dir_name = *MACOSX* ]]; then
            #    echo "[info  ] The patches live in $file isn't for android 4.4, just skip"
            #    continue
            #fi
            filter_directory_name $dir_name
            if [ $? -eq 1 ]; then
                echo "[skip  ] $dir_name is not for android 4.4, just skip"
                continue
            fi

            # Traverse directory recursive
            traverse_regular_files $file
            continue
        fi

        #
        # patch check
        #
        is_patch $file  # Is patch?
        if [ $? -eq 0 ]; then # Yes
            patch_name=${file##*/}
            # is patch file, now filter patch
            filter_patch_name $patch_name
            if [ $? -eq 1 ]; then
                echo "[filtered] $file" >> $filtered_list
                continue
            fi
            patch_check $file

            continue
        fi

        #
        # Is an zip file
        #
        if [[ $file = *.zip ]]; then
            echo "[zip   ] $file"
            echo "[cmd   ] Extract $file to $1/temp/"
            unzip $file -d $1/temp > /dev/null

            # Traversal regular files in zip
            traverse_regular_files $1/temp
            rm -r $1/temp/* # Remove temp each time

            continue
        fi
        
        #
        # Unknown file
        #
        echo "[skip  ] Unknown $file, skip"

    done
}

find_path()
{
    file_line=$1
    file_dir=${file_line#*/} # Such as 'media/libstagefright/MPEG4Extractor.cpp'
    patched_file=${file_line##*/} # Such as 'MPEG4Extractor.cpp'

    #
    # Search relative path of patched file
    #
    echo "find . -name $patched_file" >> log.txt
    find_result=`find . -name $patched_file`
    cd_path= # the path we should enter to apply patch, such as: cd $cd_path; patch -p1 < a.patch; cd -
    for path in $find_result; do
        echo $path >> log.txt
        if [[ $path = *$file_dir ]]; then
            echo ${path%$file_dir*} >> log.txt
            cd_path+=" "${path%$file_dir*}
        fi
    done

    echo $cd_path
}

get_patch_path()
{
    path=
    patch_file=$1

    # Get all the lines begain with '+++', such as '+++ b/media/libstagefright/MPEG4Extractor.cpp'
    file_lines=`sed -n -e '/^+++/p' $patch_file`
    if [ ${#file_lines[@]} -eq 0 ]; then
        echo ""
        return 1
    fi
    for line in $file_lines; do
        if [[ $line = +++* ]]; then
            continue
        fi
        echo $line >> log.txt
        path+=" "$(find_path $line)
    done

    echo $path
    return 0
}

log_check()
{
    dir=$1
    change_id=$2
    subject_title=$3

    if [ ${#dir} -eq 0 ]; then
        reutrn 1
    fi
    
    cd $dir

    echo "$PWD: git log > log.txt" >> /home/jakebo/work/bcc8916-tais/log.txt
    git log > git_log.txt
    if [ $? -ne 0 ]; then
        echo "$PWD: $dir: git log failed!!!" >> /home/jakebo/work/bcc8916-tais/log.txt
        cd -
        rm git_log.txt
        return 1
    fi

    grep $change_id git_log.txt
    if [ $? -eq 0 ]; then
        echo "[cmd  ] grep $subject_title git_log.txt"
        grep "$subject_title" git_log.txt
        if [ $? -eq 0 ]; then
            rm git_log.txt
            cd -
            return 0
        fi
    fi
    
    rm git_log.txt
    cd -
    return 1
}

get_change_id()
{
    patch_file=$1

    line=`grep "Change-Id:" $patch_file`
    change_id=${line##*Change-Id: }

    echo $change_id
}

get_subject_title()
{
    patch_file=$1

    line=`sed -n -e '/Subject:/p' $patch_file`
    subject_title=${line##*] }

    echo "${subject_title[@]}"
}

#
# Patch an specified file
# $1: the specified patch file, such as a.patch/a.diff
#
patch_check()
{
    patch_file=$1

    path=$(get_patch_path $patch_file)
    change_id=$(get_change_id $patch_file)
    subject_title=$(get_subject_title $patch_file)
    echo "[SUBTIT] ${subject_title[@]}"

    if [ ${#path[@]} -eq 0 ]; then
        return 1;
    fi
    echo "[PATH ]: ${path[@]}"
    for dir in $path; do
        log_check $dir $change_id "$subject_title"
        if [ $? -eq 0 ]; then
            let success_count=success_count+1
            echo "[$success_count] $patch_file" >> $success_list
            echo "  $dir: ChangeId: $change_id, ${subject_title[@]}" >> $success_list
            echo " " >> $success_list
            return 0
        fi
    done

    let fail_count=fail_count+1
    echo "[$fail_count] $patch_file" >> $fail_list
    echo "  ${path[@]}" >> $fail_list
    echo "  ChangeId: $change_id, ${subject_title[@]}" >> $fail_list
    echo " " >> $fail_list
    
    return 1
}

traverse_regular_files $patch_dir

echo "===========================================================" >> $success_list
echo "Successful count: $success_count" >> $success_list
echo "===========================================================" >> $fail_list
echo "Failed count: $fail_count" >> $fail_list

