#!/bin/sh
set -e

usage()
{
	if [ $# -ne 0 ]
	then
		echo "$@" >& 2
	fi


	cat <<- EOF 1>&2
	Usage $0 [-h] file ...
	    -h: print this message
EOF
}


OPT=
DIR=
while getopts h OPT
do
	case $OPT in
	d)
		DIR=$OPTARG ;;
	h)
		usage
		exit 1;;
	\?)
		usage "invalid option"
		exit 1 ;;
	esac
done
shift `expr $OPTIND - 1`

TMPFILE=/tmp/vimlint.$$.tmp

for file in "$@"
do
	vim -c 'call vimlint#vimlint("'${file}'", {"output" : "'${TMPFILE}'"})' -c 'qall!' > /dev/null 2>&1
	cat ${TMPFILE}
	rm -f ${TMPFILE}
done


# EOF

