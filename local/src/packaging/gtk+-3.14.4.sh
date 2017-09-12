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
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=gtk+
	[ "" = "${VER}" ] && VER=3.14.4
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
	__DEMOZIP=${MOD}-${VER}-${REV}-demo_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
atk
cairo
gdk-pixbuf
gettext-runtime
glib
pango
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

run_configure() {
	# ビルドに gtk-update-icon-cache, gtk-query-immodules-3.0 が必要。
	# ない場合は apt-get install libgtk-3-dev しておく。
	# --enable_gtk2_dependency を付けなければ gtk/native の native-update-icon-cache をビルドする。
	# しかし不備があり、
	#  CFLAGS, CPPFLAGS, LDFLAGS, EXEEXT が _FOR_BUILD ではなく、
	#  xcompile のものを使用する。
	# libtool を使用するのもよろしくない。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
		-D_WIN32_WINNT=_WIN32_WINNT_VISTA" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math  -static-libgcc" \
	CC_FOR_BUILD=build-cc \
	PKG_CONFIG_FOR_BUILD="$XMINGW/cross-host pkg-config" \
	CFLAGS_FOR_BUILD= \
	CPPFLAGS_FOR_BUILD= \
	LDFLAGS_FOR_BUILD= \
	${XMINGW}/cross-configure --disable-static  --prefix="${INSTALL_TARGET}" --enable-win32-backend --enable-gtk2-dependency --with-included-immodules --disable-cups --disable-schemas-compile --disable-introspection
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
	bash ${XMINGW}/replibtool.sh shared &&
	# 3.16.4
	# ビルドした gtk-update-icon-cache を実行しようとする。 demos であり、ごまかす。
	if grep demos/gtk-demo/Makefile -ie "update_icon_cache = .\+" >/dev/null 2>&1
	then
		ln --force --symbolic "`which gtk-update-icon-cache`" gtk/gtk-update-icon-cache
	fi
}

pre_make() {
	if [ -d "util" ]
	then
		# 3.14.4: util/extract-strings をネイティブでビルドできない問題への対処。
		(cd util &&
		touch extract_strings-extract-strings.o &&
		gcc extract-strings.c -o extract-strings.exe `$XMINGW/cross-host pkg-config --cflags --libs glib-2.0`
		)
	fi
	# 3.18.6: update_icon_cache.exe を実行しようとする。
	sed -i.orig -e 's/^\(update_icon_cache = \).*$/\1:/' demos/gtk-demo/Makefile
	sed -i.orig -e 's/^\(update_icon_cache = \).*$/\1:/' demos/widget-factory/Makefile
}

run_make() {
	${XMINGW}/cross make gtk_def= gdk_def= all install
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING "${docdir}/."

#	# 3.14.4: ごまかしビルドの extract-strings をコピーしておく。
#	cp util/extract-strings.exe "${INSTALL_TARGET}/bin/_extract-strings"
}

run_pack() {
local TESTZIP="${MOD}-${VER}-${REV}-test_${ARCHSUFFIX}"
	pack_archive "${TESTZIP}" tests/*.{exe,png,xpm,ui,css} tests/.libs/*.exe &&
	store_packed_archive "${TESTZIP}"

	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll bin/gtk-query-immodules-3.0.exe etc `find lib -name \*.dll` share/{locale,themes} share/doc &&
	pack_archive "${__DEVZIP}" include `find lib -name \*.def -or -name \*.a` lib/pkgconfig share/{aclocal,gettext/its,glib-2.0,gtk-3.0} &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/gtk-{builder-tool,encode-symbolic-svg,launch,query-settings,update-icon-cache}.exe share/man/man1/b* share/man/man1/gtk-* &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" && 

	pack_archive "${__DEMOZIP}" bin/gtk3-{demo,demo-application,icon-browser,widget-factory}.exe share/glib-2.0/schemas share/icons share/man/man1/gtk3-* &&
	store_packed_archive "${__DEMOZIP}" &&

	put_exclude_files share/applications/*.desktop
}



