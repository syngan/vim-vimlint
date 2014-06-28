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
FILE=/tmp/vimlint.$$.tmp
RET=0
VLINT=
VPARS=
while getopts ho:l:p: OPT
do
	case $OPT in
	o)
		FILE=$OPTARG ;;
	p)
		if [ ! -f "${OPTARG}/autoload/vimlparser.vim" ]; then
			usage
			exit 1
		fi
		VPARS="$OPTARG" ;;
	l)
		if [ ! -f "${OPTARG}/autoload/vimlint.vim" ]; then
			usage
			exit 1
		fi
		VLINT="$OPTARG" ;;
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

VOPT=""
if [ "${VLINT}" != "" ]; then
	VOPT="${VOPT} -c 'set rtp+=${VLINT}'"
fi

if [ "${VPARS}" != "" ]; then
	VOPT="${VOPT} -c 'set rtp+=${VPARS}'"
fi
VOPT="${VOPT} -c 'set rtp+=`pwd`'"

for file in "$@"
do
	VIM="vim ${VOPT} -c 'call vimlint#vimlint(\"'${file}'\", {\"output\" : \"'${FILE}'\"})' -c 'qall!'"
	eval ${VIM} > /dev/null 2>&1
	if [ -f ${FILE} ]; then
		if [ `cat ${FILE} | wc -l` -gt 0 ]; then
			grep Error "${FILE}"
			if [ $? -eq 0 ]; then
				RET=1
			fi
			cat ${FILE}
		fi
		rm -f ${FILE}
	fi
done

exit ${RET}


# EOF

