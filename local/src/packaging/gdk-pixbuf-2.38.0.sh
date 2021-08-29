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
	MOD=gdk-pixbuf
	[ "" = "${VER}" ] && VER=2.38.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
	__DOCZIP="${MOD}-doc-${VER}-${REV}_${ARCHSUFFIX}"
	__TOOLSZIP="${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}"
}

dependencies() {
	cat <<EOS
gettext-runtime
glib
libiconv
EOS
}

optional_dependencies() {
	cat <<EOS
jasper
libjpeg
libpng
tiff
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# [2.38.0] test subdir は除外する。
	sed meson.build -i.orig -e "s/^subdir('tests')/#\0/"
}

run_configure() {
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Ddocs=true -Dman=false \
		-Drelocatable=true -Dnative_windows_loaders=false \
		-Djasper=true -Dx11=false -Dinstalled_tests=false \
		-Dgio_sniffing=false \
		-Dintrospection=enabled
}

post_configure() {
	# [2.38.0]
	#  gdk-pixbuf/loaders.cache と
	#  thumbnailer/gdk-pixbuf-thumbnailer.thumbnailer を
	# 生成しないようにする。
	sed -i.orig _build/build.ninja \
		-e '/^build gdk-pixbuf\/loaders.cache:/,/^$/ {' -e 's/^/#/'  -e '}' \
		-e '/^build thumbnailer\/gdk-pixbuf-thumbnailer.thumbnailer:/,/^$/ {' -e 's/^/#/'  -e '}'

	# [2.38.0] gdk-pixbuf/loaders.cache がないと make でこける。
local file_loaders_cache="_build/gdk-pixbuf/loaders.cache"
	if [ ! -e "${file_loaders_cache}" ]
	then
		touch "${file_loaders_cache}"
	fi

	# [2.38.0] thumbnailer/gdk-pixbuf-thumbnailer.thumbnailer がないと make でこける。
local file_thumbnailer_thumbnailer="_build/thumbnailer/gdk-pixbuf-thumbnailer.thumbnailer"
	if [ "2.38.0" = "${VER}" && \
		! -e "${file_thumbnailer_thumbnailer}" ]
	then
		touch "${file_thumbnailer_thumbnailer}"
	fi

}

run_make() {
	WINEPATH="$PWD/_build/gdk-pixbuf" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="$PWD/_build/gdk-pixbuf" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
local thumbnailer=""
	# [2.38.1] thumbnailer は不要だったのだろうか。
	if [ "2.38.0" = "${VER}" ]
	then
		thumbnailer="bin/gdk-pixbuf-thumbnailer.exe share/thumbnailers"
	fi

	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll bin/gdk-pixbuf-query-loaders.exe $(find lib -iname \*.dll) lib/girepository-* share/locale "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include $(find lib -iname \*.a) lib/pkgconfig share/gir-* &&
	pack_archive "${__DOCZIP}" share/doc &&
	pack_archive "${__TOOLSZIP}" bin/gdk-pixbuf-{csource,pixdata}.exe ${thumbnailer} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" #&&
#	put_exclude_files bin/gi-docgen lib/python*
}


