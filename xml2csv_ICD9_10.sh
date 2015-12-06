#!/usr/bin/bash

##脚本主要实现将xml格式数据转化成csv格式
##
##根据csv规范:
####逗号、双引号等字段必须放于引号内
####字段内部引号必须在其前面增加一个引号来实现文字引号的转码
####
####
##本项csv格式数据第一列、第四列、第七列字段无需添加引号
##其余四列包含空格及符号，需要添加引号
##其中，存在缺失数据，共有四处，暂用空字符代替
##
##
##   基本步骤：从xml文件中读取<p>xxxx</p>标记段内字符串，根据文件
############  要求，每7个标记作为一项记录，输出到一行中，在第7个标
############  记字符串后添加换行符。
##    P.S:   第一行中，第一、四、七列需手动添加引号;
##           由于原文档中第一页表头在最后一页也出现了，导致csv文件
##           中存在重复一条记录(第65537行与第一行重复)，手动删除；
##
##USAGE: ./xml2csv_ICD9_10.sh xxx.xml xxx.csv
##

inputfile=$1 # xmlfile
outputfile=$2 # csvfile

read_dom() {
    local oldIFS=$IFS
    
    local IFS=\>
    read -d \< ENTITY CONTENT
}

VAR=1
while read_dom; do
    if [[ "$ENTITY" = "P" ]]; then    # 读取<p>....</p>字段
	
	if [[ "$(($VAR % 7))" = "0" ]]; then    #第七列添加换行符
	    echo -e "$CONTENT" >>$outputfile
	elif [[ "$(($VAR % 7))" = "1" ]]; then    #第一列相应处理
	    if [[ "$CONTENT" = "654.50" ]]; then   #该段ICD-9代码缺少英文名称，以空格代替
		echo -e "$CONTENT,\"\",\c" >>$outputfile
		VAR=$[$VAR+1]
	    else
		echo -e "$CONTENT,\c" >>$outputfile
	    fi
	    
	elif [[ $(($VAR % 7)) = 4 ]]; then    #第四列相应处理，存在部分ICD-10代码缺失，部分ICD-10代码对应中、英名缺失
	    if [[ "$CONTENT" = "NoDx" ||  "$CONTENT" = "S82829F" || "$CONTENT" = "V1031xA" ]]; then
		echo -e "$CONTENT,\"\",\"\",\c" >>$outputfile
		VAR=$[$VAR+2]
	    elif [[ "$CONTENT" = "T8601" || "$CONTENT" = "T8603" ]]; then
		echo -e "$CONTENT,\"\",\c" >>$outputfile
		VAR=$[$VAR+1]
	    else
		echo -e "$CONTENT,\c" >>$outputfile
	    fi
	else
	    echo -e "\"$CONTENT\",\c" >>$outputfile
	fi
	VAR=$[$VAR+1]
    fi
done < $inputfile
