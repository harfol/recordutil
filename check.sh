#!/bin/bash

ARCH_HOME=${ARCH_HOME:=~/recordutil}
source $ARCH_HOME/commond.sh
function format()
{
	# 中文括号
	if [ -d $1 ]; then
		for dir in $(find $1 -type d  | grep -E '（|）|\ '  )
		do
			warning '格式错误' $dir
		done
	fi
		
}

function archive()
{
	if [ -d $1 ]; then
		for dir in $( ls $1 | grep -E '!*[0-9]+-.*' )
		do
			page_sum=0
			scan_sum=0
			for txt in $( find $dir -name '*.txt' )
			do
				part=$(cat $txt | grep "份数" | sed -e 's/份数：//' -e 's/\r//' )
				page=$(cat $txt | grep "页数" | sed -e 's/页数：//' -e 's/\r//' )
				page_sum=$(( page_sum + part * page ))
				scan_sum=$(( scan_sum + 1 * page ))
			done
			printf "盒号：%-5s 测量编号：%-20s 总页数：%-5d 扫描页数：%-5d\n" "${dir%%-*}" "${dir#*-}" $page_sum $scan_sum
		done
	fi

}

function find_name()
{
	
	if [ -d $1 ] && [ -n "$2" ]; then
		for dir in $(find $1 -maxdepth 1 -type d)
		do
		
			dst_file=$(find $dir -name "*.txt" | head -n1)
			txt=$( cat $dst_file | grep "$2"  )
			if [ -n "$txt" ]; 
			then
				echo $dir
			fi 
		done
			
	fi

}


OLD_IFS=$IFS
IFS=$'\n'
find_name $1 $2
IFS=$OLD_IFS
