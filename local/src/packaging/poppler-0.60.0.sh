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
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=poppler
	[ "" = "${VER}" ] && VER=0.60.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
freetype2
poppler-data
EOS
}

optional_dependencies() {
	cat <<EOS
cairo
fontconfig
lcms2
libjpeg
libpng
openjpeg2
tiff
zlib
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# [0.60.0] gobject-introspection を無効にする。
	# [0.75.0] nss3 を無効にする。
	sed -i.orig CMakeLists.txt \
		-e 's/^\s*macro_optional_find_package(GObjectIntrospection .*$/\0\nset(INTROSPECTION_FOUND OFF)/' \
		-e '/^if (NSS3_FOUND)$/,/^endif()$/ {' -e 's/^/#/' -e '}'
}

run_configure() {
	# [0.80.0] glib のインクルード パスがコンパイラに渡されてない。
local add_include=
	case "${VER}" in
	0.8[02].*)
		add_include="`${XMINGW}/cross pkg-config --cflags glib-2.0`"
	esac
	${XMINGW}/cross-cmake -G "Unix Makefiles" -H. -B. -DALLOW_IN_SOURCE_BUILD:bool=true -DCMAKE_BUILD_TYPE:string=RELEASE -DCMAKE_INSTALL_PREFIX:string="${INSTALL_TARGET}" \
	"-DCMAKE_C_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` ${add_include} -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_CXX_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` ${add_include} -pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	"-DCMAKE_C_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_CXX_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_SHARED_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s -Wl,--export-all-symbols" \
	"-DCMAKE_EXE_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s" \
	-DBUILD_SHARED_LIBS=yes \
	-DENABLE_RELOCATABLE=yes \
	-DENABLE_ZLIB=yes \
	-DENABLE_LIBOPENJPEG=openjpeg2 \
	-DENABLE_CMS=lcms2 \
	"-DPNG_PNG_INCLUDE_DIR=`${XMINGW}/cross pkg-config --variable=includedir libpng16`" \
	-DENABLE_SPLASH=yes \
	-DENABLE_LIBCURL=no \
	-DENABLE_QT4=no -DENABLE_QT5=no
}

run_make() {
	${XMINGW}/cross make install VERBOSE=1
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*

	# [0.60.0] pkgconfig file が作成されなくなった。
local cairover=`sed CMakeLists.txt -ne 's/^set(CAIRO_VERSION "\([^"]\+\)")/\1/p'`
	if [[ "" = "${cairover}" ]]
	then
		cairover="1.10.0"
		echo "INFO: CMakeLists.txt から CAIRO_VERSION を取得できませんでした。既定値（${cairover}）を使用します。"
	fi
local glibver=`sed CMakeLists.txt -ne 's/^set(GLIB_REQUIRED "\([^"]\+\)")/\1/p'`
	if [[ "" = "${glibver}" ]]
	then
		glibver="2.41"
		echo "INFO: CMakeLists.txt から GLIB_REQUIRED を取得できませんでした。既定値（${glibver}）を使用します。"
	fi
local pkgconfigdir="${INSTALL_TARGET}/lib/pkgconfig"
	mkdir -p "${pkgconfigdir}"

local pc_file
	pc_file="${pkgconfigdir}/poppler.pc" &&
	[[ ! -e "${pc_file}" ]] && cat <<EOS > "${pc_file}"
prefix=${INSTALL_TARGET}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: poppler
Description: PDF rendering library
Version: ${VER}

Libs: -L\${libdir} -lpoppler
Cflags: -I\${includedir}/poppler
EOS

	pc_file="${pkgconfigdir}/poppler-cairo.pc" &&
	[[ ! -e "${pc_file}" ]] && cat <<EOS > "${pc_file}"
prefix=${INSTALL_TARGET}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: poppler-cairo
Description: Cairo backend for Poppler PDF rendering library
Version: ${VER}
Requires: poppler = ${VER} cairo >= ${cairover}
EOS

	pc_file="${pkgconfigdir}/poppler-cpp.pc" &&
	[[ ! -e "${pc_file}" ]] && cat <<EOS > "${pc_file}"
prefix=${INSTALL_TARGET}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: poppler-cpp
Description: cpp backend for Poppler PDF rendering library
Version: ${VER}
Requires: 
Requires.private: poppler = ${VER}

Libs: -L\${libdir} -lpoppler-cpp
Cflags: -I\${includedir}/poppler/cpp
EOS

	pc_file="${pkgconfigdir}/poppler-glib.pc" &&
	[[ ! -e "${pc_file}" ]] && cat <<EOS > "${pc_file}"
prefix=${INSTALL_TARGET}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: poppler-glib
Description: GLib wrapper for poppler
Version: ${VER}
Requires: glib-2.0 >= ${glibver} gobject-2.0 >= ${glibver} gio-2.0 >= ${glibver} cairo >= ${cairover}
Requires.private: poppler = ${VER}

Libs: -L\${libdir} -lpoppler-glib
Cflags: -I\${includedir}/poppler/glib
EOS

	pc_file="${pkgconfigdir}/poppler-splash.pc" &&
	[[ ! -e "${pc_file}" ]] && cat <<EOS > "${pc_file}"
prefix=${INSTALL_TARGET}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: poppler-splash
Description: Splash backend for Poppler PDF rendering library
Version: ${VER}
Requires: poppler = ${VER}
EOS
	return 0
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


