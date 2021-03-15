#!/bin/bash

ARCH_HOME=${ARCH_HOME:=~/recordutil}
source $ARCH_HOME/commond.sh

function find_name()
{
	if [ $(isrootdir "$1") -eq 0 ] && [ -n "$2" ]; then
		for dir in $(find $1 -maxdepth 1 -type d)
		do
		
			dst_file=$(find $dir -name "*.txt" | head -n1)
			txt=$( grep "$2"  <$dst_file )
			if [ -n "$txt" ]; then
				printf '\n' 
				info "编号" $dir
				return 0
			else 
				printf '.'
			fi
		done
			
	fi

		
}
case "$2" in
	--name)
		find_name $1 $3
		;;
	*)
		;;
esac
