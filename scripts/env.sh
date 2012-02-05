
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

export XMINGW=/usr/xmingw/xmingw32
#export XMINGW=`dirname "$0"`

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

export XLOCAL=${XMINGW}/local
export XLIBRARY=${XLOCAL}/libs
export XLIBRARY_SET=${XLIBRARY}/default_set

export TARGET=mingw32
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

export BUILD_CC="${XMINGW}/bin/build-cc "



