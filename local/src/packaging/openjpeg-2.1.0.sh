#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=openjpeg
	[ "" = "${VER}" ] && VER=2.1.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
lcms2
libpng
tiff
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	${XMINGW}/cross-cmake -DCMAKE_BUILD_TYPE:string="Release" -DCMAKE_C_FLAGS_RELEASE:string="-DNDEBUG" -DCMAKE_INSTALL_PREFIX="${INSTALL_TARGET}" -DBUILD_SHARED_LIBS:bool=ON \
	-DBUILD_JP3D:bool=ON \
	-DPNG_LIBNAME:string="png16" \
	-DPNG_PNG_INCLUDE_DIR:string="`${XMINGW}/cross pkg-config libpng16 --variable=includedir`" \
	-DPNG_LIBRARY:string="`${XMINGW}/cross pkg-config libpng16 --libs-only-l`" \
	-DBUILD_PKGCONFIG_FILES:bool=ON \
	-DBUILD_DOC:bool=ON
#	-DBUILD_JPWL:bool=ON \
#	-DBUILD_MJ2:bool=ON \
#	-DBUILD_THIRDPARTY:bool=ON \
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# libopenjp3d.dll がコピーされない。
	cp bin/*.dll "${INSTALL_TARGET}/bin/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/openjpeg* lib/pkgconfig share/man/man3 &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


