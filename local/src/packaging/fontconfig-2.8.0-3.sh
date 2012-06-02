#!/use/bin/bash
if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


run_expand_archive() {
	expand_archive "${XLIBRARY_SOURCES}/libs/pic/${ARCHIVE}" &&
	(cd "${DIRECTORY}" &&
		(gunzip "${XLIBRARY_SOURCES}/libs/pic/${DEBPATCH}" |
		patch -p 1))
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	#lt_cv_deplibs_check_method='pass_all' \
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
	CC_FOR_BUILD="build-cc" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-libxml2 --with-arch=mingw32 --prefix="${INSTALL_TARGET}"
}

post_configure() {
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll etc &&
	pack_archive "${DEVZIP}" include lib/*.{a,def} lib/pkgconfig share/doc share/man/man{3,5} &&
	pack_archive "${TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


MOD=fontconfig
VER=2.8.0
REV=3
ARCH=win32

ARCHIVE="${MOD}-${VER}.tar.gz"
DEBPATCH="${MOD}_${VER}-${REV}.diff.gz"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}

(

set -x

#DEPS=`latest --arch=${ARCH} libxml2 freetype iconv`

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

