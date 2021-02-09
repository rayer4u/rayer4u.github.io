#!/bin/bash
# seafile原生数据目录结构和s3后端的目录结构不一致，需要调整
# minio/my-fs-objects/9e07c8a3-881a-42d6-9e7e-7990800748fa/d2/c2eb3f1a3782471b7e43303adec6c8b855995e  ->
# minio/my-fs-objects/9e07c8a3-881a-42d6-9e7e-7990800748fa/d2c2eb3f1a3782471b7e43303adec6c8b855995e

if test $# -eq  0;
then
    echo "seafile_minio_mv.sh bucket [check]";
    exit 0;
fi

# 目录
root=$1

# 是否只检查，不转换
if test "$2" = "check";
then
    check=1
else
    check=0
fi

# echo $check

a=($(mc ls ${root}  | awk '{print $5}' ))

for i in "${a[@]}";
do
    # echo  "mc ls ${root}$i";
    b=($(mc ls ${root}$i | awk '{if(length($5)==3) {print $5}}'))

    for j in "${b[@]}";
    do 
        # echo  "mc ls ${root}$i$j";
        c=($(mc ls ${root}$i$j | awk '{{print $5}}'))
        for k in "${c[@]}";
        do 
            if test "$check" -eq 1 ;
            then
                cmd="mc ls ${root}$i$j$k"
                echo $cmd
            else
                cmd="mc mv ${root}$i$j$k ${root}$i${j:0:2}$k"
                eval $cmd
            fi
        done
    done
done