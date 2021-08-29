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
	XLIBRARY_SET="gtk"
	# package に返す変数。
	MOD=pango
	[ "" = "${VER}" ] && VER=1.44.5
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
cairo
glib
fontconfig
freetype2
fribidi
harfbuzz
libthai
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
GNU LIBRARY GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# xft を参照しないよう強制する。
	sed -i.orig meson.build \
		-e '/^xft_req_version = / {' -e "s/'.\+'/'> 10000.0.0'/" -e '}'

	if [[ -e "docs/pango.types.in" ]]
	then
		sed -i.orig docs/pango.types.in -e '/_xft_/ d'
	fi

	# [1.48.3] subprojects/harfbuzz の test を無効にする。
#	if [[ -e subprojects/harfbuzz/meson.build ]]
#	then
#		sed -i.orig subprojects/harfbuzz/meson.build \
#			-e "s/^  subdir('test')/#\0/"
#	fi
}

run_configure() {
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Dinstall-tests=false \
		-Dgtk_doc=true -Dintrospection=enabled
}

run_make() {
	WINEPATH="$PWD/_build/pango" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="$PWD/_build/pango" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING* THANKS*
}

run_pack() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/girepository-* "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/gir-* &&
	pack_archive "${__DOCZIP}" share/doc share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.exe &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}")
}


