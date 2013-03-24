#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=gegl
VER=0.2.0
PATCH=2+nmu1.debian
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
ARCHIVE="${MOD}-${VER}"
PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${PATCH}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${PATCH}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${PATCH}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${PATCH}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}" &&
	cd "${DIRECTORY}" &&
	name=`find_archive "${ARCHIVEDIR}" ${PATCH_ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}" &&
	for fl in `cat debian/patches/series`
	do
		patch --batch -p 1 -i debian/patches/${fl}
	done &&
	cd ..
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	#lt_cv_deplibs_check_method='pass_all' \
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --disable-docs --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh &&
	sed -i.orig -e "s/#\(libgegl =\)/\1/" `find . -name Makefile `
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make SHREXT=".dll" all install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll lib/gegl-0.2/*.dll &&
	pack_archive "${DEVZIP}" include lib/*.a lib/gegl-0.2/*.a lib/pkgconfig &&
	pack_archive "${TOOLSZIP}" bin/*.{exe,manifest,local} &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib gettext-runtime glib`

#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

XLIBRARY_SET=${XLIBRARY}/gimp_build_set

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
