#!/bin/bash - 
#===============================================================================
#          FILE:  repo_diff2patch.sh
#         USAGE:  ./repo_diff2patch.sh 
#   DESCRIPTION:  
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: LuoQiaofa (Luoqf), luoqiaofa@163.com
#  ORGANIZATION: 
#       CREATED: 2015年10月01日 13时42分39秒 HKT
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error
root_dir=${PWD}
#patch_file=${root_dir}/TO-Honeywell-20161115-20161130-01.patch
#patch_file=${root_dir}/TO_Honeywell_20161130_02-20161213_03.patch
patch_file=/media/public/share/test/01310-01610.patch

if ! [ -f ${patch_file} ]
then
    echo "Patch file ${patch_file} does not exist"
    exit 1
fi

TMP_PATCH=tmp.patch
project_lines_file=${root_dir}/projects.txt
grep -ns "^project " ${patch_file} | \
    awk 'BEGIN{FS=":"} {print $1}' > ${project_lines_file}
first_line=`head -n 1 ${project_lines_file}`
max_line=`wc -l ${project_lines_file} | awk '{print $1}'`
last_line=`sed -n "${max_line}p" ${project_lines_file}`
echo first_line=${first_line}
echo last_line=${last_line}
eof_line=`wc -l ${patch_file} | awk '{print $1}'`
while read line
do
    #echo line=$line
    if [ "${line}" == "${first_line}" ]
    then
        project_cur=`sed -n "${line}p" ${patch_file} | awk '{print $2}'`
        start_line=$((line+1))
        continue
    fi
    #echo project_cur=${project_cur}
    echo cd project: ${project_cur}
    cd ${project_cur}
    project_cur=`sed -n "${line}p" ${patch_file} | awk '{print $2}'`
    end_line=$((line-1))
    sed -n "${start_line},${end_line}p" ${patch_file} > ${TMP_PATCH}
    # cat ${TMP_PATCH}
    # patch tmp patch file
    echo 'patch -p1 <' ${TMP_PATCH}
    patch -p1 < ${TMP_PATCH}
    cd ${root_dir}
    start_line=$((line+1))
    if [ "${last_line}" == "${line}" ]
    then
        #echo project_cur=${project_cur}
        echo cd project: ${project_cur}
        cd ${project_cur}
        end_line=${eof_line}
        sed -n "${start_line},${end_line}p" ${patch_file} > ${TMP_PATCH}
        # # patch tmp patch file
        echo 'patch -p1 <' ${TMP_PATCH}
        patch -p1 < ${TMP_PATCH}
        # cat ${TMP_PATCH}
        break
    fi
done < ${project_lines_file}
cd ${root_dir}

