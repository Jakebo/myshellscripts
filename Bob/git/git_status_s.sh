#!/bin/bash - 
#===============================================================================
#          FILE:  git_status_s.sh
#         USAGE:  ./git_status_s.sh 
#   DESCRIPTION:  
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: LuoQiaofa (Luoqf)_ luoqiaofa@163.com
#  ORGANIZATION: 
#       CREATED: 01/13/2016 05:34:28 PM CST
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error
root_path=`pwd`
#top_path=${ANDROID_BUILD_TOP}
#base_path=`echo $root_path | sed -e "s:${top_path}/::g"`
kernel_prj_path=`repo forall -p kernel -c pwd | sed -n "2p"`
base_path=`echo ${kernel_prj_path} | sed -n -e "s/kernel$//gp"`
#echo ${base_path}
#git status -s | sed -e "s:\(^ *[^ ]*\)  *\(.*\):\1 ${base_path}/\2:g"
repo forall -c pwd | sed -n -e "s:${base_path}::gp" > prj_list.txt
while read prj
do
    #echo prj=$prj
    cd ${prj}
    git status -s | sed -n -e "s:\( *[^ ]\+\) \([^ ]\+$\):\1 ${prj}/\2:gp"
    cd ${root_path}
done < prj_list.txt

