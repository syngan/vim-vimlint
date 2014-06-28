#!/bin/sh
set -e

usage()
{
	if [ $# -ne 0 ]
	then
		echo "$@" >& 2
	fi


	cat <<- EOF 1>&2
	Usage $0 [-h][-p vimlparser][-l vimlint] okfile ngfile
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
		VPARS="-p $OPTARG" ;;
	l)
		if [ ! -f "${OPTARG}/autoload/vimlint.vim" ]; then
			usage
			exit 1
		fi
		VLINT="-l $OPTARG" ;;
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

if [ "$#" -ne 2 ]; then
	usage
	exit 1
fi
VOPT=${VPARS} ${VLINT}

FILE=/tmp/err.sh.$$
./bin/vimlint.sh ${VOPT} $1
RET=$?
echo "ok: RET=${RET}"
if [ ${RET} -ne 0 ]; then
	echo "err end"
	exit 2
fi

./bin/vimlint.sh ${VOPT} $2 &
wait $! || RET=$? || echo "ng: RET=${RET}"
echo "ng: RET=${RET}"
if [ ${RET} = 0 ]; then
	echo "err end"
	exit 2
fi

echo "normal end"
exit 0

# EOF

