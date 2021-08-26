
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

XMINGW=/usr/xmingw/xmingw32
#XMINGW=`dirname "$0"`
XMINGW_PLATFORM=win32
while [ 0 -lt $# ]
do
  case "$1" in
  win32)
    XMINGW_PLATFORM=win32
    ;;
  win64)
    XMINGW_PLATFORM=win64
    ;;
  -*|--*|*)
  	if [ "" = "$1" ]
  	then
  		shift
  	    continue
  	fi
    echo "$0: unsupported option \`$1'."
#    echo "try \`$0 --help' for more information."
    return 1
    ;;
  esac
  shift
done
export XMINGW
export XMINGW_PLATFORM

if [ "" = "${XMINGW_ORIG_PATH}" ]
then
export XMINGW_ORIG_PATH=${PATH}
export XMINGW_ORIG_CC=${CC}
export XMINGW_ORIG_CXX=${CXX}
export XMINGW_ORIG_PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
export XMINGW_ORIG_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
export XMINGW_ORIG_MANPATH=${MANPATH}
export XMINGW_ORIG_INFOPATH=${INFOPATH}
export XMINGW_ORIG_C_INCLUDE_PATH=${C_INCLUDE_PATH}
export XMINGW_ORIG_CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}
export XMINGW_ORIG_LIBRARY_PATH=${LIBRARY_PATH}
export XMINGW_ORIG_ACLOCAL_FLAGS=${ACLOCAL_FLAGS}
fi

TARGET_win32=i686-w64-mingw32
TARGET_win64=x86_64-w64-mingw32
case "${XMINGW_PLATFORM}" in
win32)
	TARGET=${TARGET_win32}
	;;
win64)
	TARGET=${TARGET_win64}
	;;
*)
    echo "${LINENO}: INTERNAL ERROR: unsupported."
    return 1
	;;
esac
export TARGET
export XMINGW_TARGET="${TARGET}"

#__prefix=/usr/bin/i586-mingw32msvc-
#__prefix=${XMINGW}/bin/
#export AR="${__prefix}ar"
#export AS="${__prefix}as"
#export CC="${__prefix}cc "
#export CXX="${__prefix}g++ "
#export DLLTOOL="${__prefix}dlltool"
#export DLLWRAP="${__prefix}dllwrap"
#export NM="${__prefix}nm"
#export LD="${__prefix}ld"
#export OBJDUMP="${__prefix}objdump"
#export RANLIB="${__prefix}ranlib"
#export STRIP="${__prefix}strip"
#export WINDRES="${__prefix}windres"

#export EXEEXT=".exe"
#export SHREXT=".dll"

# gcc4 との C++ ABI 互換性を維持する。 gcc5 への対応。
#export OLD_CXX_ABI="-D_GLIBCXX_USE_CXX11_ABI=0"
export OLD_CXX_ABI=" "

export BUILD_CC="${XMINGW}/bin/cross-host cc "

export XLOCAL=${XMINGW}/local

case "${XMINGW_PLATFORM}" in
win32)
	XMINGW_BIN=${XMINGW}/bin
	;;
win64)
	XMINGW_BIN=${XMINGW}/bin64
	;;
*)
    echo "${LINENO}: INTERNAL ERROR: unsupported."
    return 1
	;;
esac
export XMINGW_BIN

case "${XMINGW_PLATFORM}" in
win32)
	XLIBRARY=${XLOCAL}/libs
	;;
win64)
	XLIBRARY=${XLOCAL}/libs64
	;;
*)
    echo "${LINENO}: INTERNAL ERROR: unsupported."
    return 1
	;;
esac
export XLIBRARY
export XLIBRARY_SET=${XLIBRARY}/default_set

if [ ! -e "${XMINGW_BIN}/${TARGET}-nm" ]
then
    echo "${LINENO}: WARNING: ターゲット名(${TARGET})と bin ディレクトリーのコマンド名の不一致があります。 configure がコマンドを見つけられない可能性があります。"
fi


