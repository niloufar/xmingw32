#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=json-c
	[ "" = "${VER}" ] && VER=0.14-20200419
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/lang"
	__ARCHIVE="${MOD}-${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
json-c

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	${XMINGW}/cross-cmake -G "Unix Makefiles" -H. -B. -DALLOW_IN_SOURCE_BUILD:bool=true -DCMAKE_BUILD_TYPE:string=RELEASE -DCMAKE_INSTALL_PREFIX:string="${INSTALL_TARGET}" \
	"-DCMAKE_C_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_CXX_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	"-DCMAKE_C_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_CXX_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_SHARED_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s -Wl,--export-all-symbols" \
	"-DCMAKE_EXE_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s"
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig lib/cmake &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}



