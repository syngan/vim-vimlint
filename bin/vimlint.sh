#!/bin/sh
#set -x

#PATH=/usr/local/bin:/bin:/usr/bin

usage()
{
	cat <<EOF >&2
Usage ${0##*/} [-p <dir>][-l <dir>][-e errlv][-v][-E][-h][-c config] {<file>|<dir>} ...
 -p <dir>           look for vim-vimlparser in <dir>
 -l <dir>           look for vim-vimlint in <dir>
 -u                 invoke vim with '-u NONE -i NONE'
 -h                 print this message and exit
 -e EVLxxx=n        set error level for all variables
 -e EVLxxx.var=n    set error level for the variable "var"
                      n=1: none
                      n=3: warning
                      n=5: error
                    e.g. -e EVL103=1
                    e.g. -e EVL102.l:_=1
 -c key=value       e.g. -c func_abort=1
 -E                 report only error messages
 -v                 verbose mode
EOF
	exit 1
}

cleanup() {
  rm -f "$VF" "$TF"
}

if [ "$#" = 0 ]; then
	usage
fi

VF=$( mktemp -t "${0##*/}"-$$.XXXXXXXX ) || exit 1
trap cleanup EXIT HUP INT QUIT TERM

VERBOSE=0
VOPT="-c 'set rtp+=`pwd`'"
echo "call has_key(g:, \"vimlint#config\") | let g:vimlint#config = {}" > ${VF}
echo "let g:vimlint#config.quiet = 1" >> ${VF}
ERRGREP='Error|Warning'
while getopts 'hl:p:ue:vc:EX' OPT; do
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
	u)
		VOPT="$VOPT -u NONE -i NONE" ;;
	E)
		ERRGREP='Error' ;;
	X)
		ERRGREP='vimlint#vimlint' ;;  # Exception
	e)
		if [ `echo ${OPTARG} | grep '^EVL[0-9]\+=[135]$' | wc -l` = 1 ]; then
			E=`echo ${OPTARG} | sed 's/=.*//'`
			L=`echo ${OPTARG} | sed 's/.*=//'`
			echo "call has_key(g:vimlint#config, \"$E\") | let g:vimlint#config.$E={}" >> ${VF}
			echo "let g:vimlint#config.$E={\":\" : $L}" >> ${VF}
		elif [ `echo ${OPTARG} | grep '^EVL[0-9]\+\.[gbwtslva]:.\+=[135]$' | wc -l` = 1 ]; then
			E=`echo ${OPTARG} | sed 's/\..*//'`
			V=`echo ${OPTARG} | sed 's/EVL[0-9]*\.//;s/=.$//'`
			L=`echo ${OPTARG} | sed 's/.*=//'`
			echo "call has_key(g:vimlint#config, \"$E\") | let g:vimlint#config.$E={}" >> ${VF}
			echo "let g:vimlint#config.$E={\"$V\" : $L}" >> ${VF}
		else
			usage
		fi
		shift ;;
	c)
		if [ `echo ${OPTARG} | grep '^[a-z0-9_]\+=' | wc -l` = 1 ]; then
			K=`echo ${OPTARG} | sed 's/=.*//'`
			V=`echo ${OPTARG} | sed 's/^[a-z0-9_]\+=//'`
			echo "let g:vimlint#config.$K=$V" >> ${VF}
		else
			usage
		fi
		shift ;;
	v)
		VERBOSE=1 ;;
	*)
		usage ;;
	esac
	shift; OPTIND=1
done

TF=$( mktemp -t "${0##*/}"-$$.XXXXXXXX ) || exit 1

RET=0
VOPT="${VOPT} -c 'source ${VF}'"
VIMLINT_VIM=${VIMLINT_VIM:-vim}
while [ $# -gt 0 ]; do
	if [ -n "$1" -a \( -f "$1" -o -d "$1" \) ]; then
		cat /dev/null >"$TF" || exit 1
		VIM="$VIMLINT_VIM $VOPT -es -N -c 'call vimlint#vimlint(\"$1\", {\"output\": \"${TF}\"})' -c 'qall!'"
		eval "${VIM}" || exit
		if [ ${VERBOSE} = 0 ]; then
			egrep -a -w "${ERRGREP}" "$TF" && RET=2
		else
			cat "${TF}"
			egrep -a -w "${ERRGREP}" "$TF" > /dev/null 2>&1
			if [ $? = 0 ]; then
				RET=2
			fi
		fi
	fi
	shift
done

exit $RET

# EOF
