#!/bin/sh
#set -x
####################################################################
#
#
#
# @author GAN
####################################################################
#declare -r version=0.1

usage()
{
	if [ $# -ne 0 ]
	then
		echo "$@" >& 2
	fi


	cat <<- EOF 1>&2
Usage $0 [-h] [-r] [-d directory] file1 ...
    -h: print this message
	-d: output directory [/tmp/vimlint] 
	-r: recursive
EOF
}


OPT=
DIR=/tmp/vimlint
REC=0
while getopts hr OPT
do
	case $OPT in
	h)
		usage
		exit 1;;
	r)  REC=1 ;;
	\?)
		usage "invalid option"
		exit 1 ;;
	esac
done
shift `expr $OPTIND - 1`


check()
{
	echo "$1"
	BASE=`basename "$1"`
	vim -N -c "call vimlint#vimlint('$1', {'output': {'filename' : '${DIR}/${BASE}', 'append' : 1}})" -c "qall!" > /dev/null 2>&1
}


check_dir()
{
	for file in $1/*.vim
	do
		if [ -f "${file}" ]; then
			check "${file}" $2
		fi
	done

	if [ ${REC} = 1 ]; then
		for dir in $1/*
		do
			if [ -d ${dir} ]; then
				check_dir ${dir} $2
			fi
		done
	fi
}

mkdir -p ${DIR}
for file in "$@"
do
	if [ -f ${file} ]; then
		check ${file} ${DIR}
	elif [ -d ${file} ]; then
		check_dir ${file} ${DIR}
	fi
done


