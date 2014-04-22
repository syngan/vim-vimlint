#!/bin/sh

#PATH=/usr/local/bin:/bin:/usr/bin

usage()
{
	cat <<EOF >&2
Usage ${0##*/} [-p <dir>] [-l <dir>] [-h] {<file>|<dir>} ...
 -p <dir>	look for vim-vimlparser in <dir>
 -l <dir>	look for vim-vimlint in <dir>
 -h		print this message and exit
EOF
	exit 1
}


VOPT=
while getopts 'hl:p:' OPT; do
	case "$OPT" in
	p)
		if [ ! -f "${OPTARG}/autoload/vimlparser.vim" ]; then
			usage
		fi
		VOPT="$VOPT -c 'set rtp+=$OPTARG'"
		shift ;;
	l)
		if [ ! -f "${OPTARG}/autoload/vimlint.vim" ]; then
			usage
		fi
		VOPT="$VOPT -c 'set rtp+=$OPTARG'"
		shift ;;
	*)
		usage ;;
	esac
	shift; OPTIND=1
done

TF=$( mktemp -t "${0##*/}"-$$.XXXXXXXX ) || exit 1
trap 'rm -f "$TF"' EXIT HUP INT QUIT TERM

RET=0
while [ $# -gt 0 ]; do
	if [ -n "$1" -a \( -f "$1" -o -d "$1" \) ]; then
		cat /dev/null >"$TF" || exit 1
		vim $VOPT \
			-c "call vimlint#vimlint('$1', {'quiet':  1, 'output': '$TF'})" \
			-c 'qall!' >/dev/null 2>&1
		egrep -w 'Error|Warning' "$TF" && RET=2
	else
		echo "${0##*/}: $1 not found" >&2
	fi
	shift
done

exit $RET

# EOF
