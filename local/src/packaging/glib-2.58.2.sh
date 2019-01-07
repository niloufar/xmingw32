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
	MOD=glib
	[ "" = "${VER}" ] && VER=2.58.2
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
gettext-runtime
iconv
libffi
libxml2
zlib
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

pre_configure() {
	# tests は作らない。
	sed -i.orig {gio,glib,gobject}/meson.build \
		-e "s/subdir('tests')/#\0/"

	# ネイティブの glib-compile-resources, glib-compile-schemas コマンドを作成する。
local build_host_dir="_build_host"
	[[ -d "${build_host_dir}" ]] && rm -r "${build_host_dir}"
	mkdir -p "${build_host_dir}" &&
	meson "${build_host_dir}" --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=static --optimization=2 --strip  -Dselinux=false -Dxattr=false -Dlibmount=false -Dinternal_pcre=true -Dman=false -Ddtrace=false -Dsystemtap=false -Dgtk_doc=false -Dfam=false &&
	ninja -C "${build_host_dir}" gio/glib-compile-resources &&
	ninja -C "${build_host_dir}" gio/glib-compile-schemas
}

run_configure() {
	# -Dinternal_pcre=true : pcre は内蔵のものを使用する。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared  -Dinternal_pcre=true -Dinstalled_tests=false
}

post_configure_win64() {
	# [2.58.1] 型のバイト長が異なる。
	sed -i.orig _build/glib/glibconfig.h \
		-e 's/^#define G_POLLFD_FORMAT "%#x"/#define G_POLLFD_FORMAT "%#llx"/' && 
	post_configure
}

post_configure() {
	# [2.58.1] libelf は無い。ホストのものを拾ってしまう。
	sed -i.orig _build/config.h \
		-e 's!^#define HAVE_LIBELF 1$!/* \0 */!'
}

run_make() {
	${XMINGW}/cross ninja -C _build &&
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*

	# *.exe ファイルは OS のものを使用する。
	(cd "${INSTALL_TARGET}" &&
		for f in lib/pkgconfig/*.pc
		do
			sed -i "${f}" -e 's/^\(glib_compile_schemas\|glib_compile_resources\|gdbus_codegen\)=/#\0/'
#			sed -i "${f}" -e 's/^\(gdbus_codegen\)=/#\0/'
		done
	)

	# ネイティブの glib-compile-resources, glib-compile-schemas 。
local build_host_dir="_build_host"
	cp "${build_host_dir}/gio/glib-compile-resources" "${INSTALL_TARGET}"/bin/. &&
	cp "${build_host_dir}/gio/glib-compile-schemas" "${INSTALL_TARGET}"/bin/.
}

run_pack() {
	# share/glib-2.0/gettext は glib-gettextize が参照している。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/locale share/doc &&
	pack_archive "${__DEVZIP}" bin/{gdbus-codegen,glib-genmarshal,glib-mkenums,glib-compile-resources,glib-compile-schemas} include lib/*.{def,a} lib/glib-2.0 lib/pkgconfig share/aclocal share/glib-2.0/codegen &&
#	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.exe bin/{glib-gettextize,gtester-report} share/bash-completion share/gettext share/glib-2.0/{gdb,schemas,gettext} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
#	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


