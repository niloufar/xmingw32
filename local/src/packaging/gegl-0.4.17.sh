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
	XLIBRARY_SET="gtk gimp_build"

	# package に返す変数。
	MOD=gegl
	[ "" = "${VER}" ] && VER=git-84ef1f525
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}

	if `echo "${PATCH}" | grep -ie debian`
	then
		__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

		__BINZIP=${MOD}-${VER}-${PATCH}-${REV}-bin_${ARCHSUFFIX}
		__DEVZIP=${MOD}-dev-${VER}-${PATCH}-${REV}_${ARCHSUFFIX}
		__DOCZIP=${MOD}-${VER}-${PATCH}-${REV}-bin_${ARCHSUFFIX}
		__TOOLSZIP=${MOD}-${VER}-${PATCH}-${REV}-tools_${ARCHSUFFIX}
	fi
}

dependencies() {
	cat <<EOS
babl
gettext-runtime
glib
json-glib
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

pre_configure() {
	# [0.4.17] host_machine.cpu は any のため正しく判定できない。
	sed -i.orig meson.build \
		-e "s/host_cpu = host_machine.cpu()/host_cpu = build_machine.cpu()/"
}

run_configure() {
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Druby=disabled \
		-Dlua=disabled \
		-Dopenexr=disabled \
		-Dsdl1=disabled -Dsdl2=disabled \
		-Dlibraw=disabled \
		-Dgraphviz=disabled \
		-Dlensfun=disabled \
		-Dlibav=disabled \
		-Dmrg=disabled \
		-Dumfpack=disabled \
		-Dlibv4l=disabled -Dlibv4l2=disabled \
		-Dlibspiro=disabled \
		-Dpygobject=disabled \
		-Ddocs=true -Dintrospection=true -Dvapigen=enabled
}

post_configure() {
	# [0.4.26] tools/introspect.exe をうまく実行できない。
	#  細工した wine から実行する。
	sed -i.orig _build/build.ninja \
		-e '/ COMMAND .*introspect.exe$/ s!/operations /usr/!/operations wine /usr/!'
}

run_make() {
	WINEPATH="$PWD/_build/gegl" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="$PWD/_build/gegl" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING* AUTHORS*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/gegl-?.?/*.{dll,json} lib/girepository-* "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/gegl-?.?/*.a lib/pkgconfig share/gir-* share/vala/vapi/ &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/locale &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


