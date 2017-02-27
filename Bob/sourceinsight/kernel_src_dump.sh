#!/bin/bash - 
#===============================================================================
#          FILE:  kernel_src_dump.sh
#         USAGE:  ./kernel_src_dump.sh 
#   DESCRIPTION:  
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: LuoQiaofa (Luoqf), luoqiaofa@163.com
#  ORGANIZATION: 
#       CREATED: 2017年01月06日 09时54分22秒 UTC
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error
ROOT_DIR=${ANDROID_BUILD_TOP}
KERNEL_DIR=${ROOT_DIR}/kernel/msm-3.18
KERNEL_OUT=${OUT}/obj/KERNEL_OBJ
KERNEL_SRC_LIST_FILE=${ROOT_DIR}/kernel_src.txt
KERNEL_OUT_BASE_PATH=`echo ${KERNEL_OUT} | sed "s:${ROOT_DIR}/::g"`
echo KERNEL_OUT_BASE_PATH=${KERNEL_OUT_BASE_PATH}

cd ${ROOT_DIR}
find ${KERNEL_OUT_BASE_PATH}/ -type f -name ".*\.o\.cmd" | \
    sed -f ${ROOT_DIR}/kernel_filter.sed > ${ROOT_DIR}/kernel_src_tmp1.txt

while read l
do 
    sed -n -f ${ROOT_DIR}/kernel.sed $l | sort -u >> ${ROOT_DIR}/kernel_src_tmp2.txt
done < ${ROOT_DIR}/kernel_src_tmp1.txt

export LC_ALL=C
sort -u ${ROOT_DIR}/kernel_src_tmp2.txt > ${ROOT_DIR}/kernel_src_tmp3.txt

find ${KERNEL_OUT}/include/generated -type f >> ${ROOT_DIR}/kernel_src_tmp3.txt

sed -e "s:^\([^\/].*\):${KERNEL_OUT_BASE_PATH}/\1:g" ${ROOT_DIR}/kernel_src_tmp3.txt  > ${ROOT_DIR}/kernel_src_tmp4.txt
sed -e "s:${ROOT_DIR}/::g" ${ROOT_DIR}/kernel_src_tmp4.txt > ${ROOT_DIR}/kernel_src_tmp5.txt

while read l
do 
    [ -f $l ] && echo $l >> ${ROOT_DIR}/kernel_src_tmp6.txt
done < ${ROOT_DIR}/kernel_src_tmp5.txt
sort -u ${ROOT_DIR}/kernel_src_tmp6.txt > ${KERNEL_SRC_LIST_FILE}

rm -rf ${ROOT_DIR}/kernel_src_tmp*.txt

