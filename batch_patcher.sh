#!/bin/bash

patch_dir=$1 # Root directory of patches
success_list="success_list.log" # File to store patches of applying
fail_list="fail_list.log" # File to store patches of applying failed
compile_log="compile.log" # File to store compile log
filtered_list="filtered.log" # File to store filter log

filter_list=`cat filter.txt` # The filters stored in filter.txt
filter_patch_list=`cat filter_patch.txt` # The patch filter sotred in filter.txt

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
# Is patch file?
# $1: the specified file
#
is_patch()
{
    file=$1
    
    #
    # $file is an patch file, in normal case, the patch name with
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
        # patch file check
        #
        is_patch $file
        if [ $? -eq 0 ]; then
            patch_name=${file##*/}
            # is patch file, now filter patch
            filter_patch_name $patch_name
            if [ $? -eq 1 ]; then
                echo "[filtered] $file" >> $filtered_list
                continue
            fi
            do_patch $file
            if [ $? -eq 2 ]; then
                echo "Failed to compile after applying $file"
                echo "Continue to apply the next patches?[Y] "
                read go
                case $go in
                    yes|y)
                        continue
                        ;;
                    no|n)
                        exit 1
                        ;;
                    *)
                        continue
                        ;;
                esac
                
            fi
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

#
# Patch an specified file
# $1: the specified patch file, such as a.patch/a.diff
#
do_patch()
{
    patch_file=$1
    b_find=0;

    #
    # Get the patch path, according the alter files in patch file,
    # then search the one of alter files in ASOP, and choice the
    # one of result in most matching
    #
    file_line=`sed -n -e '/^+++/p' $patch_file | head -n 1` # Such as '+++ b/media/libstagefright/MPEG4Extractor.cpp'
    file_dir=${file_line#*/} # Such as 'media/libstagefright/MPEG4Extractor.cpp'
    patched_file=${file_line##*/} # Such as 'MPEG4Extractor.cpp'

    #
    # Search relative path of patched file
    #
    find_result=`find . -name $patched_file`
    cd_path= # the path we should enter to apply patch, such as: cd $cd_path; patch -p1 < a.patch; cd -
    for path in $find_result; do
        if [[ $path = *$file_dir ]]; then
            b_find=1
            cd_path+=${path%$file_dir*}
            break
        fi
    done

    #
    # Return 1 if we could not find a appropriate path
    #
    if [ $b_find = 0 ]; then
	let fail_count=fail_count+1
        echo "[err   ] Could not find path for $patch_file"
        echo "$fail_count. [patch ] Could not find path for $patch_file" >> $fail_list
        return 1
    fi

    #
    # Ok, we got the appropriate path as "we thought"
    # apply the patch now
    #
    echo "[info  ] Change to $cd_path"
    cd $cd_path
    echo "[cmd   ] $PWD: patch -p1 < $patch_file"
    patch -p1 < $patch_file
    if [ $? -eq 0 ]; then
	cd -
        let success_count=success_count+1
        echo $patch_file >> $success_list
        #
        # Compile while patch apply successful
        #
        ##../compiler.sh "${cd_path}${file_dir}" $compile_log
        ##if [ $? -ne 0 ]; then
        ##    let compile_failed_count=compile_failed_count+1
        ##    echo [err   ] $patch_file >> $compile_log
        ##    return 2
        ##else
        ##    let compile_ok_count=compile_ok_count+1
        ##    echo [OK    ] $patch_file >> $compile_log
        ##fi
    else
	cd -
        let fail_count=fail_count+1
        echo $fail_count. [patch ] $patch_file >> $fail_list
        echo $patch_result >> $fail_list
        return 1
    fi

    return 0
}

#
# Parse root directory that patch live in, and apply the
# patch file directly, and unzip the tar file
# $1: the root directory
#
#parse_root_directory()
#{
#    for file in $patch_dir/*; do
#        if [[ $file = *.zip ]]; then
#            echo "[zip   ] $file"
#	    echo "[cmd   ] Extract $file to temp/"
#            unzip $file -d $patch_dir/temp > /dev/null

#            # Traversal regular files in zip
#            traverse_regular_files $patch_dir/temp
#            rm -r $patch_dir/temp/* # Remove the files from temp
#        else
# patch file check
#            is_patch $file
#            if [ $? -eq 0 ]; then
#                do_patch $file
#                continue
#            fi
#        fi

#
# Unknown file
#
#        echo "[info  ] Unknown $file, skip"

#    done
#}

#parse_root_directory $patch_dir
traverse_regular_files $patch_dir

echo "===========================================================" >> $success_list
echo "Successful count: $success_count" >> $success_list
echo "===========================================================" >> $fail_list
echo "Failed count: $fail_count" >> $fail_list
echo "===========================================================" >> $compile_log
echo "Successful count: $compile_ok_count failed count: $compile_failed_count" >> $compile_log
