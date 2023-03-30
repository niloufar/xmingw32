#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCHSUFFIX は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	XLIBRARY_SET="gimp_build"

	# package に返す変数。
	MOD=libjxl
	[ "" = "${VER}" ] && VER=0.8.1
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
#	__DOCZIP="${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}"
	__TOOLSZIP="${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}"

	# アーキテクチャを指定しない場合は NOARCH=yes する。
#	NOARCH=yes
}

dependencies() {
	cat <<EOS
brotli
highway
lcms2
openexr
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
BSD-3-Clause license 

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# [0.8.1] 暗黙の型変換はできない。
	if [[ "${VER}" == "0.8.1" ]]
	then
		sed -i.orig lib/extras/enc/jpg.cc \
			-e 's/\(jpeg_mem_dest(&cinfo, &buffer, \)\(&size);\)/\1(size_t*)\2/'
	fi
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	# win32 では -msse2 が必須だった。
	${XMINGW}/cross-cmake -G "Unix Makefiles" -H. -B. -DALLOW_IN_SOURCE_BUILD:bool=true -DCMAKE_BUILD_TYPE:string=RELEASE -DCMAKE_INSTALL_PREFIX:string="${INSTALL_TARGET}" \
	"-DCMAKE_C_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_CXX_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} -msse2 " \
	"-DCMAKE_C_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_CXX_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_SHARED_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s -Wl,--export-all-symbols" \
	"-DCMAKE_EXE_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s" \
	-DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=ON \
	-DJPEGXL_ENABLE_BENCHMARK=OFF -DJPEGXL_ENABLE_MANPAGES=OFF \
	-DJPEGXL_ENABLE_FUZZERS=OFF \
	-DJPEGXL_BUNDLE_LIBPNG=OFF \
	"-DPNG_PNG_INCLUDE_DIR=$(${XMINGW}/cross pkg-config libpng16 --variable=includedir)" \
	-DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
	-DJPEGXL_FORCE_SYSTEM_LCMS2=ON -DJPEGXL_ENABLE_SKCMS=OFF \
	-DJPEGXL_ENABLE_OPENEXR=ON \
	-DJPEGXL_FORCE_SYSTEM_HWY=ON \
	-DJPEGXL_ENABLE_JNI=OFF -DJPEGXL_ENABLE_PLUGINS=OFF \
	-DJPEGXL_ENABLE_SJPEG=OFF \
	-DJPEGXL_BUNDLE_SKCMS=OFF -DJPEGXL_ENABLE_SKCMS=OFF \
	-DJPEGXL_ENABLE_DEVTOOLS=ON \
	-DJPEGXL_FORCE_SYSTEM_GTEST=ON \
	-DJPEGXL_ENABLE_VIEWERS=OFF \
	-DJPEGXL_ENABLE_DOXYGEN=OFF
#	-DJPEGXL_ENABLE_PLUGINS=ON
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" LICENSE*
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,exe.manifest,exe.local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" 
#	put_exclude_files 
}



