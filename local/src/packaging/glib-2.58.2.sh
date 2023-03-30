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
	MOD=glib
	[ "" = "${VER}" ] && VER=2.58.2
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
local pcre="pcre"
	compare_vernum_le "2.74.0" "${VER}" && pcre="pcre2"
	cat <<EOS
gettext-runtime
iconv
libffi
libxml2
${pcre}
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

run_patch() {
	# [2.68.0]
	# see: docs: Fix configuration with gtk_doc=true and installed_tests=false (!1424) ・ Merge Requests ・ GNOME / GLib ・ GitLab <https://gitlab.gnome.org/GNOME/glib/-/merge_requests/1424>
	case "${VER}" in
	2.68.* | 2.70.* | 2.72.* | 2.74.*)
		sed -i.orig docs/reference/gio/meson.build \
			-e "s/^  subdir('gdbus-object-manager-example')/#\0/" \
			-e "/^  content_files += \[/,/^  \]/ {" \
				-e "s/^/#\0/" \
			-e "}"
		;;
	esac
}

pre_configure() {
	# tests は作らない。
	sed -i.orig {gio,glib,gobject}/meson.build \
		-e "s/subdir('tests')/#\0/"

	# ネイティブの glib-compile-resources, glib-compile-schemas コマンドを作成する。
	# ドキュメントの生成とインストールも行う。
local build_host_dir="_build_host"
local pcre_flag=""
	case "${VER}" in
	2.5?.* | 2.6?.*)
		pcre_flag="-Dinternal_pcre=true"
		;;
	esac
	[[ -d "${build_host_dir}" ]] && rm -r "${build_host_dir}"
	mkdir -p "${build_host_dir}" &&
	# [2.64.0] -Dlibmount のオプションが変更された。
local libmount_disabled="disabled"
	compare_vernum_le "2.64.0" "${VER}" || libmount_disabled="false"
local fam_flag="-Dfam=false"
	compare_vernum_le "2.74.0" "${VER}" && fam_flag=""
	meson "${build_host_dir}" --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=static --optimization=2 --strip  -Dselinux=disabled -Dxattr=false -Dlibmount=${libmount_disabled} ${pcre_flag} -Dman=false -Ddtrace=false -Dsystemtap=false -Dtests=false -Dinstalled_tests=true -Dgtk_doc=false ${fam_flag} &&
	ninja -C "${build_host_dir}" gio/glib-compile-resources &&
	ninja -C "${build_host_dir}" gio/glib-compile-schemas
}

run_configure() {
local pcre_flag=""
	case "${VER}" in
	2.5?.* | 2.6?.*)
		# -Dinternal_pcre=true : pcre は内蔵のものを使用する。
		pcre_flag="-Dinternal_pcre=true"
		;;
	esac
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		${pcre_flag} \
		-Dlibelf=disabled \
		-Dtests=false -Dinstalled_tests=true \
		-Dgtk_doc=true
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
	# [2.74.4] gtkdoc-scan(gtk-doc 1.33.2-1) の実行で
	#  デッドロックが発生している様子があり、 -j 1 している。
#	WINEPATH="$PWD/gio;$PWD/gthread;$PWD/gmodule;$PWD/gobject;$PWD/glib" \
	WINEPATH="./gio;./gthread;./gmodule;./gobject;./glib" \
	${XMINGW}/cross ninja -C _build -j 1 &&
	WINEPATH="./gio;./gthread;./gmodule;./gobject;./glib" \
	${XMINGW}/cross ninja -C _build -j 1 install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*

	# *.exe ファイルは使わずホストのものを使用する。
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
	pack_archive "${__BINZIP}" bin/*.dll bin/{gdbus,glib-compile-schemas,gspawn-*}.exe share/locale "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" bin/{gdbus-codegen,glib-genmarshal,glib-mkenums,glib-compile-resources,glib-compile-schemas} include lib/*.{def,a} lib/glib-2.0 lib/pkgconfig share/aclocal share/glib-2.0/codegen &&
	pack_archive "${__TOOLSZIP}" $(ls -1 bin/*.exe | grep -vie "/gspawn-\|glib-compile-schemas\|/gdbus.exe") bin/{glib-gettextize,gtester-report} share/bash-completion share/gettext share/glib-2.0/{gdb,schemas,gettext} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&

	if [[ -d "share/gtk-doc" ]]
	then
		pack_archive "${__DOCZIP}" share/gtk-doc &&
		store_packed_archive "${__DOCZIP}"
	fi
}


