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
	# cross に渡す変数。
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=gegl
	[ "" = "${VER}" ] && VER=0.2.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}

	if `echo "${PATCH}" | grep -ie debian`
	then
		__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

		__BINZIP=${MOD}-${VER}-${PATCH}-${REV}-bin_${ARCHSUFFIX}
		__DEVZIP=${MOD}-dev-${VER}-${PATCH}-${REV}_${ARCHSUFFIX}
		__TOOLSZIP=${MOD}-${VER}-${PATCH}-${REV}-tools_${ARCHSUFFIX}
	fi
}

dependencies() {
	cat <<EOS
babl
gettext-runtime
glib
EOS
}

optional_dependencies() {
	cat <<EOS
cairo
exiv2
gdk-pixbuf
gexiv2
jasper
lcms2
libpng
libraw
librsvg
libwebp
openexr
openraw
pango
sdl
tiff
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
local name
	if `echo "${PATCH}" | grep -ie debian`
	then
		name=`find_archive "${__ARCHIVEDIR}" ${__PATCH_ARCHIVE}` &&
		patch_debian "${__ARCHIVEDIR}/${name}"
	fi
}

pre_configure() {
local gen=1
	[ -e configure ] || gen=0
	[ 1 -eq ${gen} ] && find configure.ac -newer configure && gen=0
	[ 0 -eq ${gen} ] && NOCONFIGURE=1 sh autogen.sh
	return 0
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="${OLD_CXX_ABI}" \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --disable-docs --without-ruby --without-lua --without-openexr --without-sdl --without-libraw --without-graphviz --without-libavformat --without-libv4l --without-libspiro --without-umfpack --with-webp  --disable-introspection
}

post_configure() {
	bash ${XMINGW}/replibtool.sh &&
	sed -i.orig -e "s/#\(libgegl =\)/\1/" `find . -name Makefile `
}

run_make() {
	${XMINGW}/cross make SHREXT=".dll" all install
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING* "${docdir}/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/gegl-?.?/*.{dll,json} share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/gegl-?.?/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/locale &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


