#!/bin/bash - 
#===============================================================================
#
#          FILE:  android_find_module.sh
# 
#         USAGE:  ./android_find_module.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: LuoQiaofa
#  ORGANIZATION: 
#       CREATED: 2015年01月08日 18时06分14秒 HKT
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

args_num=$#
modules=$@
first_mod=$1
flist_name=$1
if [ -f ${first_mod} ]
then
    modules=(`cat ${first_mod}`)
    flist_name=${modules[0]}
fi

filter_dirs="EXECUTABLES SHARED_LIBRARIES STATIC_LIBRARIES"
test_prj=frameworks/base
base_dir=`repo forall -p ${test_prj}  -c pwd | tail -n 1 | sed -n -e "s:/${test_prj}::gp"`
root_path=${base_dir}
echo root_path=${root_path}
deps=${flist_name}.dep
flist=${flist_name}.txt
echo generating ${flist} ...
#-type f -name '*.P' -exec cat >> ${deps} {} \;
obj_root=${ANDROID_PRODUCT_OUT}/obj*
module_dirs=
sed_scripts=`dirname $0`/dep2src.sed
#module_dirs=`find ${obj_root} -type d -iname "*${module}*"`
for module in ${modules[@]}
do
    for dir in $filter_dirs
    do
        one_dir=`find ${obj_root}/${dir} -type d -iname "*${module}*"`
        module_dirs="${module_dirs} ${one_dir}"
    done
done
#echo module_dirs= ${module_dirs}
str_pwd=${root_path}
pwd_str_sub=${str_pwd//\//\\\/}
for dir in $module_dirs
do
    echo "find files in ${dir}" | sed -e "s/${pwd_str_sub}\///g" 
    find ${dir} -type f -iname '*.[Pd]' -exec cat >> ${deps} {} \;
done
# for dir in $module_dirs
# do
#     find ${dir} -type f -iname "*${module}*.[Pd]" -exec cat >> ${deps} {} \;
# done
LC_ALL=C
sed -f ${sed_scripts} ${deps} | sort -u > ${flist}

for module in ${modules[@]}
do
    find ${ANDROID_PRODUCT_OUT}/system/etc -type f -name "${module}" >> ${flist}
done
sed -i -e "s/${pwd_str_sub}\///g" ${flist}
# rm ${deps}

echo generating ${flist} done !!!

