#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=pango
VER=1.33.7
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	# --without-x が効いていない。
	# xft は x window 関係なので使わない。
	sed -i.orig -e's/,basic-x,/,/' \
				-e's|\(have_xft\)=true|\1=false|' configure
#	echo skip > /dev/null
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-debug=yes --enable-introspection=no --disable-gtk-doc --enable-explicit-deps=no --with-included-modules=yes --prefix="${INSTALL_TARGET}"
}

post_configure() {
#	cp config.h.win32 config.h &&
	bash ${XMINGW}/replibtool.sh shared mix
#	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack_archive() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll &&
	pack_archive "${DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/gtk-doc &&
	pack_archive "${TOOLSZIP}" bin/*.exe share/man &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}")
}


(

set -x

#DEPS=`latest --arch=${ARCH} glib fontconfig freetype harfbuzz cairo`

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

EXAMPLESZIP=${MOD}-${VER}-${REV}-examples_${ARCH} &&
7z a ${EXAMPLESZIP}.7z examples/*.exe examples/.libs &&

TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCH} &&
7z a ${EXAMPLESZIP}.7z tests/*.exe tests/.libs tests/*.{txt,utf8,sh} &&

echo success completed.

) 2>&1 | tee ${PWD}/${THIS}.log


echo done.

