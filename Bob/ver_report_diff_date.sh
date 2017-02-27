#!/bin/bash
#===============================================================================
#          FILE:  ver_report_diff_date.sh
#         USAGE:  ./ver_report_diff_date.sh
#   DESCRIPTION:  
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: LuoQiaofa (Luoqf), luoqiaofa@163.com
#  ORGANIZATION: 
#       CREATED: 01/13/2016 05:34:28 PM CST
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error
function usage_help()
{

    echo "usage     : ./`basename $0` start_date end_date <out_htm_file_name>"
    echo "start_tags: date started"
    echo "end_tags  : date ended"
    echo "example   : ./`basename $0` 2016-05-11 2016-06-12 202.01.00.0002_report.htm"
    echo "note      : the start_date should be earlier than the end_date"
    return 1
}

root_path=$PWD
out_htm_file=${root_path}/ver_rls_report.htm
if [ $# -lt 2 ]
then
    usage_help
    exit 1
elif [ $# -eq 3 ]
then
    out_htm_file=$3
else
    date_old=$1
    date_new=$2
fi
date_old=$1
date_new=$2
echo Tag diff report: old=${date_old},new=${date_new}
kernel_prj_path=`repo forall -p kernel -c pwd | xargs echo | awk '{print $3}'`
prj_base=`echo ${kernel_prj_path} | sed -n -e "s/kernel$//gp"`
prj_list_file=${root_path}/prj_list.txt
repo forall -c pwd | sed -n -e "s:${prj_base}::gp" > ${prj_list_file}
prj_ver_gen=`dirname $0`
cd ${root_path}
htm_file_tmp=${root_path}/ver_rls_tmp.htm
numstat_tmp=${root_path}/numstat_tmp.txt
file_report=${root_path}/report_file.txt
[ -f ${out_htm_file} ] && rm ${out_htm_file}
[ -f ${htm_file_tmp} ] && rm ${htm_file_tmp}
[ -f ${numstat_tmp} ] && rm ${numstat_tmp}
[ -f ${file_report} ] && rm ${file_report}
touch ${file_report}
cat << EOF > ${out_htm_file}
<!DOCTYPE html>
<html>
<body>
<head>
<!--
<meta charset="GB18030">
-->
<meta charset="UTF-8">
<style type="text/css">
table, td, th
{
    text-align:left;
}
th
{
    height:20px;
}
</style>
</head>
EOF

total_add=0
total_del=0
total_chg=0
cat << EOF >> ${htm_file_tmp}
<table border="1" width="100">
    <tr>
        <th>File</th>
        <th>Added</th>
        <th>Deleted</th>
        <th>Author</th>
        <th>HASH</th>
        <th>Comment</th>
    </tr>
EOF
while read prj
do
    #echo prj: "${prj}"
    cd ${prj}
    time_from=${date_old}
    time_to=${date_new}
    echo ${prj}: time_from="'"${time_from}"'", time_to="'"${time_to}"'"
    tmp_gen_file=${root_path}/tmp_gen.txt
    git log --after={${time_from}} --before={${time_to}} --pretty=format:"%H" > ${tmp_gen_file}
    echo "" >> ${tmp_gen_file}
    #cat ${tmp_gen_file}
    commit_old=`tail -n 1 ${tmp_gen_file}`
    commit_new=`head -n 1 ${tmp_gen_file}`
    echo ${prj}: old="'"${commit_old}"'", new="'"${commit_new}"'"
    if [ -n "${commit_old}" ]
    then
        while read id
        do
            echo commit_id=${id}
            author=`git log -1 --pretty=format:"%ae" "${id}"`
            comment=`git log -1 --pretty=format:"%s" "${id}"`
            git show -1 --numstat --pretty=format:"" ${id} | \
                sed "/^$/d" > ${numstat_tmp}
            #echo author=${author}
            #echo comment=${comment}
            row_span=`wc -l ${numstat_tmp} | awk '{print $1}'`
            #echo rows_span=${row_span}
            if [ ${row_span} -eq 0 ]
            then
                continue
            fi
            line_state=1
            while read add del file
            do
                echo add=$add,del=$del,file=$file
                [ "${add}" == "-" ] && add=0
                [ "${del}" == "-" ] && del=0
                total_add=$((total_add+add))
                total_del=$((total_del+del))
                f_exist=`grep "${prj}/${file}" ${file_report}`
                if [ -z ${f_exist} ] 
                then
                   echo "${prj}/${file}" >> ${file_report}
                fi
                if [ ${line_state} -eq 1 ]
                then
                    file=${prj}/${file}
                    cat << EOF >> ${htm_file_tmp}
        <tr>
            <td>${file}</td>
            <td>${add}</td>
            <td>${del}</td>
            <td rowspan="${row_span}">${author}</td>
            <td rowspan="${row_span}">${id}</td>
            <td rowspan="${row_span}">${comment}</td>
        </tr>
EOF
                else
                    file=${prj}/${file}
                    echo file=${file}
                    echo add=${add}
                    echo del=${del}
                    cat << EOF >> ${htm_file_tmp}
        <tr>
            <td>${file}</td>
            <td>${add}</td>
            <td>${del}</td>
        </tr>
EOF
                fi
                line_state=$((line_state+1))
                # echo line_state=${line_state}
            done < ${numstat_tmp}
        done < ${tmp_gen_file}
    else
        cd ${root_path}
        continue 
    fi

    cd ${root_path}
done < ${prj_list_file}
echo "</table>" >> ${htm_file_tmp}

total_chg=$((total_add+total_del))
echo total_add=${total_add}
echo total_del=${total_del}
echo total_chg=${total_chg}

files_chg_cnt=`wc -l ${file_report} | awk '{print $1}'`
echo files_chg_cnt=${files_chg_cnt}


cat << EOF >> ${out_htm_file}
<h2>Changes summary:</h2>
<table border="1" >
    <tr>
        <td>Lines_Added</td>
        <td>${total_add}</td>
    </tr>
    <tr>
        <td>Lines_Deleted</td>
        <td>${total_del}</td>
    </tr>
    <tr>
        <td>Files_Changed</td>
        <td>${total_chg}</td>
    </tr>
    <tr>
        <td>total_files_changed</td>
        <td>${files_chg_cnt}</td>
    </tr>
</table>
EOF

echo "<h2>Changes detail:</h2>" >> ${out_htm_file}
cat ${htm_file_tmp} >> ${out_htm_file}
cat << EOF >> ${out_htm_file}
</table>
</body>
</html>
EOF
rm ${tmp_gen_file}
rm ${htm_file_tmp}
#rm ${file_report}
#rm -rf ${prj_list_file}
