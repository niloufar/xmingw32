#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func

#XLIBRARY_SET=${XLIBRARY}/gimp_build_set


MOD=pthreads
VER=2.9.1
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/etc"
ARCHIVE="${MOD}-w32-`echo "${VER}" | sed -e"s/\./-/g"`-release"
DIRECTORY="${MOD}-w32-`echo "${VER}" | sed -e"s/\./-/g"`-release"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}

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
	echo skip > /dev/null
}

post_configure() {
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make -f GNUmakefile \
		OPT="\$(CLEANUP) \
			`${XMINGW}/cross --archcflags` \
			-pipe -O2 -fomit-frame-pointer -ffast-math" \
		LFLAGS="-Wl,--enable-auto-image-base -Wl,-s" \
		CROSS=mingw32- DEVROOT="${INSTALL_TARGET}" \
		clean GC-inlined GCE-inlined
}

pre_pack() {
	(mkdir -p "${INSTALL_TARGET}" &&
	cd "${INSTALL_TARGET}" &&
	mkdir -p bin &&
	mkdir -p include &&
	mkdir -p lib
	) &&
	(
	cp pthread.h semaphore.h sched.h "${INSTALL_TARGET}/include/." &&
	cp *.dll "${INSTALL_TARGET}/bin/." &&
	cp *.a "${INSTALL_TARGET}/lib/."
	)
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll &&
	pack_archive "${DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib gettext-runtime glib`

#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

#run_expand_archive &&
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

