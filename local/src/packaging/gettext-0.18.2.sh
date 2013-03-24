#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=gettext
VER=0.18.2
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/text"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	#lt_cv_deplibs_check_method='pass_all' \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --disable-java --disable-native-java --disable-rpath --disable-openmp --enable-threads=win32 --enable-relocatable --prefix="${INSTALL_TARGET}"
}

post_configure() {
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make GNULIB_MEMCHR=0 install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	# gettext-runtime
	RBINZIP=${MOD}-runtime-${VER}-${REV}-bin_${ARCH} &&
	RDEVZIP=${MOD}-runtime-dev-${VER}-${REV}_${ARCH} &&
#	pack_archive "${RBINZIP}" bin/{libasprintf,libintl,intl}*.dll &&
	pack_archive "${RBINZIP}" bin/{libasprintf,libintl}*.dll &&
	pack_archive "${RDEVZIP}" include/{autosprintf,libintl}.h lib/lib{libasprintf,intl}*.a share/{aclocal,doc,gettext,info} share/man/man3 &&
	store_packed_archive "${RBINZIP}" &&
	store_packed_archive "${RDEVZIP}" &&
	# gettext-tools
	TDEVZIP=${MOD}-tools-dev-${VER}-${REV}_${ARCH} &&
	TTOOLSZIP=${MOD}-tools-${VER}-${REV}-tools_${ARCH} &&
	pack_archive "${TDEVZIP}" include/gettext-po.h lib/libgettext*.a share/man/man1 &&
	pack_archive "${TTOOLSZIP}" bin/*.{exe,manifest,local} bin/libgettext*.dll bin/{autopoint,gettext.sh,gettextize} lib/gettext share/locale share/man/man1 &&
	store_packed_archive "${TDEVZIP}" &&
	store_packed_archive "${TTOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} glib libcroco libiconv libxml2`

#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

run_expand_archive &&
cd "${DIRECTORY}" &&
pre_configure &&
run_configure &&
post_configure &&

pre_make &&
run_make &&

pre_pack &&
run_pack_archive &&

echo success completed.

) 2>&1 | tee ${PWD}/${THIS}.log


echo done.

