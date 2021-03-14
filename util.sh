#!/bin/bash

ARCH_HOME=${ARCH_HOME:=~/recordutil}
CACHE_HOME=~/.archives

txt_dir=~/.archives/txt
jpg_dir=~/.archives/jpg
origin_dir=
pdf_dir=~/.archives/pdf
set -e
mkdir -p ~/.archives/{txt,jpg,pdf} 2>/dev/null


source $ARCH_HOME/commond.sh
function create_base_info() 
{ 
	echo "当前目录名 $PWD" dir_name=${PWD##*/} 
	measure_no=${dir_name#*-} 
	file_no=${dir_name%%-*} 
	echo "创建 ./bash_info.txt" 
	cat >./base_info.txt <<-EOF 
测量编号：$measure_no 
权属人： 档案号：江广集装证协字第[2000]00号 
案卷号：ZY001$file_no 
年份：2000
存放地址：1号柜
EOF
}

function create_file_info()
{
	for dir_info in $(ls)
	do
		if [ -d $dir_info ]; then
			file_name=$( echo $dir_info | tr -d "[0-9]" ).txt
			echo "创建 ${dir_info}/${file_name}"
			cat >${dir_info}/$file_name <<-EOF
提名：
副题名：
份数：
页数：
EOF
		   cat base_info.txt >>${dir_info}/$file_name
		fi
	 done
}
function clean_base_info()
{
	echo "清除 ./base_info.txt"
	rm -rf ./base_info.txt
}
function clean_cache()
{
	sudo rm -rf $CACHE_HOME/pdf/* $CACHE_HOME/jpg/* $CACHE_HOME/txt/*
}
function pdf_rename()
{
	if [ -d $1 ]; then
		OLD_IFS=$IFS
		IFS=$'\n'
		for pdf in $(find $1 -name '*.pdf')
		do 
			mkdir -p $pdf_dir/${pdf%/*} 2>/dev/null
			process '拷贝' "$pdf"
			# 汲取第一页pdf保存至/pdf
			if [ $(pdfinfo $pdf  | grep Pages | tr -s ' ' | cut -f2 -d' ') -gt 1 ] && \
				[ -z "$(echo ${pdf%/*} | grep -P '[^\x4e\x00-\x9f\xff]-[^\x4e\x00-\x9f\xff]')" ]; then
					dst_pdf_name=$pdf_dir/${pdf/.pdf/-0.pdf}
					python3 $ARCH_HOME/pdfone.py $pdf $dst_pdf_name
			else
				cp $pdf $pdf_dir/$pdf
			fi
			process_finish
		IFS=$OLD_IFS

		#删除/pdf内错误的pdf
	   done
	fi
}

function pdf_convert_jpg()
{
	if [ -d $pdf_dir ]; then
		OLD_IFS=$IFS
		IFS=$'\n'
		for pdf in $(find $pdf_dir -name '*.pdf')
		do
			jpg_file=${pdf//pdf/jpg}
			mkdir -p ${jpg_file%/*} 2>/dev/null
			process '生成图片' "$jpg_file"
			convert -colorspace RGB -resize 1800 -interlace none -density 300 -quality 100 $pdf $jpg_file 
			process_finish
		done
		IFS=$OLD_IFS
	fi
}

function jpg_convert_txt()
{
	if [ -d $jpg_dir ]; then
		OLD_IFS=$IFS
		IFS=$'\n'
		for jpg in $(find $jpg_dir -name '*.jpg')                  
		do
			path=${jpg%/*}
			path=${path/jpg/txt}
			mkdir -p $path 2>/dev/null

			txt_file=${jpg%.*}
			txt_file=${txt_file/jpg/txt}

			process '生成' "$txt_file"
			tesseract $jpg $txt_file -l eng+chi1 1>/dev/null 2>&1
			process_finish
		done
		IFS=$OLD_IFS
	fi
}

function origin_dir()
{
	if [ -d $1 ]; then
		for dir in $(find $1 -mindepth 1 -type d )
		do
			dir_name=${dir##*/}
			if [ -z "$(echo $dir_name | grep -P '[^\x4e\x00-\x9f\xff]-[^\x4e\x00-\x9f\xff]' )" ]; then
				name=$(echo $dir_name | sed 's/[0-9]*$//')
				num=$(echo $dir_name | sed 's/(.*)//' | tr -cd [0-9])
				echo "$name $num"
			else
			OLD_IFS=$IFS
			IFS=$' '
				for simple_dir in ${dir_name//-/ }
			  	do
				   echo  "$simple_dir 1"
			   	done
			fi
			IFS=$OLD_IFS
		done
	fi


}

function compile_dir()
{
	if [ -d $1 ]; then
		OLD_IFS=$IFS
		IFS=$'\n'
		# 去除 {}空格"空行 分割开的第一个
		normal=($(jq .normal <$ARCH_HOME/key.json | sed -e 's/{\|}\|,\| \|\"//g'  -e '/^$/d' ))
		# 数字排序后的结果
		for origin in $(origin_dir $1)
		do
			key=${origin%% *}
			com=""
			IFS=$' '
			for info in ${normal[@]}
			do
				sim=${info%:*}
				if [ "${key//$sim/}" != "$key" ]; then

					com=${info#*:}
					break
				fi
			done
			IFS=$'\n'
			if [ -n "$com"  ];
			then
				echo "$com ${origin#* }"
			else
				echo "$key ${origin#* }"
			fi
		done

		IFS=$OLD_IFS	
	fi

}

function auto_dir()
{
	if [ -d $1 ]; then
		OLD_IFS=$IFS
		IFS=$'\n'
		auto=""
		important=($(jq .important <$ARCH_HOME/key.json | sed -e 's/\[\|\]\|\"\|,\| //g' -e '/^$/d'))
		for origin in $(origin_dir $1)
		do
			key=${origin% *}
			IFS=$' '
			for imp in ${important[@]}
			do
				if [ "${key//${imp%:*}/}" != "$key" ]; then
					auto+="$key "	
				fi
			done
		done

		clean_cache
		echo $auto
		IFS=$' '
		for dst in ${auto[@]}
		do
			dir=$( find $1 -type d | grep "$dst" )
			pdf_rename $dir
		done
			pdf_convert_jpg
			jpg_convert_txt
		IFS=$OLD_IFS	
	fi
}


case "$1" in
	base)
		create_base_info
		;;
	info)
		create_file_info
		;;
	rename)
		pdf_rename $2
		;;
	pdf2jpg)
		pdf_convert_jpg
		;;
	jpg2txt)
		jpg_convert_txt
		;;
	autodir)
		auto_dir $2
		;;
	gendir)
		compile_dir $2
		;;
	genorigin)
		origin_dir $2
		;;
	clean)                          
		clean_cache
		;;
	*)
		;;
esac
#tree $CACHE_HOME
