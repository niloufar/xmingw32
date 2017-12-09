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
	MOD=json-glib
	[ "" = "${VER}" ] && VER=1.4.2
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
glib
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
GNU LESSER GENERAL PUBLIC LICENSE
Version 2.1, February 1999
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# [1.4.2] クロス コンパイルを考慮する＋もろもろ。
	sed -i.orig configure -e 's!^exec ${MESON} !\0--cross-file /dev/stdin --buildtype release --strip !'
}

run_configure() {
	[[ -d "_build" ]] && rm -r "_build"
	mkdir -p "_build" &&
	cat <<EOS | CC="$XMINGW/cross-host gcc" ${XMINGW}/cross configure --prefix="${INSTALL_TARGET}" --disable-introspection --disable-gtk-doc
[host_machine]
system = 'windows'
cpu_family = 'any'
cpu = 'any'
endian = 'little'

[binaries]
c = "gcc"
cpp = "g++"
ar = "ar"
strip = "strip"
pkgconfig = "pkg-config"
exe_wrapper = 'wine'

[properties]
c_args = "`${XMINGW}/cross --archcflags` `${XMINGW}/cross --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math -static-libgcc".split(' ')
c_link_args = "`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s".split(' ')
needs_exe_wrapper = true
EOS
}

run_make() {
	${XMINGW}/cross make all &&
	(cd _build/ && meson --internal install "${PWD}/meson-private/install.dat")
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/locale share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files bin/installed-tests libexec share/installed-tests
}



